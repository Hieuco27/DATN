import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  static const String _serverUrl = 'https://kltn-2025-ehsx.onrender.com';

  IO.Socket? _socket;

  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  void initSocket({int? userId}) {
    if (_socket != null && _socket!.connected) {
      if (userId != null) {
        joinUserRoom(userId);
      }
      return;
    }

    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());
    
    _socket?.connect();
    
    _socket?.onConnect((_) {
      
      // Auto join user room if userId provided
      if (userId != null) {
        joinUserRoom(userId);
      }
      
      // Listen for ANY event (for debugging)
      _socket?.onAny((event, data) {
        print('📡 Received ANY event: "$event" with data: $data');
      });
    });
    
    _socket?.onReconnect((_) {
      // Rejoin room after reconnect
      if (userId != null) {
        joinUserRoom(userId);
      }
    });

    _socket?.onDisconnect((_) {});

    _socket?.onConnectError((data) {});
    
    _socket?.onError((data) {
      print('❌ Socket error: $data');
    });
  }

  void joinUserRoom(int userId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }
    
    _socket?.emit('register', userId);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, (data) {
      callback(data);
    });
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
  
  bool get isConnected => _socket?.connected ?? false;
}
