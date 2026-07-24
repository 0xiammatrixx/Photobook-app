import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  static final ChatSocket _instance = ChatSocket._internal();
  factory ChatSocket() => _instance;
  ChatSocket._internal();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;
  final Set<String> _joinedRooms = {};

  Function(dynamic)? _onMessage;
  Function(String userId, String conversationId)? _onTyping;
  Function(String userId, String conversationId)? _onStopTyping;
  Function(String userId)? _onUserOnline;
  Function(String userId, String? lastSeenAt)? _onUserOffline;

  // Call signaling — set via setCallHandlers(), independent of connect(),
  // since CallProvider may register these before or after the socket
  // actually connects.
  Function(String fromUserId, String conversationId, Map offer)? _onCallOffer;
  Function(String fromUserId, String conversationId, Map answer)? _onCallAnswer;
  Function(String fromUserId, String conversationId, Map candidate)? _onIceCandidate;
  Function(String conversationId, String fromUserId)? _onCallEnd;
  Function(String conversationId, String fromUserId)? _onCallDecline;

  void setCallHandlers({
    Function(String fromUserId, String conversationId, Map offer)? onCallOffer,
    Function(String fromUserId, String conversationId, Map answer)? onCallAnswer,
    Function(String fromUserId, String conversationId, Map candidate)? onIceCandidate,
    Function(String conversationId, String fromUserId)? onCallEnd,
    Function(String conversationId, String fromUserId)? onCallDecline,
  }) {
    _onCallOffer = onCallOffer;
    _onCallAnswer = onCallAnswer;
    _onIceCandidate = onIceCandidate;
    _onCallEnd = onCallEnd;
    _onCallDecline = onCallDecline;
  }

  void connect(
    String token,
    Function(dynamic) onMessage, {
    Function(String userId, String conversationId)? onTyping,
    Function(String userId, String conversationId)? onStopTyping,
    Function(String userId)? onUserOnline,
    Function(String userId, String? lastSeenAt)? onUserOffline,
  }) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    if (isConnected) return;
    _onMessage = onMessage;
    _onTyping = onTyping;
    _onStopTyping = onStopTyping;
    _onUserOnline = onUserOnline;
    _onUserOffline = onUserOffline;

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

    _socket!.off('user:typing');
    _socket!.on('user:typing', (data) {
      _onTyping?.call(data['userId'], data['conversationId']);
    });

    _socket!.off('user:stop_typing');
    _socket!.on('user:stop_typing', (data) {
      _onStopTyping?.call(data['userId'], data['conversationId']);
    });

    _socket!.off('user:online');
    _socket!.on('user:online', (data) {
      _onUserOnline?.call(data['userId']);
    });

    _socket!.off('user:offline');
    _socket!.on('user:offline', (data) {
      _onUserOffline?.call(data['userId'], data['lastSeenAt']);
    });

    _socket!.off('webrtc_offer');
    _socket!.on('webrtc_offer', (data) {
      _onCallOffer?.call(
        data['fromUserId'],
        data['conversationId'],
        Map<String, dynamic>.from(data['offer'] ?? {}),
      );
    });

    _socket!.off('webrtc_answer');
    _socket!.on('webrtc_answer', (data) {
      _onCallAnswer?.call(
        data['fromUserId'],
        data['conversationId'],
        Map<String, dynamic>.from(data['answer'] ?? {}),
      );
    });

    _socket!.off('ice_candidate');
    _socket!.on('ice_candidate', (data) {
      _onIceCandidate?.call(
        data['fromUserId'],
        data['conversationId'],
        Map<String, dynamic>.from(data['candidate'] ?? {}),
      );
    });

    // NOT in the documented event schema (only webrtc_offer/answer and
    // ice_candidate are). Registered anyway so hangup/decline become
    // instant the moment the backend adds them — harmless no-ops until
    // then. Until it's added, calls end via ICE-connection-state
    // detection instead (see CallProvider), which is slower.
    _socket!.off('call:end');
    _socket!.on('call:end', (data) {
      _onCallEnd?.call(data['conversationId'], data['fromUserId']);
    });

    _socket!.off('call:decline');
    _socket!.on('call:decline', (data) {
      _onCallDecline?.call(data['conversationId'], data['fromUserId']);
    });

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      for (final room in _joinedRooms) {
        _socket!.emit('join_room', {'conversationId': room});
      }
    });
    _socket!.onDisconnect((_) => print('❌ Socket disconnected'));
    _socket!.onReconnect((_) {
      print("🔄 Socket reconnected");
      for (final room in _joinedRooms) {
        _socket!.emit('join_room', {'conversationId': room});
      }
    });
    _socket!.connect();
  }

  void joinRoom(String conversationId) {
    _joinedRooms.add(conversationId);
    if (!isConnected) {
      print("⚠️ Socket not connected yet — will join once connected");
      return;
    }
    _socket!.emit('join_room', {'conversationId': conversationId});
  }

  void leaveRoom(String conversationId) {
    _joinedRooms.remove(conversationId);
    _socket?.emit('leave_room', {'conversationId': conversationId});
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

  void startTyping(String conversationId) {
    if (!isConnected) return;
    _socket!.emit('typing:start', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    if (!isConnected) return;
    _socket!.emit('typing:stop', {'conversationId': conversationId});
  }

  void sendCallOffer({required String conversationId, required Map offer}) {
    if (!isConnected) return;
    _socket!.emit('webrtc_offer', {
      'conversationId': conversationId,
      'offer': offer,
    });
  }

  void sendCallAnswer({required String conversationId, required Map answer}) {
    if (!isConnected) return;
    _socket!.emit('webrtc_answer', {
      'conversationId': conversationId,
      'answer': answer,
    });
  }

  void sendIceCandidate({
    required String conversationId,
    required Map candidate,
  }) {
    if (!isConnected) return;
    _socket!.emit('ice_candidate', {
      'conversationId': conversationId,
      'candidate': candidate,
    });
  }

  /// Not a documented event — ask the backend to broadcast this (and
  /// call:decline) to the room so the other side ends the call instantly
  /// instead of waiting for their ICE connection to time out.
  void sendCallEnd(String conversationId) {
    if (!isConnected) return;
    _socket!.emit('call:end', {'conversationId': conversationId});
  }

  void sendCallDecline(String conversationId) {
    if (!isConnected) return;
    _socket!.emit('call:decline', {'conversationId': conversationId});
  }

  void offMessage() {
    _socket?.off('message');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}