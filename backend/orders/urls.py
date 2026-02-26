from django.urls import path
from .views import (
    TableListView,
    TableDetailView,
    TableByNumberView,
    GenerateQRView,
    CreateOrderView,
    OrderDetailView,
    TableOrdersView,
    UpdateOrderStatusView,
    KitchenOrdersView,
    AdminDashboardView,
)

urlpatterns = [
    # Tables
    path('tables/', TableListView.as_view(), name='table-list'),
    path('tables/<int:pk>/', TableDetailView.as_view(), name='table-detail'),
    path('tables/number/<int:number>/', TableByNumberView.as_view(), name='table-by-number'),
    path('tables/<int:pk>/generate-qr/', GenerateQRView.as_view(), name='generate-qr'),

    # Orders
    path('create/', CreateOrderView.as_view(), name='order-create'),
    path('<int:pk>/', OrderDetailView.as_view(), name='order-detail'),
    path('<int:pk>/status/', UpdateOrderStatusView.as_view(), name='order-status-update'),
    path('table/<int:table_id>/', TableOrdersView.as_view(), name='table-orders'),

    # Kitchen
    path('kitchen/', KitchenOrdersView.as_view(), name='kitchen-orders'),

    # Admin Dashboard
    path('dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
]
