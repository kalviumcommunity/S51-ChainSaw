import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _visitorsRef =>
      _firestore.collection(AppConstants.visitorsCollection);

  CollectionReference<Map<String, dynamic>> get _flatsRef =>
      _firestore.collection(AppConstants.flatsCollection);

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  /// Get complete dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get all counts in parallel
      final results = await Future.wait([
        _getTotalUsers(),
        _getTotalFlats(),
        _getTodayVisitors(),
        _getPendingVisitors(),
        _getVisitorsInside(),
        _getUserCountByRole(),
        _getVisitorCountByStatus(),
      ]);

      return DashboardStats(
        totalUsers: results[0] as int,
        totalFlats: results[1] as int,
        todayVisitors: results[2] as int,
        pendingVisitors: results[3] as int,
        visitorsInside: results[4] as int,
        usersByRole: results[5] as Map<String, int>,
        visitorsByStatus: results[6] as Map<String, int>,
      );
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  Future<int> _getTotalUsers() async {
    final result = await _usersRef.count().get();
    return result.count ?? 0;
  }

  Future<int> _getTotalFlats() async {
    final result = await _flatsRef.count().get();
    return result.count ?? 0;
  }

  Future<int> _getTodayVisitors() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final result = await _visitorsRef
        .where(AppConstants.fieldEntryTime,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<int> _getPendingVisitors() async {
    final result = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusPending)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<int> _getVisitorsInside() async {
    final result = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusApproved)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<Map<String, int>> _getUserCountByRole() async {
    final guards = await _usersRef
        .where(AppConstants.fieldRole, isEqualTo: AppConstants.roleGuard)
        .count()
        .get();

    final residents = await _usersRef
        .where(AppConstants.fieldRole, isEqualTo: AppConstants.roleResident)
        .count()
        .get();

    final admins = await _usersRef
        .where(AppConstants.fieldRole, isEqualTo: AppConstants.roleAdmin)
        .count()
        .get();

    return {
      AppConstants.roleGuard: guards.count ?? 0,
      AppConstants.roleResident: residents.count ?? 0,
      AppConstants.roleAdmin: admins.count ?? 0,
    };
  }

  Future<Map<String, int>> _getVisitorCountByStatus() async {
    final pending = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusPending)
        .count()
        .get();

    final approved = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusApproved)
        .count()
        .get();

    final denied = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusDenied)
        .count()
        .get();

    final checkedOut = await _visitorsRef
        .where(AppConstants.fieldVisitorStatus,
            isEqualTo: AppConstants.statusCheckedOut)
        .count()
        .get();

    return {
      AppConstants.statusPending: pending.count ?? 0,
      AppConstants.statusApproved: approved.count ?? 0,
      AppConstants.statusDenied: denied.count ?? 0,
      AppConstants.statusCheckedOut: checkedOut.count ?? 0,
    };
  }

  // ============================================================
  // VISITOR TRENDS
  // ============================================================

  /// Get visitor count for last N days
  Future<List<DailyVisitorCount>> getVisitorTrend({int days = 7}) async {
    try {
      final now = DateTime.now();
      final List<DailyVisitorCount> trend = [];

      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final nextDate = date.add(const Duration(days: 1));

        final result = await _visitorsRef
            .where(AppConstants.fieldEntryTime,
                isGreaterThanOrEqualTo: Timestamp.fromDate(date))
            .where(AppConstants.fieldEntryTime,
                isLessThan: Timestamp.fromDate(nextDate))
            .count()
            .get();

        trend.add(DailyVisitorCount(
          date: date,
          count: result.count ?? 0,
        ));
      }

      return trend;
    } catch (e) {
      throw Exception('Failed to get visitor trend: $e');
    }
  }

  /// Get visitor count for this week
  Future<int> getThisWeekVisitors() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final result = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .count()
          .get();

      return result.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get this week visitors: $e');
    }
  }

  /// Get visitor count for this month
  Future<int> getThisMonthVisitors() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final result = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get();

      return result.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get this month visitors: $e');
    }
  }

  // ============================================================
  // FLAT ANALYTICS
  // ============================================================

  /// Get flat statistics
  Future<FlatStats> getFlatStats() async {
    try {
      final flatsSnapshot = await _flatsRef.get();

      int totalFlats = flatsSnapshot.docs.length;
      int occupiedFlats = 0;
      int totalResidents = 0;

      for (final doc in flatsSnapshot.docs) {
        final data = doc.data();
        final residentIds = List<String>.from(data[AppConstants.fieldResidentIds] ?? []);
        if (residentIds.isNotEmpty) {
          occupiedFlats++;
          totalResidents += residentIds.length;
        }
      }

      return FlatStats(
        totalFlats: totalFlats,
        occupiedFlats: occupiedFlats,
        vacantFlats: totalFlats - occupiedFlats,
        totalResidents: totalResidents,
        occupancyRate: totalFlats > 0 ? (occupiedFlats / totalFlats) * 100 : 0,
      );
    } catch (e) {
      throw Exception('Failed to get flat stats: $e');
    }
  }

  /// Get flats by block
  Future<Map<String, int>> getFlatCountByBlock() async {
    try {
      final flatsSnapshot = await _flatsRef.get();
      final Map<String, int> blockCounts = {};

      for (final doc in flatsSnapshot.docs) {
        final data = doc.data();
        final block = data[AppConstants.fieldBlock] as String? ?? 'Unknown';
        blockCounts[block] = (blockCounts[block] ?? 0) + 1;
      }

      return blockCounts;
    } catch (e) {
      throw Exception('Failed to get flat count by block: $e');
    }
  }

  // ============================================================
  // PEAK HOURS ANALYSIS
  // ============================================================

  /// Get visitor count by hour (for today)
  Future<Map<int, int>> getTodayVisitorsByHour() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where(AppConstants.fieldEntryTime,
              isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final Map<int, int> hourlyCount = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final entryTime = (data[AppConstants.fieldEntryTime] as Timestamp).toDate();
        final hour = entryTime.hour;
        hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
      }

      return hourlyCount;
    } catch (e) {
      throw Exception('Failed to get visitors by hour: $e');
    }
  }

  // ============================================================
  // COMPARISON STATS
  // ============================================================

  /// Get comparison with previous period
  Future<ComparisonStats> getComparisonStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = thisWeekStart;

      // Today's visitors
      final todayResult = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .count()
          .get();

      // Yesterday's visitors
      final yesterdayResult = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
          .where(AppConstants.fieldEntryTime,
              isLessThan: Timestamp.fromDate(today))
          .count()
          .get();

      // This week's visitors
      final thisWeekResult = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(thisWeekStart))
          .count()
          .get();

      // Last week's visitors
      final lastWeekResult = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeekStart))
          .where(AppConstants.fieldEntryTime,
              isLessThan: Timestamp.fromDate(lastWeekEnd))
          .count()
          .get();

      return ComparisonStats(
        todayVisitors: todayResult.count ?? 0,
        yesterdayVisitors: yesterdayResult.count ?? 0,
        thisWeekVisitors: thisWeekResult.count ?? 0,
        lastWeekVisitors: lastWeekResult.count ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get comparison stats: $e');
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class DashboardStats {
  final int totalUsers;
  final int totalFlats;
  final int todayVisitors;
  final int pendingVisitors;
  final int visitorsInside;
  final Map<String, int> usersByRole;
  final Map<String, int> visitorsByStatus;

  DashboardStats({
    required this.totalUsers,
    required this.totalFlats,
    required this.todayVisitors,
    required this.pendingVisitors,
    required this.visitorsInside,
    required this.usersByRole,
    required this.visitorsByStatus,
  });

  int get totalGuards => usersByRole[AppConstants.roleGuard] ?? 0;
  int get totalResidents => usersByRole[AppConstants.roleResident] ?? 0;
  int get totalAdmins => usersByRole[AppConstants.roleAdmin] ?? 0;
}

class DailyVisitorCount {
  final DateTime date;
  final int count;

  DailyVisitorCount({
    required this.date,
    required this.count,
  });
}

class FlatStats {
  final int totalFlats;
  final int occupiedFlats;
  final int vacantFlats;
  final int totalResidents;
  final double occupancyRate;

  FlatStats({
    required this.totalFlats,
    required this.occupiedFlats,
    required this.vacantFlats,
    required this.totalResidents,
    required this.occupancyRate,
  });
}

class ComparisonStats {
  final int todayVisitors;
  final int yesterdayVisitors;
  final int thisWeekVisitors;
  final int lastWeekVisitors;

  ComparisonStats({
    required this.todayVisitors,
    required this.yesterdayVisitors,
    required this.thisWeekVisitors,
    required this.lastWeekVisitors,
  });

  double get dailyChange {
    if (yesterdayVisitors == 0) return todayVisitors > 0 ? 100 : 0;
    return ((todayVisitors - yesterdayVisitors) / yesterdayVisitors) * 100;
  }

  double get weeklyChange {
    if (lastWeekVisitors == 0) return thisWeekVisitors > 0 ? 100 : 0;
    return ((thisWeekVisitors - lastWeekVisitors) / lastWeekVisitors) * 100;
  }
}
