import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String role; // 'guard', 'resident', 'admin'
  final String? flatNumber; // Only for residents
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    required this.role,
    this.flatNumber,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      flatNumber: json['flatNumber'],
      fcmToken: json['fcmToken'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'name': name,
      'role': role,
      'flatNumber': flatNumber,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? phone,
    String? name,
    String? role,
    String? flatNumber,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      flatNumber: flatNumber ?? this.flatNumber,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Role helpers
  bool get isGuard => role == 'guard';
  bool get isResident => role == 'resident';
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, role: $role, flatNumber: $flatNumber)';
  }
}
