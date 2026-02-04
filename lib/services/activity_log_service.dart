import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Types of admin activities that can be logged
enum ActivityType {
  userCreated,
  userUpdated,
  userDeleted,
  roleChanged,
  flatCreated,
  flatUpdated,
  flatDeleted,
  residentAssigned,
  residentRemoved,
  visitorApproved,
  visitorDenied,
  visitorCheckedOut,
  settingsUpdated,
}

/// Model class for activity log entries
class ActivityLog {
  final String id;
  final ActivityType type;
  final String adminId;
  final String adminName;
  final String targetId;
  final String targetName;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.type,
    required this.adminId,
    required this.adminName,
    required this.targetId,
    required this.targetName,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.userUpdated,
      ),
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? 'Unknown Admin',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      description: map['description'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'adminId': adminId,
      'adminName': adminName,
      'targetId': targetId,
      'targetName': targetName,
      'description': description,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get display title for the activity type
  String get displayTitle {
    switch (type) {
      case ActivityType.userCreated:
        return 'User Created';
      case ActivityType.userUpdated:
        return 'User Updated';
      case ActivityType.userDeleted:
        return 'User Deleted';
      case ActivityType.roleChanged:
        return 'Role Changed';
      case ActivityType.flatCreated:
        return 'Flat Created';
      case ActivityType.flatUpdated:
        return 'Flat Updated';
      case ActivityType.flatDeleted:
        return 'Flat Deleted';
      case ActivityType.residentAssigned:
        return 'Resident Assigned';
      case ActivityType.residentRemoved:
        return 'Resident Removed';
      case ActivityType.visitorApproved:
        return 'Visitor Approved';
      case ActivityType.visitorDenied:
        return 'Visitor Denied';
      case ActivityType.visitorCheckedOut:
        return 'Visitor Checked Out';
      case ActivityType.settingsUpdated:
        return 'Settings Updated';
    }
  }

  /// Get icon name for the activity type
  String get iconName {
    switch (type) {
      case ActivityType.userCreated:
        return 'person_add';
      case ActivityType.userUpdated:
        return 'edit';
      case ActivityType.userDeleted:
        return 'person_remove';
      case ActivityType.roleChanged:
        return 'swap_horiz';
      case ActivityType.flatCreated:
        return 'add_home';
      case ActivityType.flatUpdated:
        return 'home';
      case ActivityType.flatDeleted:
        return 'home_work';
      case ActivityType.residentAssigned:
        return 'person_add_alt';
      case ActivityType.residentRemoved:
        return 'person_off';
      case ActivityType.visitorApproved:
        return 'check_circle';
      case ActivityType.visitorDenied:
        return 'cancel';
      case ActivityType.visitorCheckedOut:
        return 'exit_to_app';
      case ActivityType.settingsUpdated:
        return 'settings';
    }
  }

  /// Get category for grouping activities
  String get category {
    switch (type) {
      case ActivityType.userCreated:
      case ActivityType.userUpdated:
      case ActivityType.userDeleted:
      case ActivityType.roleChanged:
        return 'Users';
      case ActivityType.flatCreated:
      case ActivityType.flatUpdated:
      case ActivityType.flatDeleted:
      case ActivityType.residentAssigned:
      case ActivityType.residentRemoved:
        return 'Flats';
      case ActivityType.visitorApproved:
      case ActivityType.visitorDenied:
      case ActivityType.visitorCheckedOut:
        return 'Visitors';
      case ActivityType.settingsUpdated:
        return 'Settings';
    }
  }
}

