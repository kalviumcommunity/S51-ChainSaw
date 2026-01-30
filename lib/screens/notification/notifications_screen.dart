import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;
        final unreadCount = notificationProvider.unreadCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () => _markAllAsRead(notificationProvider),
                  icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) => _handleMenuAction(value, notificationProvider),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete all', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: notificationProvider.isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(notifications, notificationProvider),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      List<NotificationModel> notifications, NotificationProvider provider) {
    // Group notifications by date
    final grouped = _groupNotificationsByDate(notifications);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by stream, just wait a bit for visual feedback
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
          return _buildDateGroup(entry.key, entry.value, provider);
        },
      ),
    );
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate(
      List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildDateGroup(String dateLabel, List<NotificationModel> notifications,
      NotificationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ...notifications.map((n) => _buildNotificationCard(n, provider)),
      ],
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, NotificationProvider provider) {
    final typeInfo = _getNotificationTypeInfo(notification.type);
    final timeFormat = DateFormat('h:mm a');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppColors.primary.withAlpha(15),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeInfo.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          timeFormat.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationTypeInfo _getNotificationTypeInfo(NotificationType type) {
    switch (type) {
      case NotificationType.visitorArrived:
        return _NotificationTypeInfo(
          icon: Icons.person_add,
          color: AppColors.pending,
        );
      case NotificationType.visitorApproved:
        return _NotificationTypeInfo(
          icon: Icons.check_circle,
          color: AppColors.approved,
        );
      case NotificationType.visitorDenied:
        return _NotificationTypeInfo(
          icon: Icons.cancel,
          color: AppColors.denied,
        );
      case NotificationType.visitorCheckedOut:
        return _NotificationTypeInfo(
          icon: Icons.logout,
          color: AppColors.checkedOut,
        );
      case NotificationType.newResident:
        return _NotificationTypeInfo(
          icon: Icons.home,
          color: AppColors.residentColor,
        );
      case NotificationType.flatAssigned:
        return _NotificationTypeInfo(
          icon: Icons.apartment,
          color: AppColors.info,
        );
      case NotificationType.systemAlert:
        return _NotificationTypeInfo(
          icon: Icons.info,
          color: AppColors.warning,
        );
    }
  }

  void _handleNotificationTap(
      NotificationModel notification, NotificationProvider provider) {
    // Mark as read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    final data = notification.data;
    if (data != null) {
      final action = data['action'] as String?;

      switch (action) {
        case 'approve_visitor':
          // Navigate to visitor requests
          Navigator.pop(context);
          // Could navigate to specific screen based on role
          break;
        case 'allow_entry':
        case 'deny_entry':
          // Navigate to pending visitors (guard)
          Navigator.pop(context);
          break;
        default:
          // Just close and go back
          break;
      }
    }

    // Show detail bottom sheet
    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(NotificationModel notification) {
    final typeInfo = _getNotificationTypeInfo(notification.type);
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeInfo.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      typeInfo.icon,
                      color: typeInfo.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.type.displayTitle,
                          style: TextStyle(
                            color: typeInfo.color,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                notification.body,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _markAllAsRead(NotificationProvider provider) {
    provider.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action, NotificationProvider provider) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead(provider);
        break;
      case 'delete_all':
        _showDeleteAllConfirmation(provider);
        break;
    }
  }

  void _showDeleteAllConfirmation(NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTypeInfo {
  final IconData icon;
  final Color color;

  _NotificationTypeInfo({required this.icon, required this.color});
}