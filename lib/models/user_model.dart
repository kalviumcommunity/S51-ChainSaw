import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String role; // 'guard', 'resident', 'admin'
  final String? phone; // Can be null if registered via email/google
  final String? email; // Can be null if registered via phone
  final String? photoUrl; // Google profile picture
  final String? flatNumber; // Only for residents
  final List<String> authMethods; // ['phone', 'password', 'google.com']
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.photoUrl,
    this.flatNumber,
    required this.authMethods,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      flatNumber: json['flatNumber'],
      authMethods: List<String>.from(json['authMethods'] ?? []),
      fcmToken: json['fcmToken'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'flatNumber': flatNumber,
      'authMethods': authMethods,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? role,
    String? phone,
    String? email,
    String? photoUrl,
    String? flatNumber,
    List<String>? authMethods,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      flatNumber: flatNumber ?? this.flatNumber,
      authMethods: authMethods ?? this.authMethods,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Role helpers
  bool get isGuard => role == 'guard';
  bool get isResident => role == 'resident';
  bool get isAdmin => role == 'admin';

  // Auth method helpers
  bool get hasPhoneAuth => authMethods.contains('phone');
  bool get hasEmailAuth => authMethods.contains('password');
  bool get hasGoogleAuth => authMethods.contains('google.com');

  // Display helpers
  String get displayIdentifier => email ?? phone ?? 'Unknown';

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, role: $role, email: $email, phone: $phone)';
  }
}