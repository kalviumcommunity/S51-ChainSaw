import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorModel {
  final String id;
  final String name;
  final String phone;
  final String flatNumber;
  final String status; // 'pending', 'approved', 'denied', 'checked_out'
  final DateTime entryTime;
  final DateTime? exitTime;
  final String guardId; // Guard who registered the visitor
  final String? guardName;
  final String? approvedBy; // Resident who approved
  final String? approvedByName;
  final String? deniedBy; // Resident who denied
  final String? deniedByName;
  final String? purpose; // Purpose of visit (optional)

  VisitorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatNumber,
    required this.status,
    required this.entryTime,
    this.exitTime,
    required this.guardId,
    this.guardName,
    this.approvedBy,
    this.approvedByName,
    this.deniedBy,
    this.deniedByName,
    this.purpose,
  });

  factory VisitorModel.fromJson(Map<String, dynamic> json, String id) {
    return VisitorModel(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      flatNumber: json['flatNumber'] ?? '',
      status: json['status'] ?? 'pending',
      entryTime: (json['entryTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exitTime: (json['exitTime'] as Timestamp?)?.toDate(),
      guardId: json['guardId'] ?? '',
      guardName: json['guardName'],
      approvedBy: json['approvedBy'],
      approvedByName: json['approvedByName'],
      deniedBy: json['deniedBy'],
      deniedByName: json['deniedByName'],
      purpose: json['purpose'],
    );
  }

  // Alias for fromJson (used by services)
  factory VisitorModel.fromMap(Map<String, dynamic> map, String id) {
    return VisitorModel.fromJson(map, id);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'flatNumber': flatNumber,
      'status': status,
      'entryTime': Timestamp.fromDate(entryTime),
      'exitTime': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
      'guardId': guardId,
      'guardName': guardName,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'deniedBy': deniedBy,
      'deniedByName': deniedByName,
      'purpose': purpose,
    };
  }

  // Alias for toJson (used by services)
  Map<String, dynamic> toMap() => toJson();

  VisitorModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? flatNumber,
    String? status,
    DateTime? entryTime,
    DateTime? exitTime,
    String? guardId,
    String? guardName,
    String? approvedBy,
    String? approvedByName,
    String? deniedBy,
    String? deniedByName,
    String? purpose,
  }) {
    return VisitorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      flatNumber: flatNumber ?? this.flatNumber,
      status: status ?? this.status,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      deniedBy: deniedBy ?? this.deniedBy,
      deniedByName: deniedByName ?? this.deniedByName,
      purpose: purpose ?? this.purpose,
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
  bool get isCheckedOut => status == 'checked_out';
  bool get isInside => status == 'approved' && exitTime == null;

  // Duration helpers
  Duration? get visitDuration {
    if (exitTime != null) {
      return exitTime!.difference(entryTime);
    }
    return null;
  }

  @override
  String toString() {
    return 'VisitorModel(id: $id, name: $name, flatNumber: $flatNumber, status: $status)';
  }
}
