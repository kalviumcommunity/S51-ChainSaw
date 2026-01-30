import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling background message: ${message.messageId}');
}

/// Service for handling push notifications and in-app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(AppConstants.notificationsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'gatekeeper_notifications',
    'GateKeeper Notifications',
    description: 'Notifications for visitor management',
    importance: Importance.high,
    playSound: true,
  );

  // Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Set up message handlers
    _setupMessageHandlers();

    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('Notification permission: ${settings.authorizationStatus}');
    return isAuthorized;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _notificationTapController.add(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a terminated state
    _checkInitialMessage();
  }

  /// Handle foreground messages - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'GateKeeper',
        body: notification.body ?? '',
        payload: message.data,
      );
    }
  }

  /// Handle notification open
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    _notificationTapController.add(message.data);
  }

  /// Check for initial message (app opened from terminated state)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.messageId}');
      _notificationTapController.add(initialMessage.data);
    }
  }

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  // ============================================================
  // FCM TOKEN MANAGEMENT
  // ============================================================

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user document
  Future<void> saveTokenToUser(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _usersRef.doc(userId).update({
          AppConstants.fieldFcmToken: token,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token from user document (on logout)
  Future<void> removeTokenFromUser(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        AppConstants.fieldFcmToken: FieldValue.delete(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token removed for user: $userId');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Listen for token refresh
  void onTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await _usersRef.doc(userId).update({
        AppConstants.fieldFcmToken: newToken,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // IN-APP NOTIFICATIONS (FIRESTORE)
  // ============================================================

  /// Create a notification in Firestore
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _notificationsRef.add(notification.toMap());
      debugPrint('Notification created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Get notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Stream notifications for a user
  Stream<List<NotificationModel>> streamUserNotifications(String userId,
      {int limit = 50}) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream unread notification count
  Stream<int> streamUnreadCount(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('Marked ${snapshot.docs.length} notifications as read');
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // ============================================================
  // SEND NOTIFICATIONS
  // ============================================================

  /// Notify resident about new visitor
  Future<void> notifyResidentNewVisitor({
    required String visitorName,
    required String flatNumber,
    required String visitorId,
  }) async {
    try {
      // Get residents of this flat
      final flatsSnapshot = await _firestore
          .collection(AppConstants.flatsCollection)
          .where('flatNumber', isEqualTo: flatNumber)
          .limit(1)
          .get();

      if (flatsSnapshot.docs.isEmpty) return;

      final flatData = flatsSnapshot.docs.first.data();
      final residentIds = List<String>.from(flatData['residentIds'] ?? []);

      // Create notification for each resident
      for (final residentId in residentIds) {
        final notification = NotificationModel(
          id: '',
          userId: residentId,
          type: NotificationType.visitorArrived,
          title: 'New Visitor',
          body: '$visitorName is waiting at the gate for Flat $flatNumber',
          data: {
            'visitorId': visitorId,
            'visitorName': visitorName,
            'flatNumber': flatNumber,
            'action': 'approve_visitor',
          },
          createdAt: DateTime.now(),
        );

        await createNotification(notification);
      }

      debugPrint('Notified residents of flat $flatNumber about visitor');
    } catch (e) {
      debugPrint('Error notifying resident: $e');
    }
  }

  /// Notify guard about visitor approval
  Future<void> notifyGuardVisitorApproved({
    required String guardId,
    required String visitorName,
    required String flatNumber,
    required String visitorId,
    required String approvedBy,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: guardId,
        type: NotificationType.visitorApproved,
        title: 'Visitor Approved',
        body: '$visitorName approved by Flat $flatNumber resident',
        data: {
          'visitorId': visitorId,
          'visitorName': visitorName,
          'flatNumber': flatNumber,
          'approvedBy': approvedBy,
          'action': 'allow_entry',
        },
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
      debugPrint('Notified guard about visitor approval');
    } catch (e) {
      debugPrint('Error notifying guard: $e');
    }
  }

  /// Notify guard about visitor denial
  Future<void> notifyGuardVisitorDenied({
    required String guardId,
    required String visitorName,
    required String flatNumber,
    required String visitorId,
    required String deniedBy,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: guardId,
        type: NotificationType.visitorDenied,
        title: 'Visitor Denied',
        body: '$visitorName denied by Flat $flatNumber resident',
        data: {
          'visitorId': visitorId,
          'visitorName': visitorName,
          'flatNumber': flatNumber,
          'deniedBy': deniedBy,
          'action': 'deny_entry',
        },
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
      debugPrint('Notified guard about visitor denial');
    } catch (e) {
      debugPrint('Error notifying guard: $e');
    }
  }

  /// Send notification to all users with a specific role
  Future<void> notifyByRole({
    required String role,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final usersSnapshot = await _usersRef
          .where('role', isEqualTo: role)
          .get();

      final batch = _firestore.batch();

      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _notificationsRef.doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'type': type.value,
          'title': title,
          'body': body,
          'data': data,
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
      }

      await batch.commit();
      debugPrint('Sent notification to ${usersSnapshot.docs.length} $role users');
    } catch (e) {
      debugPrint('Error notifying by role: $e');
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void dispose() {
    _notificationTapController.close();
  }
}
