import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/flat_model.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../services/flat_service.dart';
import '../services/activity_log_service.dart';

enum AdminStatus { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final FlatService _flatService = FlatService();
  final ActivityLogService _activityLogService = ActivityLogService();

  // State
  AdminStatus _status = AdminStatus.initial;
  String? _errorMessage;

  // Dashboard data
  DashboardStats? _dashboardStats;
  ComparisonStats? _comparisonStats;
  FlatStats? _flatStats;
  List<DailyVisitorCount> _visitorTrend = [];

  // User management data
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  String _searchQuery = '';
  String _roleFilter = 'All';

  // Flat management data
  List<FlatModel> _allFlats = [];
  List<FlatModel> _filteredFlats = [];
  String _flatSearchQuery = '';
  String _blockFilter = 'All';
  String _statusFilter = 'All'; // All, Occupied, Vacant

  // Activity log data
  List<ActivityLog> _activityLogs = [];
  List<ActivityLog> _filteredLogs = [];
  String _logCategoryFilter = 'All';
  String _logDateFilter = 'Today';

  // Stream subscriptions
  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<FlatModel>>? _flatsSubscription;
  StreamSubscription<List<ActivityLog>>? _logsSubscription;

  // Getters
  AdminStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdminStatus.loading;

  DashboardStats? get dashboardStats => _dashboardStats;
  ComparisonStats? get comparisonStats => _comparisonStats;
  FlatStats? get flatStats => _flatStats;
  List<DailyVisitorCount> get visitorTrend => _visitorTrend;

  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get filteredUsers => _filteredUsers;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;

  // Flat getters
  List<FlatModel> get allFlats => _allFlats;
  List<FlatModel> get filteredFlats => _filteredFlats;
  String get flatSearchQuery => _flatSearchQuery;
  String get blockFilter => _blockFilter;
  String get statusFilter => _statusFilter;

  // Activity log getters
  List<ActivityLog> get activityLogs => _activityLogs;
  List<ActivityLog> get filteredLogs => _filteredLogs;
  String get logCategoryFilter => _logCategoryFilter;
  String get logDateFilter => _logDateFilter;

  // Computed getters for dashboard
  int get totalUsers => _dashboardStats?.totalUsers ?? 0;
  int get totalFlats => _dashboardStats?.totalFlats ?? 0;
  int get todayVisitors => _dashboardStats?.todayVisitors ?? 0;
  int get pendingVisitors => _dashboardStats?.pendingVisitors ?? 0;
  int get visitorsInside => _dashboardStats?.visitorsInside ?? 0;
  int get totalGuards => _dashboardStats?.totalGuards ?? 0;
  int get totalResidents => _dashboardStats?.totalResidents ?? 0;
  int get totalAdmins => _dashboardStats?.totalAdmins ?? 0;

