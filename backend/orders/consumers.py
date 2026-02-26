import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async


class OrderConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for real-time order updates."""

    async def connect(self):
        self.table_number = self.scope['url_route']['kwargs'].get('table_number')
        self.groups_joined = []

        # Join kitchen group (all orders)
        await self.channel_layer.group_add('kitchen', self.channel_name)
        self.groups_joined.append('kitchen')

        # Join table-specific group if table number provided
        if self.table_number:
            table_group = f'table_{self.table_number}'
            await self.channel_layer.group_add(table_group, self.channel_name)
            self.groups_joined.append(table_group)

        await self.accept()

        # Send connection confirmation
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': 'Connected to DineQR order system',
            'table_number': self.table_number,
        }))

    async def disconnect(self, close_code):
        # Leave all groups
        for group in self.groups_joined:
            await self.channel_layer.group_discard(group, self.channel_name)

    async def receive(self, text_data):
        """Handle incoming WebSocket messages."""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')

            if message_type == 'join_kitchen':
                await self.channel_layer.group_add('kitchen', self.channel_name)
                if 'kitchen' not in self.groups_joined:
                    self.groups_joined.append('kitchen')
                await self.send(text_data=json.dumps({
                    'type': 'joined',
                    'group': 'kitchen',
                }))

            elif message_type == 'join_table':
                table_num = data.get('table_number')
                if table_num:
                    table_group = f'table_{table_num}'
                    await self.channel_layer.group_add(table_group, self.channel_name)
                    if table_group not in self.groups_joined:
                        self.groups_joined.append(table_group)
                    await self.send(text_data=json.dumps({
                        'type': 'joined',
                        'group': table_group,
                    }))

            elif message_type == 'new_order':
                # Broadcast new order to kitchen
                await self.channel_layer.group_send(
                    'kitchen',
                    {
                        'type': 'new_order',
                        'order': data.get('order'),
                    }
                )

            elif message_type == 'order_status_update':
                order_data = data.get('order', {})
                table_number = data.get('table_number')

                # Broadcast to kitchen
                await self.channel_layer.group_send(
                    'kitchen',
                    {
                        'type': 'order_status_update',
                        'order': order_data,
                    }
                )
                # Broadcast to specific table
                if table_number:
                    await self.channel_layer.group_send(
                        f'table_{table_number}',
                        {
                            'type': 'order_status_update',
                            'order': order_data,
                        }
                    )

            elif message_type == 'call_waiter':
                table_number = data.get('table_number')
                await self.channel_layer.group_send(
                    'kitchen',
                    {
                        'type': 'waiter_call',
                        'table_number': table_number,
                        'message': data.get('message', 'Customer needs assistance'),
                    }
                )

        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Invalid JSON format',
            }))

    # === Group message handlers ===

    async def new_order(self, event):
        """Handle new order broadcast."""
        await self.send(text_data=json.dumps({
            'type': 'new_order',
            'order': event['order'],
        }))

    async def order_update(self, event):
        """Handle order update broadcast."""
        await self.send(text_data=json.dumps({
            'type': 'order_update',
            'order': event['order'],
        }))

    async def order_status_update(self, event):
        """Handle order status update broadcast."""
        await self.send(text_data=json.dumps({
            'type': 'order_status_update',
            'order': event['order'],
        }))

    async def waiter_call(self, event):
        """Handle waiter call broadcast."""
        await self.send(text_data=json.dumps({
            'type': 'waiter_call',
            'table_number': event['table_number'],
            'message': event['message'],
        }))
