import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // State
  NotificationStatus _status = NotificationStatus.initial;
  String? _errorMessage;
  String? _currentUserId;

  // Data
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  // Stream subscriptions
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;

  // Callback for notification tap navigation
  Function(Map<String, dynamic> data)? onNotificationTap;

  // Getters
  NotificationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationStatus.loading;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  // Filtered getters
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize notification provider for a user
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return; // Already initialized for this user

    _currentUserId = userId;
    _status = NotificationStatus.loading;
    notifyListeners();

    try {
      // Initialize notification service
      await _notificationService.initialize();

      // Save FCM token for this user
      await _notificationService.saveTokenToUser(userId);

      // Listen for token refresh
      _notificationService.onTokenRefresh(userId);

      // Start streaming notifications
      _startNotificationsStream(userId);

      // Start streaming unread count
      _startUnreadCountStream(userId);

      // Listen for notification taps
      _listenForNotificationTaps();

      _status = NotificationStatus.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationStatus.error;
      notifyListeners();
    }
  }

  /// Start streaming notifications for user
  void _startNotificationsStream(String userId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationService
        .streamUserNotifications(userId)
        .listen(
      (notifications) {
        _notifications = notifications;
        _status = NotificationStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Start streaming unread count
  void _startUnreadCountStream(String userId) {
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = _notificationService
        .streamUnreadCount(userId)
        .listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming unread count: $error');
      },
    );
  }

  /// Listen for notification taps
  void _listenForNotificationTaps() {
    _notificationTapSubscription?.cancel();
    _notificationTapSubscription = _notificationService.onNotificationTap.listen(
      (data) {
        if (onNotificationTap != null) {
          onNotificationTap!(data);
        }
      },
    );
  }

  // ============================================================
  // NOTIFICATION ACTIONS
  // ============================================================

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state immediately for better UX
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.markAllAsRead(_currentUserId!);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.deleteAllNotifications(_currentUserId!);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ============================================================
  // SEND NOTIFICATIONS (used by other parts of the app)
  // ============================================================

  /// Notify resident about new visitor (called when guard adds visitor)
  Future<void> notifyResidentNewVisitor({
    required String visitorName,
    required String flatNumber,
    required String visitorId,
  }) async {
    await _notificationService.notifyResidentNewVisitor(
      visitorName: visitorName,
      flatNumber: flatNumber,
      visitorId: visitorId,
    );
  }

  /// Notify guard about visitor approval (called when resident approves)
  Future<void> notifyGuardVisitorApproved({
    required String guardId,
    required String visitorName,
    required String flatNumber,
    required String visitorId,
    required String approvedBy,
  }) async {
    await _notificationService.notifyGuardVisitorApproved(
      guardId: guardId,
      visitorName: visitorName,
      flatNumber: flatNumber,
      visitorId: visitorId,
      approvedBy: approvedBy,
    );
  }

  /// Notify guard about visitor denial (called when resident denies)
  Future<void> notifyGuardVisitorDenied({
    required String guardId,
    required String visitorName,
    required String flatNumber,
    required String visitorId,
    required String deniedBy,
  }) async {
    await _notificationService.notifyGuardVisitorDenied(
      guardId: guardId,
      visitorName: visitorName,
      flatNumber: flatNumber,
      visitorId: visitorId,
      deniedBy: deniedBy,
    );
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Clear state on logout
  Future<void> clearOnLogout() async {
    if (_currentUserId != null) {
      await _notificationService.removeTokenFromUser(_currentUserId!);
    }

    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _notificationTapSubscription?.cancel();

    _currentUserId = null;
    _notifications.clear();
    _unreadCount = 0;
    _status = NotificationStatus.initial;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _notificationTapSubscription?.cancel();
    super.dispose();
  }
}
