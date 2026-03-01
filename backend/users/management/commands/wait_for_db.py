import time

from django.core.management.base import BaseCommand
from django.db import connections
from django.db.utils import OperationalError


class Command(BaseCommand):
    help = "Block until the default database is available."

    def handle(self, *args, **options):
        self.stdout.write("Waiting for database...")
        db_conn = None
        while not db_conn:
            try:
                db_conn = connections["default"]
                db_conn.ensure_connection()
            except OperationalError as exc:
                self.stdout.write(
                    self.style.WARNING(f"Database unavailable ({exc}), retrying in 3s...")
                )
                time.sleep(3)
            else:
                self.stdout.write(self.style.SUCCESS("Database available!"))
