#!/usr/bin/env python
"""
DineQR - Seed Database with Sample Data

Creates sample categories, menu items, and tables for development.
Run with: python manage.py shell < seed_data.py
Or: python manage.py runscript seed_data (if django-extensions installed)
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
django.setup()

from django.contrib.auth import get_user_model
from menu.models import Category, MenuItem
from orders.models import Table

User = get_user_model()


def seed():
    print("\n🍽️  DineQR - Seeding Database...\n")

    # --- Create Superuser ---
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser(
            username='admin',
            email='admin@dineqr.com',
            password='admin123',
            role='admin',
        )
        print("  ✅ Admin user created (admin / admin123)")
    else:
        print("  ⏭️  Admin user already exists")

    # --- Create Kitchen Staff ---
    if not User.objects.filter(username='kitchen').exists():
        User.objects.create_user(
            username='kitchen',
            email='kitchen@dineqr.com',
            password='kitchen123',
            role='kitchen',
        )
        print("  ✅ Kitchen user created (kitchen / kitchen123)")
    else:
        print("  ⏭️  Kitchen user already exists")

    # --- Create Waiter ---
    if not User.objects.filter(username='waiter').exists():
        User.objects.create_user(
            username='waiter',
            email='waiter@dineqr.com',
            password='waiter123',
            role='waiter',
        )
        print("  ✅ Waiter user created (waiter / waiter123)")
    else:
        print("  ⏭️  Waiter user already exists")

    # --- Create Categories ---
    categories_data = [
        {'name': 'Appetizers', 'icon': '🥗', 'description': 'Start your meal right', 'sort_order': 1},
        {'name': 'Main Course', 'icon': '🍖', 'description': 'Hearty main dishes', 'sort_order': 2},
        {'name': 'Pizza', 'icon': '🍕', 'description': 'Wood-fired pizzas', 'sort_order': 3},
        {'name': 'Pasta', 'icon': '🍝', 'description': 'Fresh Italian pasta', 'sort_order': 4},
        {'name': 'Desserts', 'icon': '🍰', 'description': 'Sweet endings', 'sort_order': 5},
        {'name': 'Beverages', 'icon': '🍹', 'description': 'Refreshing drinks', 'sort_order': 6},
        {'name': 'Ethiopian', 'icon': '🫓', 'description': 'Traditional Ethiopian dishes', 'sort_order': 7},
    ]

    categories = {}
    for cat_data in categories_data:
        cat, created = Category.objects.get_or_create(
            name=cat_data['name'],
            defaults=cat_data,
        )
        categories[cat.name] = cat
        status = "✅ Created" if created else "⏭️  Exists"
        print(f"  {status}: Category - {cat.name}")

    # --- Create Menu Items ---
    menu_items_data = [
        # Appetizers
        {'name': 'Caesar Salad', 'description': 'Crisp romaine lettuce, parmesan, croutons with classic Caesar dressing', 'price': 180, 'category': 'Appetizers', 'preparation_time': 10, 'is_popular': True},
        {'name': 'Bruschetta', 'description': 'Toasted bread topped with fresh tomatoes, basil, and garlic', 'price': 150, 'category': 'Appetizers', 'preparation_time': 8},
        {'name': 'Spring Rolls', 'description': 'Crispy vegetable spring rolls with sweet chili dipping sauce', 'price': 120, 'category': 'Appetizers', 'preparation_time': 12},
        {'name': 'Soup of the Day', 'description': 'Chef\'s daily special soup served with bread', 'price': 100, 'category': 'Appetizers', 'preparation_time': 5},

        # Main Course
        {'name': 'Grilled Ribeye Steak', 'description': '300g premium ribeye steak with herb butter, roasted potatoes, and seasonal vegetables', 'price': 650, 'category': 'Main Course', 'preparation_time': 25, 'is_popular': True},
        {'name': 'Grilled Salmon', 'description': 'Atlantic salmon fillet with lemon dill sauce, asparagus, and rice', 'price': 550, 'category': 'Main Course', 'preparation_time': 20},
        {'name': 'Chicken Parmesan', 'description': 'Breaded chicken breast with marinara sauce and melted mozzarella', 'price': 380, 'category': 'Main Course', 'preparation_time': 20},
        {'name': 'Lamb Chops', 'description': 'Herb-crusted lamb chops with mint jelly and roasted vegetables', 'price': 580, 'category': 'Main Course', 'preparation_time': 25},

        # Pizza
        {'name': 'Margherita Pizza', 'description': 'Classic tomato sauce, fresh mozzarella, and basil on thin crust', 'price': 280, 'category': 'Pizza', 'preparation_time': 15, 'is_popular': True},
        {'name': 'Pepperoni Supreme', 'description': 'Double pepperoni, mozzarella, and oregano', 'price': 350, 'category': 'Pizza', 'preparation_time': 15},
        {'name': 'BBQ Chicken Pizza', 'description': 'BBQ sauce, grilled chicken, red onion, and cilantro', 'price': 380, 'category': 'Pizza', 'preparation_time': 18},

        # Pasta
        {'name': 'Spaghetti Carbonara', 'description': 'Classic Roman pasta with pancetta, egg, pecorino, and black pepper', 'price': 280, 'category': 'Pasta', 'preparation_time': 15},
        {'name': 'Penne Arrabbiata', 'description': 'Spicy tomato sauce with garlic and chili flakes', 'price': 240, 'category': 'Pasta', 'preparation_time': 12},
        {'name': 'Fettuccine Alfredo', 'description': 'Rich and creamy parmesan sauce with fettuccine', 'price': 300, 'category': 'Pasta', 'preparation_time': 15, 'is_popular': True},

        # Desserts
        {'name': 'Tiramisu', 'description': 'Classic Italian coffee-flavored layered dessert', 'price': 200, 'category': 'Desserts', 'preparation_time': 5, 'is_popular': True},
        {'name': 'Chocolate Lava Cake', 'description': 'Warm chocolate cake with molten center, served with vanilla ice cream', 'price': 220, 'category': 'Desserts', 'preparation_time': 15},
        {'name': 'Crème Brûlée', 'description': 'Classic French vanilla custard with caramelized sugar top', 'price': 180, 'category': 'Desserts', 'preparation_time': 5},

        # Beverages
        {'name': 'Fresh Mango Juice', 'description': 'Freshly squeezed mango juice', 'price': 80, 'category': 'Beverages', 'preparation_time': 5},
        {'name': 'Iced Coffee', 'description': 'Ethiopian cold brew coffee over ice with milk', 'price': 90, 'category': 'Beverages', 'preparation_time': 3},
        {'name': 'Sparkling Water', 'description': 'Imported sparkling mineral water 500ml', 'price': 60, 'category': 'Beverages', 'preparation_time': 1},
        {'name': 'Tropical Smoothie', 'description': 'Blend of mango, pineapple, banana, and passion fruit', 'price': 120, 'category': 'Beverages', 'preparation_time': 5, 'is_popular': True},

        # Ethiopian
        {'name': 'Doro Wot', 'description': 'Traditional spicy chicken stew with boiled egg, served with injera', 'price': 350, 'category': 'Ethiopian', 'preparation_time': 30, 'is_popular': True},
        {'name': 'Kitfo', 'description': 'Ethiopian steak tartare with mitmita spice and clarified butter', 'price': 400, 'category': 'Ethiopian', 'preparation_time': 15},
        {'name': 'Beyaynetu', 'description': 'Vegetarian platter with various wots and salads on injera', 'price': 280, 'category': 'Ethiopian', 'preparation_time': 20},
        {'name': 'Tibs', 'description': 'Sautéed beef cubes with peppers, onions, and rosemary', 'price': 320, 'category': 'Ethiopian', 'preparation_time': 15},
    ]

    for item_data in menu_items_data:
        cat_name = item_data.pop('category')
        item, created = MenuItem.objects.get_or_create(
            name=item_data['name'],
            defaults={**item_data, 'category': categories[cat_name]},
        )
        status = "✅ Created" if created else "⏭️  Exists"
        print(f"  {status}: {item.name} (ETB {item.price})")

    # --- Create Tables ---
    for i in range(1, 16):
        table, created = Table.objects.get_or_create(
            number=i,
            defaults={
                'name': f'Table {i}',
                'capacity': 4 if i <= 10 else 6 if i <= 13 else 8,
            },
        )
        status = "✅ Created" if created else "⏭️  Exists"
        print(f"  {status}: {table.name} (capacity: {table.capacity})")

    print(f"\n{'='*50}")
    print(f"  🎉 Seeding complete!")
    print(f"  📊 Categories: {Category.objects.count()}")
    print(f"  🍽️  Menu Items: {MenuItem.objects.count()}")
    print(f"  🪑 Tables: {Table.objects.count()}")
    print(f"  👥 Users: {User.objects.count()}")
    print(f"{'='*50}\n")


if __name__ == '__main__':
    seed()
else:
    seed()
