from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/orders/$', consumers.OrderConsumer.as_asgi()),
    re_path(r'ws/orders/(?P<table_number>\d+)/$', consumers.OrderConsumer.as_asgi()),
]