class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _logsRef =>
      _firestore.collection(AppConstants.activityLogsCollection);

  // ============================================================
  // CREATE
  // ============================================================

  /// Log an activity
  Future<String> logActivity({
    required ActivityType type,
    required String adminId,
    required String adminName,
    required String targetId,
    required String targetName,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = ActivityLog(
        id: '',
        type: type,
        adminId: adminId,
        adminName: adminName,
        targetId: targetId,
        targetName: targetName,
        description: description,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      final docRef = await _logsRef.add(log.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to log activity: $e');
    }
  }

  /// Quick log methods for common actions

  Future<void> logUserCreated({
    required String adminId,
    required String adminName,
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    await logActivity(
      type: ActivityType.userCreated,
      adminId: adminId,
      adminName: adminName,
      targetId: userId,
      targetName: userName,
      description: 'Created new $userRole: $userName',
      metadata: {'role': userRole},
    );
  }

  Future<void> logUserUpdated({
    required String adminId,
    required String adminName,
    required String userId,
    required String userName,
    List<String>? changedFields,
  }) async {
    await logActivity(
      type: ActivityType.userUpdated,
      adminId: adminId,
      adminName: adminName,
      targetId: userId,
      targetName: userName,
      description: 'Updated user: $userName',
      metadata: {'changedFields': changedFields},
    );
  }

  Future<void> logUserDeleted({
    required String adminId,
    required String adminName,
    required String userId,
    required String userName,
  }) async {
    await logActivity(
      type: ActivityType.userDeleted,
      adminId: adminId,
      adminName: adminName,
      targetId: userId,
      targetName: userName,
      description: 'Deleted user: $userName',
    );
  }

  Future<void> logRoleChanged({
    required String adminId,
    required String adminName,
    required String userId,
    required String userName,
    required String oldRole,
    required String newRole,
  }) async {
    await logActivity(
      type: ActivityType.roleChanged,
      adminId: adminId,
      adminName: adminName,
      targetId: userId,
      targetName: userName,
      description: 'Changed role of $userName from $oldRole to $newRole',
      metadata: {'oldRole': oldRole, 'newRole': newRole},
    );
  }

  Future<void> logFlatCreated({
    required String adminId,
    required String adminName,
    required String flatId,
    required String flatNumber,
    String? block,
  }) async {
    await logActivity(
      type: ActivityType.flatCreated,
      adminId: adminId,
      adminName: adminName,
      targetId: flatId,
      targetName: flatNumber,
      description: 'Created flat: $flatNumber',
      metadata: {'block': block},
    );
  }

  Future<void> logFlatUpdated({
    required String adminId,
    required String adminName,
    required String flatId,
    required String flatNumber,
    List<String>? changedFields,
  }) async {
    await logActivity(
      type: ActivityType.flatUpdated,
      adminId: adminId,
      adminName: adminName,
      targetId: flatId,
      targetName: flatNumber,
      description: 'Updated flat: $flatNumber',
      metadata: {'changedFields': changedFields},
    );
  }

  Future<void> logFlatDeleted({
    required String adminId,
    required String adminName,
    required String flatId,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.flatDeleted,
      adminId: adminId,
      adminName: adminName,
      targetId: flatId,
      targetName: flatNumber,
      description: 'Deleted flat: $flatNumber',
    );
  }

  Future<void> logResidentAssigned({
    required String adminId,
    required String adminName,
    required String residentId,
    required String residentName,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.residentAssigned,
      adminId: adminId,
      adminName: adminName,
      targetId: residentId,
      targetName: residentName,
      description: 'Assigned $residentName to flat $flatNumber',
      metadata: {'flatNumber': flatNumber},
    );
  }

  Future<void> logResidentRemoved({
    required String adminId,
    required String adminName,
    required String residentId,
    required String residentName,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.residentRemoved,
      adminId: adminId,
      adminName: adminName,
      targetId: residentId,
      targetName: residentName,
      description: 'Removed $residentName from flat $flatNumber',
      metadata: {'flatNumber': flatNumber},
    );
  }

  Future<void> logVisitorApproved({
    required String residentId,
    required String residentName,
    required String visitorId,
    required String visitorName,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.visitorApproved,
      adminId: residentId,
      adminName: residentName,
      targetId: visitorId,
      targetName: visitorName,
      description: '$residentName approved visitor $visitorName for flat $flatNumber',
      metadata: {'flatNumber': flatNumber},
    );
  }

  Future<void> logVisitorDenied({
    required String residentId,
    required String residentName,
    required String visitorId,
    required String visitorName,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.visitorDenied,
      adminId: residentId,
      adminName: residentName,
      targetId: visitorId,
      targetName: visitorName,
      description: '$residentName denied visitor $visitorName for flat $flatNumber',
      metadata: {'flatNumber': flatNumber},
    );
  }

  Future<void> logVisitorCheckedOut({
    required String guardId,
    required String guardName,
    required String visitorId,
    required String visitorName,
    required String flatNumber,
  }) async {
    await logActivity(
      type: ActivityType.visitorCheckedOut,
      adminId: guardId,
      adminName: guardName,
      targetId: visitorId,
      targetName: visitorName,
      description: '$guardName checked out visitor $visitorName from flat $flatNumber',
      metadata: {'flatNumber': flatNumber},
    );
  }

  // ============================================================
  // READ
  // ============================================================

  /// Get all activity logs (with optional limit)
  Future<List<ActivityLog>> getActivityLogs({int limit = 50}) async {
    try {
      final snapshot = await _logsRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  /// Get activity logs by admin
  Future<List<ActivityLog>> getActivityLogsByAdmin(
    String adminId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _logsRef
          .where('adminId', isEqualTo: adminId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs by admin: $e');
    }
  }

  /// Get activity logs by type
  Future<List<ActivityLog>> getActivityLogsByType(
    ActivityType type, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _logsRef
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs by type: $e');
    }
  }

  /// Get activity logs for a specific target (user, flat, etc.)
  Future<List<ActivityLog>> getActivityLogsForTarget(
    String targetId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _logsRef
          .where('targetId', isEqualTo: targetId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs for target: $e');
    }
  }

  /// Get activity logs for a date range
  Future<List<ActivityLog>> getActivityLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _logsRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs by date range: $e');
    }
  }

  /// Get today's activity logs
  Future<List<ActivityLog>> getTodaysActivityLogs({int limit = 50}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getActivityLogsByDateRange(startOfDay, endOfDay, limit: limit);
  }

  // ============================================================
  // REAL-TIME STREAMS
  // ============================================================

  /// Stream all activity logs
  Stream<List<ActivityLog>> streamActivityLogs({int limit = 50}) {
    return _logsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream activity logs by type
  Stream<List<ActivityLog>> streamActivityLogsByType(
    ActivityType type, {
    int limit = 50,
  }) {
    return _logsRef
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream today's activity logs
  Stream<List<ActivityLog>> streamTodaysActivityLogs({int limit = 50}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _logsRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  /// Get activity count by type for a date range
  Future<Map<ActivityType, int>> getActivityCountByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _logsRef;

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      final counts = <ActivityType, int>{};
      for (final type in ActivityType.values) {
        counts[type] = 0;
      }

      for (final doc in snapshot.docs) {
        final typeName = doc.data()['type'] as String?;
        if (typeName != null) {
          try {
            final type = ActivityType.values.firstWhere((e) => e.name == typeName);
            counts[type] = (counts[type] ?? 0) + 1;
          } catch (_) {
            // Unknown type, skip
          }
        }
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get activity count by type: $e');
    }
  }

  /// Get total activity count for today
  Future<int> getTodaysActivityCount() async {
    try {
      final logs = await getTodaysActivityLogs(limit: 1000);
      return logs.length;
    } catch (e) {
      throw Exception('Failed to get today\'s activity count: $e');
    }
  }

  /// Get most active admins
  Future<List<Map<String, dynamic>>> getMostActiveAdmins({
    int limit = 5,
    DateTime? since,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _logsRef;

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();

      final adminCounts = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final adminId = doc.data()['adminId'] as String?;
        final adminName = doc.data()['adminName'] as String?;

        if (adminId != null && adminId.isNotEmpty) {
          if (!adminCounts.containsKey(adminId)) {
            adminCounts[adminId] = {
              'adminId': adminId,
              'adminName': adminName ?? 'Unknown',
              'count': 0,
            };
          }
          adminCounts[adminId]!['count'] = (adminCounts[adminId]!['count'] as int) + 1;
        }
      }

      final sortedAdmins = adminCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedAdmins.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get most active admins: $e');
    }
  }

  // ============================================================
  // DELETE (for cleanup)
  // ============================================================

  /// Delete old activity logs (older than specified days)
  Future<int> deleteOldLogs(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _logsRef
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to delete old logs: $e');
    }
  }
}
