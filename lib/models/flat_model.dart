import 'package:cloud_firestore/cloud_firestore.dart';

class FlatModel {
  final String id;
  final String flatNumber;
  final String block;
  final List<String> residentIds;
  final String? ownerName;
  final String? ownerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlatModel({
    required this.id,
    required this.flatNumber,
    required this.block,
    required this.residentIds,
    this.ownerName,
    this.ownerPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlatModel.fromJson(Map<String, dynamic> json, String id) {
    return FlatModel(
      id: id,
      flatNumber: json['flatNumber'] ?? '',
      block: json['block'] ?? '',
      residentIds: List<String>.from(json['residentIds'] ?? []),
      ownerName: json['ownerName'],
      ownerPhone: json['ownerPhone'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Alias for fromJson (used by services)
  factory FlatModel.fromMap(Map<String, dynamic> map, String id) {
    return FlatModel.fromJson(map, id);
  }

  Map<String, dynamic> toJson() {
    return {
      'flatNumber': flatNumber,
      'block': block,
      'residentIds': residentIds,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Alias for toJson (used by services)
  Map<String, dynamic> toMap() => toJson();

  FlatModel copyWith({
    String? id,
    String? flatNumber,
    String? block,
    List<String>? residentIds,
    String? ownerName,
    String? ownerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlatModel(
      id: id ?? this.id,
      flatNumber: flatNumber ?? this.flatNumber,
      block: block ?? this.block,
      residentIds: residentIds ?? this.residentIds,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get full flat display name
  String get displayName => '$block-$flatNumber';

  // Check if a user is resident of this flat
  bool hasResident(String userId) => residentIds.contains(userId);

  // Number of residents
  int get residentCount => residentIds.length;

  @override
  String toString() {
    return 'FlatModel(id: $id, flatNumber: $flatNumber, block: $block, residents: $residentCount)';
  }
}
