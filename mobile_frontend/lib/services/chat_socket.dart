import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  static final ChatSocket _instance = ChatSocket._internal();
  factory ChatSocket() => _instance;
  ChatSocket._internal();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;
  final Set<String> _joinedRooms = {};

  // In chat_socket.dart
  Function(dynamic)? _onMessage;
  void connect(String token, Function(dynamic) onMessage) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    if (isConnected) return;
    _onMessage = onMessage;

    _socket = IO.io(
      'https://api.photobookhq.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    // ✅ Register BEFORE connect — socket.io buffers these
    _socket!.off('message');
    _socket!.on('message', (data) {
      print("📨 Raw socket message: $data");
      onMessage.call(data);
    });

    _socket!.onConnect((_) => print('✅ Socket connected'));
    _socket!.onDisconnect((_) => print('❌ Socket disconnected'));
    _socket!.onReconnect((_) {
      print("🔄 Socket reconnected");

      for (final room in _joinedRooms) {
        _socket!.emit('join_room', {'conversationId': room});
      }
    });
    _socket!.onReconnect((_) {
      print("🔄 Socket reconnected");

      for (final room in _joinedRooms) {
        _socket!.emit('join_room', {'conversationId': room});
      }
    });
    _socket!.connect();
  }

  void joinRoom(String conversationId) {
    if (!isConnected) {
      print("⚠️ Socket not connected yet");
      return;
    }

    _socket!.emit('join_room', {'conversationId': conversationId});
  }

  void sendMessage({required String conversationId, required String content}) {
    _socket!.emitWithAck(
      'send_message',
      {'conversationId': conversationId, 'content': content},
      ack: (response) {
        print("Server response: $response");
      },
    );
  }

  void offMessage() {
    _socket?.off('message');
  }

  void leaveRoom(String conversationId) {
    _socket?.emit('leave_room', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
