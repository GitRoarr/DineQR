from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated

from .models import Category, MenuItem
from .serializers import CategorySerializer, MenuItemSerializer, MenuItemCreateSerializer


class CategoryListView(APIView):
    """List all categories / Create new category"""
    permission_classes = [AllowAny]

    def get(self, request):
        categories = Category.objects.filter(is_active=True)
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = CategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CategoryDetailView(APIView):
    """Retrieve / Update / Delete a category"""

    def get_object(self, pk):
        try:
            return Category.objects.get(pk=pk)
        except Category.DoesNotExist:
            return None

    def get(self, request, pk):
        category = self.get_object(pk)
        if not category:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(CategorySerializer(category).data)

    def put(self, request, pk):
        category = self.get_object(pk)
        if not category:
            return Response(status=status.HTTP_404_NOT_FOUND)
        serializer = CategorySerializer(category, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        category = self.get_object(pk)
        if not category:
            return Response(status=status.HTTP_404_NOT_FOUND)
        category.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MenuItemListView(APIView):
    """List all menu items / Create new item"""
    permission_classes = [AllowAny]

    def get(self, request):
        items = MenuItem.objects.filter(available=True).select_related('category')

        # Filter by category
        category_id = request.query_params.get('category')
        if category_id:
            items = items.filter(category_id=category_id)

        # Search
        search = request.query_params.get('search')
        if search:
            items = items.filter(name__icontains=search)

        # Popular filter
        popular = request.query_params.get('popular')
        if popular == 'true':
            items = items.filter(is_popular=True)

        serializer = MenuItemSerializer(items, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = MenuItemCreateSerializer(data=request.data)
        if serializer.is_valid():
            item = serializer.save()
            return Response(
                MenuItemSerializer(item).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MenuItemDetailView(APIView):
    """Retrieve / Update / Delete a menu item"""

    def get_object(self, pk):
        try:
            return MenuItem.objects.select_related('category').get(pk=pk)
        except MenuItem.DoesNotExist:
            return None

    def get(self, request, pk):
        item = self.get_object(pk)
        if not item:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(MenuItemSerializer(item).data)

    def put(self, request, pk):
        item = self.get_object(pk)
        if not item:
            return Response(status=status.HTTP_404_NOT_FOUND)
        serializer = MenuItemCreateSerializer(item, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            return Response(MenuItemSerializer(updated).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        item = self.get_object(pk)
        if not item:
            return Response(status=status.HTTP_404_NOT_FOUND)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
