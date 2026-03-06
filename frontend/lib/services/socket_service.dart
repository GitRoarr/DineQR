import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/app_constants.dart';

/// WebSocket service for real-time order updates via Django Channels
class SocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Connection params for reconnect
  int? _tableNumber;
  String? _role;

  // Callbacks
  Function(Map<String, dynamic>)? onNewOrder;
  Function(Map<String, dynamic>)? onOrderStatusUpdate;
  Function(Map<String, dynamic>)? onOrderUpdate;
  Function(Map<String, dynamic>)? onWaiterCall;
  Function()? onConnect;
  Function()? onDisconnect;

  bool get isConnected => _isConnected;

  /// Connect to Django Channels WebSocket server
  void connect({int? tableNumber, String? role}) {
    _tableNumber = tableNumber;
    _role = role;

    // Build the WebSocket URL
    String url = AppConstants.wsUrl;
    if (tableNumber != null) {
      url += '/orders/$tableNumber/';
    } else {
      url += '/orders/';
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: () {
          _isConnected = false;
          onDisconnect?.call();
          print('🔌 WebSocket disconnected');
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          onDisconnect?.call();
          print('🔌 WebSocket error: $error');
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      onConnect?.call();
      print('🔌 WebSocket connected to $url');

      // Start ping timer to keep connection alive
      _startPingTimer();
    } catch (e) {
      print('🔌 WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'connection_established':
          print('🔌 Connection confirmed: ${data['message']}');
          break;
        case 'new_order':
          onNewOrder?.call(data['order'] ?? data);
          break;
        case 'order_status_update':
          onOrderStatusUpdate?.call(data['order'] ?? data);
          break;
        case 'order_update':
          onOrderUpdate?.call(data['order'] ?? data);
          break;
        case 'waiter_call':
          onWaiterCall?.call(data);
          break;
        case 'joined':
          print('🔌 Joined group: ${data['group']}');
          break;
        case 'error':
          print('🔌 Server error: ${data['message']}');
          break;
        default:
          print('🔌 Unknown message type: $type');
      }
    } catch (e) {
      print('🔌 Error parsing message: $e');
    }
  }

  /// Send a JSON message to the server
  void _send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Join kitchen group
  void joinKitchen() {
    _send({'type': 'join_kitchen'});
  }

  /// Join table group
  void joinTable(int tableNumber) {
    _send({'type': 'join_table', 'table_number': tableNumber});
  }

  /// Send new order event
  void emitNewOrder(Map<String, dynamic> orderData) {
    _send({'type': 'new_order', 'order': orderData});
  }

  /// Send order status update
  void emitStatusUpdate(int orderId, String status, {int? tableNumber}) {
    _send({
      'type': 'order_status_update',
      'order': {'order_id': orderId, 'status': status},
      'table_number': tableNumber,
    });
  }

  /// Call waiter
  void callWaiter(int tableNumber, {String message = 'Customer needs assistance'}) {
    _send({
      'type': 'call_waiter',
      'table_number': tableNumber,
      'message': message,
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('🔌 Attempting reconnect...');
        connect(tableNumber: _tableNumber, role: _role);
      }
    });
  }

  /// Disconnect socket
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}
