import uuid
import qrcode
from io import BytesIO
from django.db import models
from django.core.files.base import ContentFile
from menu.models import MenuItem


class Table(models.Model):
    number = models.PositiveIntegerField(unique=True)
    name = models.CharField(max_length=50, blank=True)
    capacity = models.PositiveIntegerField(default=4)
    is_active = models.BooleanField(default=True)
    qr_code = models.ImageField(upload_to='qr_codes/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['number']

    def __str__(self):
        return self.name or f"Table {self.number}"

    def generate_qr_code(self, base_url='http://localhost:8000'):
        """Generate QR code for this table."""
        qr_data = f"{base_url}/table/{self.number}"
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        filename = f"table_{self.number}_qr.png"
        self.qr_code.save(filename, ContentFile(buffer.getvalue()), save=True)

    def save(self, *args, **kwargs):
        if not self.name:
            self.name = f"Table {self.number}"
        super().save(*args, **kwargs)


class Order(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('cooking', 'Cooking'),
        ('ready', 'Ready'),
        ('served', 'Served'),
        ('cancelled', 'Cancelled'),
    ]

    PAYMENT_STATUS_CHOICES = [
        ('unpaid', 'Unpaid'),
        ('paid', 'Paid'),
    ]

    order_number = models.CharField(max_length=20, unique=True, editable=False)
    table = models.ForeignKey(Table, on_delete=models.CASCADE, related_name='orders')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='unpaid')
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    service_charge = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    notes = models.TextField(blank=True)
    customer_name = models.CharField(max_length=100, blank=True)
    estimated_time = models.PositiveIntegerField(default=20, help_text='Estimated time in minutes')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Order #{self.order_number} - {self.table}"

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = self._generate_order_number()
        super().save(*args, **kwargs)

    def _generate_order_number(self):
        """Generate a unique order number."""
        from django.utils import timezone
        now = timezone.now()
        prefix = now.strftime('%y%m%d')
        last_order = Order.objects.filter(
            order_number__startswith=prefix
        ).order_by('-order_number').first()

        if last_order:
            last_num = int(last_order.order_number[-4:])
            new_num = last_num + 1
        else:
            new_num = 1
        return f"{prefix}{new_num:04d}"

    def calculate_totals(self):
        """Calculate subtotal, service charge, and total from order items."""
        self.subtotal = sum(
            item.quantity * item.unit_price for item in self.items.all()
        )
        self.service_charge = self.subtotal * 0.10  # 10% service charge
        self.total = self.subtotal + self.service_charge
        self.save(update_fields=['subtotal', 'service_charge', 'total'])


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    menu_item = models.ForeignKey(MenuItem, on_delete=models.CASCADE, related_name='order_items')
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.quantity}x {self.menu_item.name}"

    @property
    def total_price(self):
        return self.quantity * self.unit_price

    def save(self, *args, **kwargs):
        if not self.unit_price:
            self.unit_price = self.menu_item.price
        super().save(*args, **kwargs)