  // Flat computed getters
  int get occupiedFlatsCount => _allFlats.where((f) => f.residentIds.isNotEmpty).length;
  int get vacantFlatsCount => _allFlats.where((f) => f.residentIds.isEmpty).length;
  List<String> get availableBlocks {
    final blocks = _allFlats.map((f) => f.block).toSet().toList();
    blocks.sort();
    return ['All', ...blocks];
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize admin dashboard data
  Future<void> initialize() async {
    _status = AdminStatus.loading;
    notifyListeners();

    try {
      // Load all dashboard data in parallel
      await Future.wait([
        loadDashboardStats(),
        loadComparisonStats(),
        loadFlatStats(),
        loadVisitorTrend(),
        loadAllUsers(),
        loadAllFlats(),
        loadActivityLogs(),
      ]);

      _status = AdminStatus.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AdminStatus.error;
      notifyListeners();
    }
  }

  /// Initialize with real-time streams
  void initializeWithStream() {
    _status = AdminStatus.loading;
    notifyListeners();

    // Stream all users
    _usersSubscription?.cancel();
    _usersSubscription = _adminService.streamAllUsers().listen(
      (users) {
        _allUsers = users;
        _applyUserFilters();
        _status = AdminStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _status = AdminStatus.error;
        notifyListeners();
      },
    );

    // Stream all flats
    _flatsSubscription?.cancel();
    _flatsSubscription = _flatService.streamAllFlats().listen(
      (flats) {
        _allFlats = flats;
        _applyFlatFilters();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Failed to stream flats: $error');
      },
    );

    // Stream activity logs
    _logsSubscription?.cancel();
    _logsSubscription = _activityLogService.streamActivityLogs(limit: 100).listen(
      (logs) {
        _activityLogs = logs;
        _applyLogFilters();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Failed to stream activity logs: $error');
      },
    );

    // Load other dashboard data
    loadDashboardStats();
    loadComparisonStats();
    loadFlatStats();
    loadVisitorTrend();
  }

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _analyticsService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load dashboard stats: $e');
    }
  }

  /// Load comparison stats (today vs yesterday, this week vs last week)
  Future<void> loadComparisonStats() async {
    try {
      _comparisonStats = await _analyticsService.getComparisonStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load comparison stats: $e');
    }
  }

  /// Load flat statistics
  Future<void> loadFlatStats() async {
    try {
      _flatStats = await _analyticsService.getFlatStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load flat stats: $e');
    }
  }

  /// Load visitor trend for last 7 days
  Future<void> loadVisitorTrend({int days = 7}) async {
    try {
      _visitorTrend = await _analyticsService.getVisitorTrend(days: days);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load visitor trend: $e');
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await Future.wait([
      loadDashboardStats(),
      loadComparisonStats(),
      loadFlatStats(),
      loadVisitorTrend(),
    ]);
  }

  // ============================================================
  // USER MANAGEMENT
  // ============================================================

  /// Load all users
  Future<void> loadAllUsers() async {
    try {
      _allUsers = await _adminService.getAllUsers();
      _applyUserFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load all users: $e');
      _errorMessage = e.toString();
    }
  }

  /// Search users
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyUserFilters();
    notifyListeners();
  }

  /// Filter by role
  void setRoleFilter(String role) {
    _roleFilter = role;
    _applyUserFilters();
    notifyListeners();
  }

  /// Apply search and role filters
  void _applyUserFilters() {
    var users = _allUsers;

    // Apply role filter
    if (_roleFilter != 'All') {
      users = users.where((user) => user.role == _roleFilter.toLowerCase()).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      users = users.where((user) =>
          user.name.toLowerCase().contains(queryLower) ||
          (user.phone?.contains(_searchQuery) ?? false) ||
          (user.email?.toLowerCase().contains(queryLower) ?? false)).toList();
    }

    _filteredUsers = users;
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      return await _adminService.getUsersByRole(role);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _adminService.updateUserRole(userId, newRole);
      await loadAllUsers();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update user details
  Future<bool> updateUserDetails({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? flatNumber,
    String? role,
  }) async {
    try {
      await _adminService.updateUserDetails(
        userId: userId,
        name: name,
        phone: phone,
        email: email,
        flatNumber: flatNumber,
        role: role,
      );
      await loadAllUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      await loadAllUsers();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Assign user to flat
  Future<bool> assignUserToFlat(String userId, String flatNumber) async {
    try {
      await _adminService.assignUserToFlat(userId, flatNumber);
      await loadAllUsers();
      await loadFlatStats();
      await loadAllFlats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove user from flat
  Future<bool> removeUserFromFlat(String userId, String flatNumber) async {
    try {
      await _adminService.removeUserFromFlat(userId, flatNumber);
      await loadAllUsers();
      await loadFlatStats();
      await loadAllFlats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get recent users
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      return await _adminService.getRecentUsers(limit: limit);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // ============================================================
  // FLAT MANAGEMENT
  // ============================================================

  /// Load all flats
  Future<void> loadAllFlats() async {
    try {
      _allFlats = await _flatService.getAllFlats();
      _applyFlatFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load all flats: $e');
      _errorMessage = e.toString();
    }
  }

  /// Set flat search query
  void setFlatSearchQuery(String query) {
    _flatSearchQuery = query;
    _applyFlatFilters();
    notifyListeners();
  }

  /// Set block filter
  void setBlockFilter(String block) {
    _blockFilter = block;
    _applyFlatFilters();
    notifyListeners();
  }

  /// Set status filter (All, Occupied, Vacant)
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFlatFilters();
    notifyListeners();
  }

  /// Apply flat filters
  void _applyFlatFilters() {
    var flats = _allFlats;

    // Apply block filter
    if (_blockFilter != 'All') {
      flats = flats.where((flat) => flat.block == _blockFilter).toList();
    }

    // Apply status filter
    if (_statusFilter == 'Occupied') {
      flats = flats.where((flat) => flat.residentIds.isNotEmpty).toList();
    } else if (_statusFilter == 'Vacant') {
      flats = flats.where((flat) => flat.residentIds.isEmpty).toList();
    }

    // Apply search filter
    if (_flatSearchQuery.isNotEmpty) {
      final query = _flatSearchQuery.toLowerCase();
      flats = flats.where((flat) =>
          flat.flatNumber.toLowerCase().contains(query) ||
          flat.block.toLowerCase().contains(query) ||
          (flat.ownerName?.toLowerCase().contains(query) ?? false)).toList();
    }

    _filteredFlats = flats;
  }

  /// Create a new flat
  Future<bool> createFlat({
    required String flatNumber,
    required String block,
    String? ownerName,
    String? ownerPhone,
  }) async {
    try {
      final flat = FlatModel(
        id: '',
        flatNumber: flatNumber,
        block: block,
        residentIds: [],
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _flatService.createFlat(flat);
      await loadAllFlats();
      await loadDashboardStats();
      await loadFlatStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update flat details
  Future<bool> updateFlat({
    required String flatId,
    String? flatNumber,
    String? block,
    String? ownerName,
    String? ownerPhone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (flatNumber != null) updates['flatNumber'] = flatNumber;
      if (block != null) updates['block'] = block;
      if (ownerName != null) updates['ownerName'] = ownerName;
      if (ownerPhone != null) updates['ownerPhone'] = ownerPhone;

      await _flatService.updateFlat(flatId, updates);
      await loadAllFlats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete flat
  Future<bool> deleteFlat(String flatId) async {
    try {
      await _flatService.deleteFlat(flatId);
      await loadAllFlats();
      await loadDashboardStats();
      await loadFlatStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add resident to flat
  Future<bool> addResidentToFlat(String flatId, String residentId) async {
    try {
      await _flatService.addResidentToFlat(flatId, residentId);
      await loadAllFlats();
      await loadFlatStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove resident from flat
  Future<bool> removeResidentFromFlat(String flatId, String residentId) async {
    try {
      await _flatService.removeResidentFromFlat(flatId, residentId);
      await loadAllFlats();
      await loadFlatStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get flat by ID
  FlatModel? getFlatById(String id) {
    try {
      return _allFlats.firstWhere((flat) => flat.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ACTIVITY LOGS
  // ============================================================

  /// Load activity logs
  Future<void> loadActivityLogs({int limit = 100}) async {
    try {
      _activityLogs = await _activityLogService.getActivityLogs(limit: limit);
      _applyLogFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load activity logs: $e');
      _errorMessage = e.toString();
    }
  }

  /// Set log category filter
  void setLogCategoryFilter(String category) {
    _logCategoryFilter = category;
    _applyLogFilters();
    notifyListeners();
  }

  /// Set log date filter
  void setLogDateFilter(String dateFilter) {
    _logDateFilter = dateFilter;
    _applyLogFilters();
    notifyListeners();
  }

  /// Apply log filters
  void _applyLogFilters() {
    var logs = _activityLogs;

    // Apply category filter
    if (_logCategoryFilter != 'All') {
      logs = logs.where((log) => log.category == _logCategoryFilter).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (_logDateFilter) {
      case 'Today':
        logs = logs.where((log) => log.createdAt.isAfter(startOfToday)).toList();
        break;
      case 'This Week':
        final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
        logs = logs.where((log) => log.createdAt.isAfter(startOfWeek)).toList();
        break;
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        logs = logs.where((log) => log.createdAt.isAfter(startOfMonth)).toList();
        break;
      // 'All Time' - no date filtering
    }

    _filteredLogs = logs;
  }

  /// Refresh activity logs
  Future<void> refreshActivityLogs() async {
    await loadActivityLogs();
  }

  /// Get activity count by category
  Map<String, int> getActivityCountByCategory() {
    final counts = <String, int>{
      'Users': 0,
      'Flats': 0,
      'Visitors': 0,
      'Settings': 0,
    };

    for (final log in _filteredLogs) {
      counts[log.category] = (counts[log.category] ?? 0) + 1;
    }

    return counts;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Get user by ID from loaded users
  UserModel? getUserById(String id) {
    try {
      return _allUsers.firstWhere((user) => user.uid == id);
    } catch (e) {
      return null;
    }
  }

  /// Get user count by role from loaded users
  Map<String, int> getUserCountByRole() {
    final counts = <String, int>{
      'guard': 0,
      'resident': 0,
      'admin': 0,
    };

    for (final user in _allUsers) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }

    return counts;
  }

  /// Search users for resident assignment
  List<UserModel> searchUsersForAssignment(String query) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    return _allUsers.where((user) =>
        user.role == 'resident' &&
        (user.name.toLowerCase().contains(queryLower) ||
            (user.phone?.contains(query) ?? false))).toList();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _roleFilter = 'All';
    _applyUserFilters();
    notifyListeners();
  }

  void clearFlatFilters() {
    _flatSearchQuery = '';
    _blockFilter = 'All';
    _statusFilter = 'All';
    _applyFlatFilters();
    notifyListeners();
  }

  void clearLogFilters() {
    _logCategoryFilter = 'All';
    _logDateFilter = 'Today';
    _applyLogFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _flatsSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }
}
