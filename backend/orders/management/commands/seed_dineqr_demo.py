from django.core.management.base import BaseCommand
from django.db import transaction

from menu.models import Category, MenuItem
from orders.models import Table


class Command(BaseCommand):
    help = (
        "Seed demo data for DineQR: tables 1-20, sample menu items, "
        "and QR codes for each table."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--base-url",
            dest="base_url",
            default="http://127.0.0.1:8000",
            help=(
                "Base URL encoded in QR codes. "
                "Example: https://dineqr.com or http://192.168.1.10:8000"
            ),
        )

    @transaction.atomic
    def handle(self, *args, **options):
        base_url = options["base_url"].rstrip("/")

        self.stdout.write(self.style.MIGRATE_HEADING("Seeding DineQR demo data..."))

        categories_config = [
            {"name": "Breakfast", "description": "Morning specials and classics"},
            {"name": "Mains", "description": "Burgers, pizza, pasta and more"},
            {"name": "Drinks", "description": "Coffee, soft drinks and juices"},
            {"name": "Desserts", "description": "Sweet treats and cakes"},
        ]

        categories = {}
        for cfg in categories_config:
            category, created = Category.objects.get_or_create(
                name=cfg["name"],
                defaults={"description": cfg["description"]},
            )
            categories[cfg["name"]] = category
            if created:
                self.stdout.write(self.style.SUCCESS(f"Created category: {category.name}"))

        # 2) Create demo menu items (realistic café items)
        items_config = [
            # Breakfast
            {"name": "Pancakes", "price": 6.99, "category": "Breakfast"},
            {"name": "Omelette", "price": 5.99, "category": "Breakfast"},
            # Mains
            {"name": "Beef Burger", "price": 10.99, "category": "Mains"},
            {"name": "Chicken Burger", "price": 9.99, "category": "Mains"},
            {"name": "Margherita Pizza", "price": 13.99, "category": "Mains"},
            {"name": "Creamy Pasta", "price": 12.99, "category": "Mains"},
            # Drinks
            {"name": "Coffee", "price": 3.00, "category": "Drinks"},
            {"name": "Latte", "price": 4.50, "category": "Drinks"},
            {"name": "Orange Juice", "price": 4.00, "category": "Drinks"},
            # Desserts
            {"name": "Chocolate Cake", "price": 6.00, "category": "Desserts"},
            {"name": "Ice Cream", "price": 4.50, "category": "Desserts"},
        ]

        for cfg in items_config:
            category = categories[cfg["category"]]
            item, created = MenuItem.objects.get_or_create(
                name=cfg["name"],
                defaults={
                    "description": cfg["name"],
                    "price": cfg["price"],
                    "category": category,
                },
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f"Created menu item: {item.name}"))

        self.stdout.write(self.style.MIGRATE_LABEL("Creating tables 1-20 and QR codes..."))

        for number in range(1, 21):
            table, created = Table.objects.get_or_create(
                number=number,
                defaults={
                    "name": f"Table {number}",
                    "capacity": 4,
                    "is_active": True,
                },
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f"Created {table}"))

            table.generate_qr_code(base_url=base_url)
            self.stdout.write(
                self.style.SUCCESS(
                    f"QR generated for {table} → {base_url}/table/{table.number}"
                )
            )

        self.stdout.write(self.style.SUCCESS("DineQR demo data seeding completed."))
