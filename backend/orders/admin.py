from django.contrib import admin
from .models import Table, Order, OrderItem


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('unit_price', 'total_price')
    raw_id_fields = ('menu_item',)


@admin.register(Table)
class TableAdmin(admin.ModelAdmin):
    list_display = ('number', 'name', 'capacity', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name',)
    list_editable = ('is_active',)
    ordering = ('number',)
    actions = ['generate_qr_codes']

    @admin.action(description='Generate QR codes for selected tables')
    def generate_qr_codes(self, request, queryset):
        base_url = request.build_absolute_uri('/').rstrip('/')
        for table in queryset:
            table.generate_qr_code(base_url)
        self.message_user(request, f"QR codes generated for {queryset.count()} tables.")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_number', 'table', 'status', 'payment_status',
        'total', 'customer_name', 'created_at',
    )
    list_filter = ('status', 'payment_status', 'created_at')
    search_fields = ('order_number', 'customer_name')
    list_editable = ('status', 'payment_status')
    readonly_fields = ('order_number', 'subtotal', 'service_charge', 'total', 'created_at', 'updated_at')
    inlines = [OrderItemInline]
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('order', 'menu_item', 'quantity', 'unit_price', 'total_price')
    list_filter = ('order__status',)
    raw_id_fields = ('order', 'menu_item')
