import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/chat_list_screen.dart';

class CreativeChatPage extends StatelessWidget {
  const CreativeChatPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ChatListScreen(isCreative: true);
}