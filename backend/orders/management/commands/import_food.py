"""
Import real food data from TheMealDB free API into DineQR.
Usage:  python manage.py import_food
"""
import requests
from django.core.management.base import BaseCommand
from django.db import transaction
from menu.models import Category, MenuItem
from decimal import Decimal
import random


CATEGORIES_MAP = {
    'Beef': {'name': 'Beef', 'icon': 'restaurant'},
    'Chicken': {'name': 'Chicken', 'icon': 'restaurant'},
    'Seafood': {'name': 'Seafood', 'icon': 'restaurant'},
    'Pasta': {'name': 'Pasta', 'icon': 'restaurant'},
    'Breakfast': {'name': 'Breakfast', 'icon': 'free_breakfast'},
    'Dessert': {'name': 'Desserts', 'icon': 'icecream'},
    'Side': {'name': 'Sides', 'icon': 'restaurant'},
    'Vegetarian': {'name': 'Vegetarian', 'icon': 'eco'},
    'Lamb': {'name': 'Lamb', 'icon': 'restaurant'},
    'Miscellaneous': {'name': 'Specials', 'icon': 'stars'},
    'Pork': {'name': 'Pork', 'icon': 'restaurant'},
    'Starter': {'name': 'Starters', 'icon': 'restaurant'},
    'Vegan': {'name': 'Vegan', 'icon': 'eco'},
    'Goat': {'name': 'Goat', 'icon': 'restaurant'},
}

# Price ranges per category
PRICE_RANGES = {
    'Beef': (12, 25),
    'Chicken': (10, 20),
    'Seafood': (14, 28),
    'Pasta': (9, 18),
    'Breakfast': (5, 12),
    'Dessert': (4, 10),
    'Side': (3, 8),
    'Vegetarian': (8, 16),
    'Lamb': (14, 26),
    'Miscellaneous': (8, 18),
    'Pork': (11, 22),
    'Starter': (5, 12),
    'Vegan': (7, 15),
    'Goat': (13, 24),
}

# Prep time ranges (minutes)
PREP_RANGES = {
    'Beef': (20, 35),
    'Chicken': (15, 30),
    'Seafood': (15, 25),
    'Pasta': (12, 20),
    'Breakfast': (8, 15),
    'Dessert': (5, 15),
    'Side': (5, 10),
    'Vegetarian': (10, 20),
    'Lamb': (20, 40),
    'Miscellaneous': (10, 25),
    'Pork': (18, 30),
    'Starter': (8, 15),
    'Vegan': (10, 20),
    'Goat': (20, 35),
}


class Command(BaseCommand):
    help = 'Import real food data from TheMealDB API into DineQR menu'

    def add_arguments(self, parser):
        parser.add_argument(
            '--limit',
            type=int,
            default=5,
            help='Max items per category to import (default: 5)',
        )
        parser.add_argument(
            '--categories',
            nargs='*',
            default=None,
            help='Specific categories to import (e.g. Beef Chicken Dessert)',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        limit = options['limit']
        filter_cats = options.get('categories')

        self.stdout.write(self.style.MIGRATE_HEADING(
            '🍽  Importing food from TheMealDB API...\n'))

        # 1. Fetch categories from API
        try:
            resp = requests.get(
                'https://www.themealdb.com/api/json/v1/1/categories.php',
                timeout=10,
            )
            resp.raise_for_status()
            api_categories = resp.json().get('categories', [])
        except Exception as e:
            self.stderr.write(self.style.ERROR(f'Failed to fetch categories: {e}'))
            return

        total_items = 0

        for api_cat in api_categories:
            cat_name = api_cat['strCategory']

            # Skip if user specified categories and this isn't one
            if filter_cats and cat_name not in filter_cats:
                continue

            # Skip if not in our mapping
            if cat_name not in CATEGORIES_MAP:
                continue

            mapped = CATEGORIES_MAP[cat_name]

            # Create or get category
            category, created = Category.objects.get_or_create(
                name=mapped['name'],
                defaults={'description': api_cat.get('strCategoryDescription', '')[:200]},
            )
            status = 'Created' if created else 'Exists'
            self.stdout.write(
                self.style.SUCCESS(f'  📁 {status} category: {category.name}'))

            # 2. Fetch meals for this category
            try:
                meals_resp = requests.get(
                    f'https://www.themealdb.com/api/json/v1/1/filter.php?c={cat_name}',
                    timeout=10,
                )
                meals_resp.raise_for_status()
                meals = meals_resp.json().get('meals', []) or []
            except Exception as e:
                self.stderr.write(f'    Failed to fetch meals for {cat_name}: {e}')
                continue

            # Limit items per category
            meals = meals[:limit]

            for meal in meals:
                meal_name = meal['strMeal']
                meal_thumb = meal.get('strMealThumb', '')

                # Fetch full details for description
                description = ''
                try:
                    detail_resp = requests.get(
                        f'https://www.themealdb.com/api/json/v1/1/lookup.php?i={meal["idMeal"]}',
                        timeout=10,
                    )
                    detail_resp.raise_for_status()
                    detail_meals = detail_resp.json().get('meals', [])
                    if detail_meals:
                        full_desc = detail_meals[0].get('strInstructions', '')
                        # Take first 2 sentences as description
                        sentences = full_desc.split('.')
                        description = '. '.join(sentences[:2]).strip()
                        if description and not description.endswith('.'):
                            description += '.'
                except Exception:
                    description = f'Delicious {meal_name}'

                # Generate realistic price
                price_range = PRICE_RANGES.get(cat_name, (8, 20))
                price = Decimal(str(round(
                    random.uniform(price_range[0], price_range[1]), 2
                )))

                # Generate prep time
                prep_range = PREP_RANGES.get(cat_name, (10, 25))
                prep_time = random.randint(prep_range[0], prep_range[1])

                # Popular flag (20% chance)
                is_popular = random.random() < 0.2

                item, created = MenuItem.objects.get_or_create(
                    name=meal_name,
                    defaults={
                        'description': description[:500],
                        'price': price,
                        'category': category,
                        'available': True,
                        'is_popular': is_popular,
                        'preparation_time': prep_time,
                        'image': meal_thumb,
                    },
                )

                if created:
                    total_items += 1
                    self.stdout.write(
                        f'    ✅ {meal_name} — ${price} — {prep_time}min')
                else:
                    self.stdout.write(
                        f'    ⏭  {meal_name} (already exists)')

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(
            f'🎉 Done! Imported {total_items} new menu items.'))
        self.stdout.write(self.style.SUCCESS(
            f'   Total categories: {Category.objects.count()}'))
        self.stdout.write(self.style.SUCCESS(
            f'   Total menu items: {MenuItem.objects.count()}'))
