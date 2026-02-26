from rest_framework import serializers
from .models import Category, MenuItem


class CategorySerializer(serializers.ModelSerializer):
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'image', 'description', 'sort_order', 'is_active', 'item_count']

    def get_item_count(self, obj):
        return obj.items.filter(available=True).count()


class MenuItemSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = MenuItem
        fields = [
            'id', 'name', 'description', 'price', 'image',
            'category', 'category_name', 'available',
            'is_popular', 'preparation_time',
        ]


class MenuItemCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenuItem
        fields = [
            'name', 'description', 'price', 'image',
            'category', 'available', 'is_popular', 'preparation_time',
        ]
