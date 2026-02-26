from rest_framework import serializers
from .models import Table, Order, OrderItem
from menu.serializers import MenuItemSerializer


class TableSerializer(serializers.ModelSerializer):
    active_orders_count = serializers.SerializerMethodField()

    class Meta:
        model = Table
        fields = [
            'id', 'number', 'name', 'capacity',
            'is_active', 'qr_code', 'active_orders_count', 'created_at',
        ]
        read_only_fields = ['qr_code', 'created_at']

    def get_active_orders_count(self, obj):
        return obj.orders.exclude(status__in=['served', 'cancelled']).count()


class OrderItemSerializer(serializers.ModelSerializer):
    menu_item_name = serializers.CharField(source='menu_item.name', read_only=True)
    menu_item_image = serializers.ImageField(source='menu_item.image', read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = OrderItem
        fields = [
            'id', 'menu_item', 'menu_item_name', 'menu_item_image',
            'quantity', 'unit_price', 'notes', 'total_price',
        ]
        read_only_fields = ['unit_price']


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    table_number = serializers.IntegerField(source='table.number', read_only=True)
    table_name = serializers.CharField(source='table.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    items_count = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'table', 'table_number', 'table_name',
            'status', 'status_display', 'payment_status',
            'subtotal', 'service_charge', 'total',
            'notes', 'customer_name', 'estimated_time',
            'items', 'items_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'order_number', 'subtotal', 'service_charge', 'total',
            'created_at', 'updated_at',
        ]

    def get_items_count(self, obj):
        return obj.items.count()


class OrderItemCreateSerializer(serializers.Serializer):
    menu_item_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, default=1)
    notes = serializers.CharField(required=False, allow_blank=True, default='')


class OrderCreateSerializer(serializers.Serializer):
    table_id = serializers.IntegerField()
    customer_name = serializers.CharField(required=False, allow_blank=True, default='')
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    items = OrderItemCreateSerializer(many=True)

    def validate_table_id(self, value):
        try:
            Table.objects.get(id=value, is_active=True)
        except Table.DoesNotExist:
            raise serializers.ValidationError("Table not found or inactive.")
        return value

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("At least one item is required.")
        return value

    def create(self, validated_data):
        from menu.models import MenuItem

        table = Table.objects.get(id=validated_data['table_id'])
        items_data = validated_data['items']

        order = Order.objects.create(
            table=table,
            customer_name=validated_data.get('customer_name', ''),
            notes=validated_data.get('notes', ''),
        )

        for item_data in items_data:
            menu_item = MenuItem.objects.get(id=item_data['menu_item_id'])
            OrderItem.objects.create(
                order=order,
                menu_item=menu_item,
                quantity=item_data['quantity'],
                unit_price=menu_item.price,
                notes=item_data.get('notes', ''),
            )

        order.calculate_totals()

        # Calculate estimated time based on max preparation time
        max_prep_time = max(
            MenuItem.objects.get(id=item['menu_item_id']).preparation_time
            for item in items_data
        )
        order.estimated_time = max_prep_time + 5  # Extra 5 min buffer
        order.save(update_fields=['estimated_time'])

        return order


class OrderStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Order.STATUS_CHOICES)

    def validate_status(self, value):
        order = self.context.get('order')
        if order:
            valid_transitions = {
                'pending': ['confirmed', 'cancelled'],
                'confirmed': ['cooking', 'cancelled'],
                'cooking': ['ready', 'cancelled'],
                'ready': ['served'],
                'served': [],
                'cancelled': [],
            }
            allowed = valid_transitions.get(order.status, [])
            if value not in allowed:
                raise serializers.ValidationError(
                    f"Cannot transition from '{order.status}' to '{value}'. "
                    f"Allowed: {allowed}"
                )
        return value
