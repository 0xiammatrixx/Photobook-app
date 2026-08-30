import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationProvider>().markAllRead(),
            child: const Text('Mark all as read',
                style: TextStyle(color: Color(0xFFFF7A33), fontSize: 12)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: const [
                SkeletonListTile(),
                SkeletonListTile(),
                SkeletonListTile(),
                SkeletonListTile(),
              ],
            );
          }

          final notifications = provider.notifications;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No notifications yet',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor:
                    n.read ? null : const Color(0xFFFF7A33).withOpacity(0.04),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: n.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.color, size: 20),
                ),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(_formatTime(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                onTap: () {
                  if (!n.read) {
                    context.read<NotificationProvider>().markRead(n.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}