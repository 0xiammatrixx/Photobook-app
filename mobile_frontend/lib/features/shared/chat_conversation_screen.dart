import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/offer_bubble.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';
import 'package:mobile_frontend/features/shared/send_custom_offer_screen.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
 
class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String? avatarUrl;
  final bool isCreative;
  final String recipientId;
 
  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    required this.recipientId,
    this.avatarUrl,
    this.isCreative = false,
  });
 
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}
 
class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showActions = false;
  late ChatProvider _chatProvider; // ✅ save reference
 
  // In-memory only for now — see caveat in the offer-details write-up.
  final Set<String> _declinedOfferIds = {};
  final Set<String> _supersededOfferIds = {};
 
  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>(); // ✅ capture here
 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<UserProvider>().token ?? '';
      _chatProvider.loadMessages(token, widget.conversationId).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      });
    });
 
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 100) {
        final token = context.read<UserProvider>().token ?? '';
        _chatProvider.loadMoreMessages(token, widget.conversationId);
      }
    });
  }
 
  @override
  void dispose() {
    _chatProvider.leaveConversation(widget.conversationId); // ✅ no context
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
 
  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    _controller.clear();
    final token = context.read<UserProvider>().token ?? '';
    context.read<ChatProvider>().sendMessage(
      token: token,
      conversationId: widget.conversationId,
      content: content,
    );
    _scrollToBottom();
  }
 
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
 
  Future<void> _sendRateCard() async {
    final token = context.read<UserProvider>().token ?? '';
    try {
      final items = await ProfilePortfolioService().getMyRateCard(token: token);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your rate card is empty')),
        );
        return;
      }
 
      // Format rate card as a readable message
      final lines = items
          .map((item) {
            final name = item['serviceName'] ?? '';
            final price = item['pricingMode'] == 'contact'
                ? 'Contact for price'
                : '₦${item['pricingAmount']}';
            return '• $name — $price';
          })
          .join('\n');
 
      final content = '📋 *My Rate Card*\n$lines';
      context.read<ChatProvider>().sendMessage(
        token: token,
        conversationId: widget.conversationId,
        content: content,
      );
      setState(() => _showActions = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send rate card: $e')));
    }
  }
 
  void _openSendCustomOffer() {
    final token = context.read<UserProvider>().token ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendCustomOfferScreen(
          token: token,
          conversationId: widget.conversationId,
          recipientId: widget.recipientId,
          recipientName: widget.title,
        ),
      ),
    );
    setState(() => _showActions = false);
  }
 
  @override
  Widget build(BuildContext context) {
    final myId = context.read<UserProvider>().user?['id'] ?? '';
    final token = context.read<UserProvider>().token ?? '';
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Active',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final messages = chatProvider.getMessages(
                  widget.conversationId,
                );
 
                if (messages.isEmpty) {
                  return const SizedBox.shrink(); // silent empty
                }
 
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == myId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      token: token,
                      conversationId: widget.conversationId,
                      recipientId: widget.recipientId,
                      counterpartyName: widget.title,
                      counterpartyAvatarUrl: widget.avatarUrl,
                      declinedOfferIds: _declinedOfferIds,
                      supersededOfferIds: _supersededOfferIds,
                      onOfferDeclined: (id) =>
                          setState(() => _declinedOfferIds.add(id)),
                      onOfferEdited: (id) =>
                          setState(() => _supersededOfferIds.add(id)),
                    );
                  },
                );
              },
            ),
          ),
 
          // Creative action panel
          if (_showActions && widget.isCreative)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: '📋',
                      label: 'Send Rate Card',
                      subtitle: 'Let clients view your rates',
                      onTap: _sendRateCard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: '✉️',
                      label: 'Send Custom Offer',
                      subtitle: 'Send the negotiated price',
                      onTap: _openSendCustomOffer,
                    ),
                  ),
                ],
              ),
            ),
 
          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Emoji placeholder
                  const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  // Actions toggle (creative only)
                  if (widget.isCreative)
                    GestureDetector(
                      onTap: () => setState(() => _showActions = !_showActions),
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: _showActions
                            ? const Color(0xFFFF7A33)
                            : Colors.grey,
                        size: 22,
                      ),
                    ),
                  if (widget.isCreative) const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFFF7A33),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String token;
  final String conversationId;
  final String recipientId;
  final String counterpartyName;
  final String? counterpartyAvatarUrl;
  final Set<String> declinedOfferIds;
  final Set<String> supersededOfferIds;
  final void Function(String offerId) onOfferDeclined;
  final void Function(String offerId) onOfferEdited;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.token,
    required this.conversationId,
    required this.recipientId,
    required this.counterpartyName,
    required this.declinedOfferIds,
    required this.supersededOfferIds,
    required this.onOfferDeclined,
    required this.onOfferEdited,
    this.counterpartyAvatarUrl,
  });
 
  @override
  Widget build(BuildContext context) {
    final content = message['content'] ?? '';
    final createdAt = message['createdAt'] ?? '';
 
    final isRateCard = content.startsWith('📋 *My Rate Card*');
    final offerPayload = OfferMessagePayload.tryParse(content);
    final isSpecialBubble = isRateCard || offerPayload != null;
 
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: isSpecialBubble
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSpecialBubble
              ? const Color(0xFFF5F9F6)
              : isMe
              ? const Color(0xFFE8F5E9)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isSpecialBubble
              ? Border.all(color: const Color(0xFF047418), width: 0.8)
              : null,
        ),
        child: offerPayload != null
            ? OfferBubble(
                payload: offerPayload,
                isMe: isMe,
                isDeclined: declinedOfferIds.contains(offerPayload.offerId),
                isSuperseded: supersededOfferIds.contains(offerPayload.offerId),
                token: token,
                conversationId: conversationId,
                recipientId: recipientId,
                counterpartyName: counterpartyName,
                counterpartyAvatarUrl: counterpartyAvatarUrl,
                onDeclined: onOfferDeclined,
                onEdited: onOfferEdited,
              )
            : isRateCard
                ? _RateCardBubble(content: content)
                : Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(content, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(createdAt),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
      ),
    );
  }
 
  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
 
class _RateCardBubble extends StatelessWidget {
  final String content;
  const _RateCardBubble({required this.content});
 
  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final items = lines.skip(1).toList();
 
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📋', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Rate Card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ...items.map(
                (line) => Text(
                  line,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
 
class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
 
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}