import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types for the app
enum NotificationType {
  visitorArrived,    // Guard added a visitor for resident
  visitorApproved,   // Resident approved visitor (notify guard)
  visitorDenied,     // Resident denied visitor (notify guard)
  visitorCheckedOut, // Guard checked out visitor
  newResident,       // Admin added new resident
  flatAssigned,      // Resident assigned to flat
  systemAlert,       // General system notification
}

/// Extension to convert NotificationType to/from string
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.visitorArrived:
        return 'visitor_arrived';
      case NotificationType.visitorApproved:
        return 'visitor_approved';
      case NotificationType.visitorDenied:
        return 'visitor_denied';
      case NotificationType.visitorCheckedOut:
        return 'visitor_checked_out';
      case NotificationType.newResident:
        return 'new_resident';
      case NotificationType.flatAssigned:
        return 'flat_assigned';
      case NotificationType.systemAlert:
        return 'system_alert';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'visitor_arrived':
        return NotificationType.visitorArrived;
      case 'visitor_approved':
        return NotificationType.visitorApproved;
      case 'visitor_denied':
        return NotificationType.visitorDenied;
      case 'visitor_checked_out':
        return NotificationType.visitorCheckedOut;
      case 'new_resident':
        return NotificationType.newResident;
      case 'flat_assigned':
        return NotificationType.flatAssigned;
      case 'system_alert':
      default:
        return NotificationType.systemAlert;
    }
  }

  /// Get display title for notification type
  String get displayTitle {
    switch (this) {
      case NotificationType.visitorArrived:
        return 'New Visitor';
      case NotificationType.visitorApproved:
        return 'Visitor Approved';
      case NotificationType.visitorDenied:
        return 'Visitor Denied';
      case NotificationType.visitorCheckedOut:
        return 'Visitor Left';
      case NotificationType.newResident:
        return 'Welcome!';
      case NotificationType.flatAssigned:
        return 'Flat Assigned';
      case NotificationType.systemAlert:
        return 'Notice';
    }
  }
}

/// Model for in-app notifications stored in Firestore
class NotificationModel {
  final String id;
  final String userId;          // Target user ID
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;  // Additional payload (visitorId, flatNumber, etc.)
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      type: NotificationTypeExtension.fromString(map['type'] ?? 'system_alert'),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: ${type.value}, title: $title, isRead: $isRead)';
  }
}

/// Model for push notification payload
class PushNotificationPayload {
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  PushNotificationPayload({
    required this.title,
    required this.body,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data ?? {},
    };
  }
}
