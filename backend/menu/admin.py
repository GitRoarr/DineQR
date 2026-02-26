from django.contrib import admin
from .models import Category, MenuItem


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'sort_order', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name',)
    list_editable = ('sort_order', 'is_active')
    ordering = ('sort_order',)


@admin.register(MenuItem)
class MenuItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'price', 'is_available', 'is_popular', 'preparation_time')
    list_filter = ('category', 'is_available', 'is_popular')
    search_fields = ('name', 'description')
    list_editable = ('price', 'is_available', 'is_popular')
    ordering = ('category', 'name')
