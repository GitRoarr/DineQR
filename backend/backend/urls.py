"""
DineQR — Main URL Configuration
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from orders.views import TableByNumberView


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('users.urls')),
    path('api/menu/', include('menu.urls')),
    path('api/orders/', include('orders.urls')),

    # Public table endpoint used by QR codes, e.g. /table/7
    path('table/<int:number>/', TableByNumberView.as_view(), name='public-table-by-number'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
