import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../screens/notification/notifications_screen.dart';

/// A notification bell icon with badge showing unread count
/// Use this widget in AppBar actions
class NotificationBell extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;
  final bool showBadge;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.iconSize = 24,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        final hasUnread = unreadCount > 0;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                hasUnread
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
              if (showBadge && hasUnread)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _navigateToNotifications(context),
          tooltip: 'Notifications',
        );
      },
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}

/// A compact notification badge (just the count circle)
/// Use this inside other widgets like NavigationDestination
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool show;

  const NotificationBadge({
    super.key,
    required this.child,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;

        if (unreadCount == 0) return child;

        return Badge(
          label: Text('$unreadCount'),
          child: child,
        );
      },
    );
  }
}

/// A notification list tile for showing recent notifications inline
class NotificationPreviewTile extends StatelessWidget {
  final VoidCallback? onTap;
  final int maxNotifications;

  const NotificationPreviewTile({
    super.key,
    this.onTap,
    this.maxNotifications = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;
        final unreadCount = notificationProvider.unreadCount;

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentNotifications = notifications.take(maxNotifications).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.notifications, color: AppColors.primary),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  'Notifications',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  unreadCount > 0
                      ? '$unreadCount unread notification${unreadCount != 1 ? 's' : ''}'
                      : 'All caught up',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTap ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
              ),
              if (recentNotifications.isNotEmpty) ...[
                const Divider(height: 1),
                ...recentNotifications.map((notification) => ListTile(
                      dense: true,
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Colors.transparent
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notification.body,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        if (!notification.isRead) {
                          notificationProvider.markAsRead(notification.id);
                        }
                      },
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}