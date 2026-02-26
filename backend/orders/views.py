from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta

from .models import Table, Order, OrderItem
from .serializers import (
    TableSerializer,
    OrderSerializer,
    OrderCreateSerializer,
    OrderStatusUpdateSerializer,
)


class TableListView(generics.ListCreateAPIView):
    """List all tables or create a new table."""
    queryset = Table.objects.all()
    serializer_class = TableSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = Table.objects.all()
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        return queryset


class TableDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a table."""
    queryset = Table.objects.all()
    serializer_class = TableSerializer
    permission_classes = [AllowAny]


class TableByNumberView(APIView):
    """Get table info by table number (used by QR scan)."""
    permission_classes = [AllowAny]

    def get(self, request, number):
        try:
            table = Table.objects.get(number=number, is_active=True)
        except Table.DoesNotExist:
            return Response(
                {'error': 'Table not found or inactive.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        serializer = TableSerializer(table)
        return Response(serializer.data)


class GenerateQRView(APIView):
    """Generate QR code for a specific table."""
    permission_classes = [AllowAny]

    def post(self, request, pk):
        try:
            table = Table.objects.get(pk=pk)
        except Table.DoesNotExist:
            return Response(
                {'error': 'Table not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        base_url = request.build_absolute_uri('/').rstrip('/')
        table.generate_qr_code(base_url)
        serializer = TableSerializer(table)
        return Response(serializer.data)


class CreateOrderView(APIView):
    """Create a new order (customer)."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = serializer.save()

        # Send WebSocket notification
        self._notify_kitchen(order)

        return Response(
            OrderSerializer(order).data,
            status=status.HTTP_201_CREATED,
        )

    def _notify_kitchen(self, order):
        """Send new order notification to kitchen via WebSocket."""
        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync

            channel_layer = get_channel_layer()
            order_data = OrderSerializer(order).data

            async_to_sync(channel_layer.group_send)(
                'kitchen',
                {
                    'type': 'new_order',
                    'order': order_data,
                }
            )
            async_to_sync(channel_layer.group_send)(
                f'table_{order.table.number}',
                {
                    'type': 'order_update',
                    'order': order_data,
                }
            )
        except Exception as e:
            print(f"WebSocket notification error: {e}")


class OrderDetailView(generics.RetrieveAPIView):
    """Get order details."""
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [AllowAny]


class TableOrdersView(APIView):
    """Get all orders for a specific table."""
    permission_classes = [AllowAny]

    def get(self, request, table_id):
        orders = Order.objects.filter(table_id=table_id)

        active_only = request.query_params.get('active')
        if active_only and active_only.lower() == 'true':
            orders = orders.exclude(status__in=['served', 'cancelled'])

        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)


class UpdateOrderStatusView(APIView):
    """Update order status (kitchen/admin)."""
    permission_classes = [AllowAny]

    def patch(self, request, pk):
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return Response(
                {'error': 'Order not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = OrderStatusUpdateSerializer(
            data=request.data,
            context={'order': order},
        )
        serializer.is_valid(raise_exception=True)

        old_status = order.status
        order.status = serializer.validated_data['status']
        order.save(update_fields=['status', 'updated_at'])

        # Notify via WebSocket
        self._notify_status_change(order, old_status)

        return Response(OrderSerializer(order).data)

    def _notify_status_change(self, order, old_status):
        """Send status update via WebSocket."""
        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync

            channel_layer = get_channel_layer()
            order_data = OrderSerializer(order).data

            # Notify kitchen
            async_to_sync(channel_layer.group_send)(
                'kitchen',
                {
                    'type': 'order_status_update',
                    'order': order_data,
                    'old_status': old_status,
                }
            )
            # Notify customer table
            async_to_sync(channel_layer.group_send)(
                f'table_{order.table.number}',
                {
                    'type': 'order_status_update',
                    'order': order_data,
                    'old_status': old_status,
                }
            )
        except Exception as e:
            print(f"WebSocket notification error: {e}")


class KitchenOrdersView(APIView):
    """Get orders for kitchen display."""
    permission_classes = [AllowAny]

    def get(self, request):
        status_filter = request.query_params.get('status')

        orders = Order.objects.exclude(
            status__in=['served', 'cancelled']
        ).select_related('table').prefetch_related('items__menu_item')

        if status_filter:
            orders = orders.filter(status=status_filter)

        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)


class AdminDashboardView(APIView):
    """Get dashboard analytics for admin."""
    permission_classes = [AllowAny]

    def get(self, request):
        today = timezone.now().date()
        today_start = timezone.make_aware(
            timezone.datetime.combine(today, timezone.datetime.min.time())
        )

        # Today's stats
        today_orders = Order.objects.filter(created_at__gte=today_start)
        total_orders_today = today_orders.count()
        revenue_today = today_orders.filter(
            status__in=['served', 'ready', 'cooking', 'confirmed']
        ).aggregate(total=Sum('total'))['total'] or 0

        # Active orders
        active_orders = Order.objects.exclude(
            status__in=['served', 'cancelled']
        ).count()

        # Active tables (tables with active orders)
        active_tables = Table.objects.filter(
            orders__status__in=['pending', 'confirmed', 'cooking', 'ready']
        ).distinct().count()

        # Pending orders
        pending_orders = Order.objects.filter(status='pending').count()

        # Weekly revenue
        week_ago = today_start - timedelta(days=7)
        weekly_revenue = Order.objects.filter(
            created_at__gte=week_ago,
            status__in=['served', 'ready', 'cooking', 'confirmed'],
        ).aggregate(total=Sum('total'))['total'] or 0

        # Popular items (last 7 days)
        popular_items = OrderItem.objects.filter(
            order__created_at__gte=week_ago,
        ).values(
            'menu_item__name',
        ).annotate(
            total_ordered=Sum('quantity'),
        ).order_by('-total_ordered')[:5]

        return Response({
            'today': {
                'orders': total_orders_today,
                'revenue': float(revenue_today),
                'active_orders': active_orders,
                'active_tables': active_tables,
                'pending_orders': pending_orders,
            },
            'weekly': {
                'revenue': float(weekly_revenue),
            },
            'popular_items': list(popular_items),
            'total_tables': Table.objects.filter(is_active=True).count(),
        })
