from django.urls import path
from .views import (
    CategoryListView,
    CategoryDetailView,
    MenuItemListView,
    MenuItemDetailView,
)

urlpatterns = [
    path('categories/', CategoryListView.as_view(), name='category-list'),
    path('categories/<int:pk>/', CategoryDetailView.as_view(), name='category-detail'),
    path('items/', MenuItemListView.as_view(), name='menu-item-list'),
    path('items/<int:pk>/', MenuItemDetailView.as_view(), name='menu-item-detail'),
]
