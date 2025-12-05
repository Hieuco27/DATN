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
    // If socket already exists and connected, just join room
    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected, joining room...');
      if (userId != null) {
        joinUserRoom(userId);
      }
      return;
    }

    // If socket exists but not connected, disconnect first
    if (_socket != null) {
      print('⚠️ Socket exists but not connected, recreating...');
      _socket?.disconnect();
      _socket = null;
    }

    print('🔌 Creating new socket connection...');
    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());
    
    // Setup event handlers BEFORE connect
    _setupEventHandlers(userId);
    
    print('📞 Calling socket.connect()...');
    _socket?.connect();
  }

  void _setupEventHandlers(int? userId) {
    _socket?.onConnect((_) {
      print('✅ Socket CONNECTED to $_serverUrl');
      
      // Auto join user room if userId provided
      if (userId != null) {
        print('🚪 Attempting to join room for user: $userId');
        joinUserRoom(userId);
      }
      
      // Listen for ANY event (for debugging)
      _socket?.onAny((event, data) {
        print('📡 Received ANY event: "$event" with data: $data');
      });
    });
    
    _socket?.onReconnect((_) {
      print('🔄 Socket RECONNECTED');
      // Rejoin room after reconnect
      if (userId != null) {
        print('🚪 Rejoining room for user: $userId');
        joinUserRoom(userId);
      }
    });

    _socket?.onDisconnect((_) {
      print('❌ Socket DISCONNECTED');
    });

    _socket?.onConnectError((data) {
      print('❌ Socket CONNECT ERROR: $data');
    });
    
    _socket?.onError((data) {
      print('❌ Socket ERROR: $data');
    });
  }

  void joinUserRoom(int userId) {
    if (_socket == null) {
      print('❌ Cannot join room: Socket is null');
      return;
    }
    
    if (!_socket!.connected) {
      print('❌ Cannot join room: Socket not connected');
      return;
    }
    
    print('📤 Emitting "register" event with userId: $userId');
    _socket?.emit('register', userId);
    print('✅ "register" event emitted, waiting for server confirmation...');
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
