import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../firebase/firebase_messaging_service.dart';
import '../firebase/firebase_providers.dart';

void showNotificationCenterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const NotificationCenterSheet(),
  );
}

class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  @override
  ConsumerState<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends ConsumerState<NotificationCenterSheet> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications from backend when sheet opens
    Future.microtask(() {
      ref.invalidate(fetchBackendNotificationsProvider);
    });
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildTypeBadge(String type) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (type.toLowerCase()) {
      case 'announcement':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.campaign_rounded;
        label = 'Announcement';
        break;
      case 'update':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4F46E5);
        icon = Icons.system_update_alt_rounded;
        label = 'Update';
        break;
      case 'promo':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        icon = Icons.card_giftcard_rounded;
        label = 'Special';
        break;
      default:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        icon = Icons.notifications_active_rounded;
        label = 'Notice';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(firebaseMessagingServiceProvider);

    return ValueListenableBuilder<List<AppNotificationItem>>(
      valueListenable: service.notificationsNotifier,
      builder: (context, notifications, _) {
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount new',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Stay updated with announcements and alerts',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        service.markAllAsRead();
                      });
                    },
                    child: const Text(
                      'Mark read',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D6EFD)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 44,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Announcements and project alerts will show up right here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 20),
                          // Device token copy helper for testing
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D6EFD),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.token_rounded, size: 14),
                            label: const Text('Copy FCM Device Token', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final token = await service.getSavedToken();
                              if (token != null) {
                                await Clipboard.setData(ClipboardData(text: token));
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('FCM Token copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('FCM token not available on this platform/emulator.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final item = notifications[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            service.markAsRead(item.id);
                          });
                          final route = item.data['route'] as String? ?? item.data['screen'] as String?;
                          if (route != null) {
                            Navigator.pop(context);
                            context.push(route);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isRead ? const Color(0xFFE5E7EB) : const Color(0xFFBAE6FD),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildTypeBadge(item.type),
                                  const Spacer(),
                                  Text(
                                    _formatTimestamp(item.receivedAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  if (!item.isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0D6EFD),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              if (item.message.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}
