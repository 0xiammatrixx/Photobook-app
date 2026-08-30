import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/chat_service.dart';
import 'package:mobile_frontend/services/chat_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  final _service = ChatService();
  final _socket = ChatSocket();
  bool get isSocketConnected => _socket.isConnected;
  bool get isSocketConnecting => _socket.isConnecting;
  String? _myId;
  String? _token;

  /// Invoked when a message arrives from another user (not my own). Set from
  /// the app root to surface an in-app banner / notification.
  void Function(Map<String, dynamic> message)? onIncomingMessage;

  // userId -> online/offline + last seen
  final Map<String, bool> _onlineUsers = {};
  final Map<String, DateTime?> _lastSeenAt = {};
  // conversationId -> set of userIds currently typing in that room
  final Map<String, Set<String>> _typingUsers = {};

  bool isUserOnline(String userId) => _onlineUsers[userId] ?? false;
  DateTime? lastSeenAt(String userId) => _lastSeenAt[userId];

  bool isUserTyping(String conversationId, String userId) =>
      _typingUsers[conversationId]?.contains(userId) ?? false;

  /// Fallback: get the timestamp of the last message sent BY this user
  /// in the given conversation. Used when the server hasn't emitted a
  /// user:offline event yet (e.g. you connected after they went offline).
  DateTime? lastMessageFrom(String conversationId, String userId) {
    final msgs = _messages[conversationId];
    if (msgs == null || msgs.isEmpty) return null;
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i]['senderId'] == userId) {
        final ts = msgs[i]['createdAt'];
        if (ts != null) return DateTime.tryParse(ts);
      }
    }
    return null;
  }

  void connectSocket(String token, String userId) {
    _myId = userId;
    _token = token;
    _socket.connect(
      token,
      _handleIncomingMessage,
      onTyping: (uid, conversationId) {
        _typingUsers.putIfAbsent(conversationId, () => {}).add(uid);
        notifyListeners();
      },
      onStopTyping: (uid, conversationId) {
        _typingUsers[conversationId]?.remove(uid);
        notifyListeners();
      },
      onUserOnline: (uid) {
        print('🟢 [ChatProvider] user online: $uid');
        _onlineUsers[uid] = true;
        notifyListeners();
      },
      onUserOffline: (uid, lastSeenIso) {
        print('🔴 [ChatProvider] user offline: $uid, lastSeenIso=$lastSeenIso');
        _onlineUsers[uid] = false;
        if (lastSeenIso != null && lastSeenIso.isNotEmpty) {
          final parsed = DateTime.tryParse(lastSeenIso);
          if (parsed != null) {
            _lastSeenAt[uid] = parsed;
            print('🔴 [ChatProvider] last seen parsed: $parsed');
          } else {
            print('🔴 [ChatProvider] last seen parse FAILED for: $lastSeenIso');
          }
        } else {
          print('🔴 [ChatProvider] no lastSeenAt in offline event');
        }
        notifyListeners();
      },
    );
  }

  void startTyping(String conversationId) => _socket.startTyping(conversationId);
  void stopTyping(String conversationId) => _socket.stopTyping(conversationId);

  void _handleIncomingMessage(dynamic msg) {
    print("📨 Provider handling message: $msg");
    final conversationId = msg['conversationId'];

    // ✅ Update messages if conversation is open
    if (_messages.containsKey(conversationId)) {
      _messages[conversationId] = [...(_messages[conversationId] ?? []), msg];
    }

    // ✅ Always update conversation list preview
    final idx = _conversations.indexWhere((c) => c['id'] == conversationId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_conversations[idx]);
      updated['lastMessage'] = msg;
      updated['lastMessageAt'] = msg['createdAt'];
      _conversations[idx] = updated;
      print("✅ Updated conversation preview at idx $idx");
    } else {
      // New conversation — reload list
      if (_token != null) loadConversations(_token!);
    }

    notifyListeners(); // ✅ updates chat list, nav badge, everything

    // Surface an in-app banner for messages from other users so the user is
    // alerted even when they're not looking at this conversation.
    final senderId = msg['senderId'];
    if (senderId != null && senderId != _myId) {
      onIncomingMessage?.call(Map<String, dynamic>.from(msg));
    }
  }

  List<dynamic> _conversations = [];
  List<dynamic> get conversations => _conversations;

  Map<String, List<dynamic>> _messages = {}; // conversationId → messages
  Map<String, String?> _cursors = {}; // conversationId → nextCursor
  Map<String, bool> _hasMore = {};

  Set<String> _favorites = {};

  bool isLoading = false;
  bool isSending = false;

  List<dynamic> getMessages(String conversationId) =>
      _messages[conversationId] ?? [];

  bool hasMoreMessages(String conversationId) =>
      _hasMore[conversationId] ?? true;

  int get totalUnread {
    // we need myId here — pass it in or store it
    return _conversations.where((c) {
      final lastMsgAt = c['lastMessageAt'];
      final participants = List<dynamic>.from(c['participants'] ?? []);
      final me =
          participants.firstWhere(
                (p) => p['id'] == _myId,
                orElse: () => <String, dynamic>{},
              )
              as Map<String, dynamic>;
      final lastReadAt = me['lastReadAt'];
      if (lastMsgAt == null || lastReadAt == null) return false;
      return DateTime.parse(lastMsgAt).isAfter(DateTime.parse(lastReadAt)) &&
          c['lastMessage']?['senderId'] != _myId;
    }).length;
  }

  // ── Conversations ──

  Future<void> loadConversations(String token) async {
    _token = token;
    try {
      _conversations = await _service.getConversations(token: token);
      await _loadFavorites();
      // Join every conversation room — not just the one currently open —
      // so incoming messages *and* incoming calls (webrtc_offer is
      // broadcast to the room) reach you no matter which screen you're on.
      for (final c in _conversations) {
        final id = c['id'];
        if (id != null) _socket.joinRoom(id);
      }
      notifyListeners();
      print("💬 Conversations: $_conversations");
    } catch (e) {
      print('❌ Load conversations: $e');
    }
  }

  Future<Map<String, dynamic>> createConversation({
    required String token,
    required String participantId,
    String? initialMessage,
  }) async {
    final result = await _service.createConversation(
      token: token,
      participantId: participantId,
      initialMessage: initialMessage,
    );
    await loadConversations(token);
    return result;
  }

  // ── Messages ──

  // In ChatProvider
  final Set<String> _joinedRooms = {};

  Future<void> loadMessages(String token, String conversationId) async {
    try {
      final result = await _service.getMessages(
        token: token,
        conversationId: conversationId,
      );
      _messages[conversationId] = List.from(
        (result['messages'] ?? []).reversed,
      );
      _cursors[conversationId] = result['nextCursor'];
      _hasMore[conversationId] = result['nextCursor'] != null;

      // Mark read locally
      _markReadLocally(conversationId);

      // Join room
      _joinedRooms.add(conversationId);
      if (_socket.isConnected) {
        _socket.joinRoom(conversationId);
      } else {
        print("Socket not ready, will join after connect");
      }

      notifyListeners();
    } catch (e) {
      print('❌ Load messages: $e');
    }
  }

  void _markReadLocally(String conversationId) {
    final idx = _conversations.indexWhere((c) => c['id'] == conversationId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_conversations[idx]);
      final participants = List<dynamic>.from(updated['participants'] ?? []);
      final now = DateTime.now().toUtc().toIso8601String();
      final myIdx = participants.indexWhere((p) => p['id'] == _myId);
      if (myIdx != -1) {
        final p = Map<String, dynamic>.from(participants[myIdx]);
        p['lastReadAt'] = now;
        participants[myIdx] = p;
        updated['participants'] = participants;
        _conversations[idx] = updated;
      }
    }
  }

  Map<String, dynamic> getOtherParticipant(
    Map<String, dynamic> conversation,
    String myId,
  ) {
    final participants = List<dynamic>.from(conversation['participants'] ?? []);
    return participants.firstWhere((p) => p['id'] != myId, orElse: () => {})
        as Map<String, dynamic>;
  }

  Future<void> loadMoreMessages(String token, String conversationId) async {
    final cursor = _cursors[conversationId];
    if (cursor == null) return;
    try {
      final result = await _service.getMessages(
        token: token,
        conversationId: conversationId,
        cursor: cursor,
      );
      final older = List.from((result['messages'] ?? []).reversed);
      _messages[conversationId] = [
        ...older,
        ...(_messages[conversationId] ?? []),
      ];
      _cursors[conversationId] = result['nextCursor'];
      _hasMore[conversationId] = result['nextCursor'] != null;
      notifyListeners();
    } catch (e) {
      print('❌ Load more messages: $e');
    }
  }

  Future<void> sendMessage({
    required String token,
    required String conversationId,
    required String content,
  }) async {
    isSending = true;
    notifyListeners();
    try {
      // Try socket first, fall back to REST
      if (_socket.isConnected) {
        _socket.sendMessage(conversationId: conversationId, content: content);
      } else {
        final result = await _service.sendMessage(
          token: token,
          conversationId: conversationId,
          content: content,
        );
        final msg = result['message'] ?? result;
        _messages[conversationId] = [...(_messages[conversationId] ?? []), msg];
        notifyListeners();
      }
    } catch (e) {
      print('❌ Send message: $e');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  // ── Favorites (local) ──

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = Set.from(prefs.getStringList('favorite_conversations') ?? []);
  }

  Future<void> toggleFavorite(String conversationId) async {
    if (_favorites.contains(conversationId)) {
      _favorites.remove(conversationId);
    } else {
      _favorites.add(conversationId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_conversations', _favorites.toList());
    notifyListeners();
  }

  bool isFavorite(String conversationId) => _favorites.contains(conversationId);

  List<dynamic> get favoriteConversations =>
      _conversations.where((c) => _favorites.contains(c['id'])).toList();

  List<dynamic> get unreadConversations => _conversations
      .where((c) => c['unreadCount'] != null && c['unreadCount'] > 0)
      .toList();

  // ── Socket lifecycle ──

  void leaveConversation(String conversationId) {
    _socket.leaveRoom(conversationId);
  }

  void disconnectSocket() => _socket.disconnect();

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}