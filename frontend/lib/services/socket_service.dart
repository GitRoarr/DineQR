import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/app_constants.dart';

/// WebSocket service for real-time order updates
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNewOrder;
  Function(Map<String, dynamic>)? onOrderStatusUpdate;
  Function()? onConnect;
  Function()? onDisconnect;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  void connect({int? tableId, String? role}) {
    _socket = IO.io(
      AppConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({
            if (tableId != null) 'table_id': tableId.toString(),
            if (role != null) 'role': role,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      onConnect?.call();
      print('🔌 Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      onDisconnect?.call();
      print('🔌 Socket disconnected');
    });

    // Listen for new orders (kitchen receives this)
    _socket!.on('new_order', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      onNewOrder?.call(parsed);
    });

    // Listen for order status updates (customer receives this)
    _socket!.on('order_status_update', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      onOrderStatusUpdate?.call(parsed);
    });

    _socket!.connect();
  }

  /// Send new order event
  void emitNewOrder(Map<String, dynamic> orderData) {
    _socket?.emit('new_order', jsonEncode(orderData));
  }

  /// Send order status update
  void emitStatusUpdate(int orderId, String status) {
    _socket?.emit('order_status_update', jsonEncode({
      'order_id': orderId,
      'status': status,
    }));
  }

  /// Join table room for customer
  void joinTable(int tableId) {
    _socket?.emit('join_table', {'table_id': tableId});
  }

  /// Join kitchen room
  void joinKitchen() {
    _socket?.emit('join_kitchen', {});
  }

  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
