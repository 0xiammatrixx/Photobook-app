import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/chat_conversation_screen.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  final bool isCreative;
  const ChatListScreen({super.key, this.isCreative = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _filter = 'all'; // all | unread | favorites

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<UserProvider>().token ?? '';
      final userId = context.read<UserProvider>().user?['id'] ?? '';
      final chatProvider = context.read<ChatProvider>();

      if (!chatProvider.isSocketConnected) {
        print("🔌 Socket not connected — connecting now");
        chatProvider.connectSocket(token, userId);
      }

      chatProvider.loadConversations(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Chats',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for creatives by style, genre, location...',
                  hintStyle: const TextStyle(fontSize: 12),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  suffixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unread',
                    selected: _filter == 'unread',
                    onTap: () => setState(() => _filter = 'unread'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Favorites',
                    selected: _filter == 'favorites',
                    onTap: () => setState(() => _filter = 'favorites'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Conversation list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  print("🔄 ChatList rebuilding, convs: ${chatProvider.conversations.length}");
                 

                  final conversations = _filter == 'unread'
                      ? chatProvider.unreadConversations
                      : _filter == 'favorites'
                      ? chatProvider.favoriteConversations
                      : chatProvider.conversations;

                  if (conversations.isEmpty) {
                    return const Center(child: Text('No conversations yet'));
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return _ConversationTile(
                        conversation: conv,
                        isCreative: widget.isCreative,
                        isFavorite: chatProvider.isFavorite(conv['id']),
                        onFavoriteToggle: () =>
                            chatProvider.toggleFavorite(conv['id']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7A33) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFF7A33) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.black,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final bool isCreative;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _ConversationTile({
    required this.conversation,
    required this.isCreative,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final myId = context.read<UserProvider>().user?['id'] ?? '';
    final participants = List<dynamic>.from(conversation['participants'] ?? []);
    final other =
        participants.firstWhere(
              (p) => p['id'] != myId,
              orElse: () => <String, dynamic>{},
            )
            as Map<String, dynamic>;

    // ✅ Derive from other participant since title is null for direct chats
    final title =
        conversation['title'] ??
        other['businessName'] ?? // ✅ now available
        other['displayName'] ??
        other['name'] ??
        'Unknown';

    final avatarUrl = other['profilePhotoUrl']; // ✅ now available
    final lastMessage = conversation['lastMessage']?['content'] ?? '';
    final lastMessageAt = conversation['lastMessageAt'] ?? '';
    final conversationId = conversation['id'];

    // Unread: lastMessage sent after my lastReadAt
    final myParticipant =
        participants.firstWhere(
              (p) => p['id'] == myId,
              orElse: () => <String, dynamic>{},
            )
            as Map<String, dynamic>;
    final lastReadAt = myParticipant['lastReadAt'];
    final lastMsgAt = conversation['lastMessageAt'];
    final isUnread =
        lastReadAt != null &&
        lastMsgAt != null &&
        DateTime.parse(lastMsgAt).isAfter(DateTime.parse(lastReadAt)) &&
        conversation['lastMessage']?['senderId'] != myId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    (title.isNotEmpty ? title[0] : '?').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          // Online indicator dot
          Consumer<ChatProvider>(
            builder: (_, chat, __) {
              final isOnline = chat.isUserOnline(other['id'] ?? '');
              if (!isOnline) return const SizedBox.shrink();
              return Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(lastMessageAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          if (isUnread)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7A33),
                shape: BoxShape.circle,
              ),
            )
          else if (isFavorite)
            const Icon(Icons.star, color: Colors.orange, size: 14),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            conversationId: conversationId,
            title: title, // ✅ now correctly derived
            avatarUrl: avatarUrl, // ✅ now correctly derived
            isCreative:
                context.read<UserProvider>().user?['role'] == 'photographer', recipientId: other['id'] ?? '',
          ),
        ),
      ),
      onLongPress: onFavoriteToggle,
    );
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (now.difference(dt).inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
