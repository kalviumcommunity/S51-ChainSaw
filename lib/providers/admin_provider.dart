import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';

enum AdminStatus { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final AnalyticsService _analyticsService = AnalyticsService();

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

  // Stream subscriptions
  StreamSubscription<List<UserModel>>? _usersSubscription;

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

  // Computed getters for dashboard
  int get totalUsers => _dashboardStats?.totalUsers ?? 0;
  int get totalFlats => _dashboardStats?.totalFlats ?? 0;
  int get todayVisitors => _dashboardStats?.todayVisitors ?? 0;
  int get pendingVisitors => _dashboardStats?.pendingVisitors ?? 0;
  int get visitorsInside => _dashboardStats?.visitorsInside ?? 0;
  int get totalGuards => _dashboardStats?.totalGuards ?? 0;
  int get totalResidents => _dashboardStats?.totalResidents ?? 0;
  int get totalAdmins => _dashboardStats?.totalAdmins ?? 0;

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
      ]);

      _status = AdminStatus.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = AdminStatus.error;
      notifyListeners();
    }
  }

  /// Initialize with real-time user stream
  void initializeWithStream() {
    _status = AdminStatus.loading;
    notifyListeners();

    // Stream all users
    _usersSubscription?.cancel();
    _usersSubscription = _adminService.streamAllUsers().listen(
      (users) {
        _allUsers = users;
        _applyFilters();
        _status = AdminStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _status = AdminStatus.error;
        notifyListeners();
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
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load all users: $e');
      _errorMessage = e.toString();
    }
  }

  /// Search users
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter by role
  void setRoleFilter(String role) {
    _roleFilter = role;
    _applyFilters();
    notifyListeners();
  }

  /// Apply search and role filters
  void _applyFilters() {
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
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}
