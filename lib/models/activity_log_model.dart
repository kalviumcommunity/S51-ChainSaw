import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity types for user authentication actions
class LogAction {
  LogAction._();

  static const String otpRequested = 'otp_requested';
  static const String otpVerified = 'otp_verified';
  static const String otpFailed = 'otp_failed';
  static const String userRegistered = 'user_registered';
  static const String userLogin = 'user_login';
  static const String userLogout = 'user_logout';
  static const String roleSelected = 'role_selected';
}

class ActivityLogModel {
  final String id;
  final String action;
  final String? userId;
  final String? userPhone;
  final String? userRole;
  final String? userName;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.action,
    this.userId,
    this.userPhone,
    this.userRole,
    this.userName,
    this.details,
    required this.timestamp,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json, String id) {
    return ActivityLogModel(
      id: id,
      action: json['action'] ?? '',
      userId: json['userId'],
      userPhone: json['userPhone'],
      userRole: json['userRole'],
      userName: json['userName'],
      details: json['details'] as Map<String, dynamic>?,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'userPhone': userPhone,
      'userRole': userRole,
      'userName': userName,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create log for OTP requested
  factory ActivityLogModel.otpRequested({
    required String phoneNumber,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.otpRequested,
      userPhone: phoneNumber,
      details: {'phoneNumber': phoneNumber},
      timestamp: DateTime.now(),
    );
  }

  /// Create log for OTP verified successfully
  factory ActivityLogModel.otpVerified({
    required String userId,
    required String phoneNumber,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.otpVerified,
      userId: userId,
      userPhone: phoneNumber,
      details: {'phoneNumber': phoneNumber},
      timestamp: DateTime.now(),
    );
  }

  /// Create log for OTP verification failed
  factory ActivityLogModel.otpFailed({
    required String phoneNumber,
    String? reason,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.otpFailed,
      userPhone: phoneNumber,
      details: {
        'phoneNumber': phoneNumber,
        'reason': reason,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create log for new user registration
  factory ActivityLogModel.userRegistered({
    required String userId,
    required String phoneNumber,
    required String name,
    required String role,
    String? flatNumber,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.userRegistered,
      userId: userId,
      userPhone: phoneNumber,
      userName: name,
      userRole: role,
      details: {
        'name': name,
        'role': role,
        'flatNumber': flatNumber,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create log for user login
  factory ActivityLogModel.userLogin({
    required String userId,
    required String phoneNumber,
    required String name,
    required String role,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.userLogin,
      userId: userId,
      userPhone: phoneNumber,
      userName: name,
      userRole: role,
      details: {
        'name': name,
        'role': role,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create log for user logout
  factory ActivityLogModel.userLogout({
    required String userId,
    required String name,
    required String role,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.userLogout,
      userId: userId,
      userName: name,
      userRole: role,
      timestamp: DateTime.now(),
    );
  }

  /// Create log for role selection
  factory ActivityLogModel.roleSelected({
    required String userId,
    required String role,
    String? flatNumber,
  }) {
    return ActivityLogModel(
      id: '',
      action: LogAction.roleSelected,
      userId: userId,
      userRole: role,
      details: {
        'role': role,
        'flatNumber': flatNumber,
      },
      timestamp: DateTime.now(),
    );
  }
}
