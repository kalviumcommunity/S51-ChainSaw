import 'dart:async';
import 'package:flutter/material.dart';
import '../models/visitor_model.dart';
import '../services/visitor_service.dart';
import '../services/notification_service.dart';
import '../services/activity_log_service.dart';

enum VisitorStatus { initial, loading, loaded, error }

class VisitorProvider extends ChangeNotifier {
  final VisitorService _visitorService = VisitorService();
  final NotificationService _notificationService = NotificationService();
  final ActivityLogService _activityLogService = ActivityLogService();

  // State
  VisitorStatus _status = VisitorStatus.initial;
  String? _errorMessage;

  // Data lists
  List<VisitorModel> _pendingVisitors = [];
  List<VisitorModel> _visitorsInside = [];
  List<VisitorModel> _allVisitors = [];
  List<VisitorModel> _flatVisitors = [];
  List<VisitorModel> _flatPendingVisitors = [];

  // Counts
  int _pendingCount = 0;
  int _insideCount = 0;
  int _todayCount = 0;

  // Stream subscriptions
  StreamSubscription<List<VisitorModel>>? _pendingSubscription;
  StreamSubscription<List<VisitorModel>>? _insideSubscription;
  StreamSubscription<List<VisitorModel>>? _flatPendingSubscription;
  StreamSubscription<List<VisitorModel>>? _flatVisitorsSubscription;

  // Getters
  VisitorStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == VisitorStatus.loading;

  List<VisitorModel> get pendingVisitors => _pendingVisitors;
  List<VisitorModel> get visitorsInside => _visitorsInside;
  List<VisitorModel> get allVisitors => _allVisitors;
  List<VisitorModel> get flatVisitors => _flatVisitors;
  List<VisitorModel> get flatPendingVisitors => _flatPendingVisitors;

  int get pendingCount => _pendingCount;
  int get insideCount => _insideCount;
  int get todayCount => _todayCount;

  // ============================================================
  // INITIALIZATION FOR GUARD
  // ============================================================

  /// Initialize streams for guard (all pending + all inside)
  void initializeForGuard() {
    _status = VisitorStatus.loading;
    notifyListeners();

    // Stream pending visitors
    _pendingSubscription?.cancel();
    _pendingSubscription = _visitorService.streamPendingVisitors().listen(
      (visitors) {
        _pendingVisitors = visitors;
        _pendingCount = visitors.length;
        _status = VisitorStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _status = VisitorStatus.error;
        notifyListeners();
      },
    );

    // Stream visitors inside
    _insideSubscription?.cancel();
    _insideSubscription = _visitorService.streamVisitorsInside().listen(
      (visitors) {
        _visitorsInside = visitors;
        _insideCount = visitors.length;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Load today's count
    _loadTodayCount();
  }

  // ============================================================
  // INITIALIZATION FOR RESIDENT
  // ============================================================

  /// Initialize streams for resident (flat-specific)
  void initializeForResident(String flatNumber) {
    if (flatNumber.isEmpty) return;

    _status = VisitorStatus.loading;
    notifyListeners();

    // Stream pending visitors for this flat
    _flatPendingSubscription?.cancel();
    _flatPendingSubscription =
        _visitorService.streamPendingVisitorsForFlat(flatNumber).listen(
      (visitors) {
        _flatPendingVisitors = visitors;
        _pendingCount = visitors.length;
        _status = VisitorStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _status = VisitorStatus.error;
        notifyListeners();
      },
    );

    // Stream all visitors for this flat (history)
    _flatVisitorsSubscription?.cancel();
    _flatVisitorsSubscription =
        _visitorService.streamVisitorsForFlat(flatNumber).listen(
      (visitors) {
        _flatVisitors = visitors;
        _insideCount = visitors.where((v) => v.isApproved).length;
        _todayCount = visitors
            .where((v) =>
                v.entryTime.day == DateTime.now().day &&
                v.entryTime.month == DateTime.now().month &&
                v.entryTime.year == DateTime.now().year)
            .length;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // ============================================================
  // VISITOR ACTIONS
  // ============================================================

  /// Add a new visitor (Guard action)
  Future<bool> addVisitor({
    required String name,
    required String phone,
    required String flatNumber,
    required String guardId,
    String? guardName,
    String? purpose,
  }) async {
    _status = VisitorStatus.loading;
    notifyListeners();

    try {
      final visitor = VisitorModel(
        id: '',
        name: name,
        phone: phone,
        flatNumber: flatNumber,
        status: 'pending',
        entryTime: DateTime.now(),
        guardId: guardId,
        guardName: guardName,
        purpose: purpose,
      );

      final visitorId = await _visitorService.addVisitor(visitor);

      // Send notification to residents of this flat
      await _notificationService.notifyResidentNewVisitor(
        visitorName: name,
        flatNumber: flatNumber,
        visitorId: visitorId,
      );

      _status = VisitorStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = VisitorStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Approve a visitor (Resident action)
  Future<bool> approveVisitor(String visitorId, String approvedBy, {String? approvedByName}) async {
    try {
      // Get visitor details before approving
      final visitor = await _visitorService.getVisitor(visitorId);

      await _visitorService.approveVisitor(visitorId, approvedBy);

      // Notify the guard who added this visitor
      if (visitor != null && visitor.guardId.isNotEmpty) {
        await _notificationService.notifyGuardVisitorApproved(
          guardId: visitor.guardId,
          visitorName: visitor.name,
          flatNumber: visitor.flatNumber,
          visitorId: visitorId,
          approvedBy: approvedBy,
        );

        // Log activity
        await _activityLogService.logVisitorApproved(
          residentId: approvedBy,
          residentName: approvedByName ?? 'Resident',
          visitorId: visitorId,
          visitorName: visitor.name,
          flatNumber: visitor.flatNumber,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Deny a visitor (Resident action)
  Future<bool> denyVisitor(String visitorId, String deniedBy, {String? deniedByName}) async {
    try {
      // Get visitor details before denying
      final visitor = await _visitorService.getVisitor(visitorId);

      await _visitorService.denyVisitor(visitorId, deniedBy);

      // Notify the guard who added this visitor
      if (visitor != null && visitor.guardId.isNotEmpty) {
        await _notificationService.notifyGuardVisitorDenied(
          guardId: visitor.guardId,
          visitorName: visitor.name,
          flatNumber: visitor.flatNumber,
          visitorId: visitorId,
          deniedBy: deniedBy,
        );

        // Log activity
        await _activityLogService.logVisitorDenied(
          residentId: deniedBy,
          residentName: deniedByName ?? 'Resident',
          visitorId: visitorId,
          visitorName: visitor.name,
          flatNumber: visitor.flatNumber,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Checkout a visitor (Guard action)
  Future<bool> checkoutVisitor(String visitorId, {String? guardId, String? guardName}) async {
    try {
      // Get visitor details before checkout
      final visitor = await _visitorService.getVisitor(visitorId);

      await _visitorService.checkoutVisitor(visitorId);

      // Log activity
      if (visitor != null && guardId != null) {
        await _activityLogService.logVisitorCheckedOut(
          guardId: guardId,
          guardName: guardName ?? 'Guard',
          visitorId: visitorId,
          visitorName: visitor.name,
          flatNumber: visitor.flatNumber,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  /// Load today's visitor count
  Future<void> _loadTodayCount() async {
    try {
      final todayVisitors = await _visitorService.getTodayVisitors();
      _todayCount = todayVisitors.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load today count: $e');
    }
  }

  /// Refresh all data (pull to refresh)
  Future<void> refresh() async {
    await _loadTodayCount();
  }

  /// Load all visitors (for admin)
  Future<void> loadAllVisitors() async {
    _status = VisitorStatus.loading;
    notifyListeners();

    try {
      _allVisitors = await _visitorService.getAllVisitors();
      _status = VisitorStatus.loaded;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = VisitorStatus.error;
      notifyListeners();
    }
  }

  // ============================================================
  // FILTERING HELPERS
  // ============================================================

  /// Get visitors by status from flat visitors
  List<VisitorModel> getVisitorsByStatus(String status) {
    if (status == 'all') return _flatVisitors;
    return _flatVisitors.where((v) => v.status == status).toList();
  }

  /// Get visitors inside for flat
  List<VisitorModel> get flatVisitorsInside {
    return _flatVisitors.where((v) => v.isApproved).toList();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _insideSubscription?.cancel();
    _flatPendingSubscription?.cancel();
    _flatVisitorsSubscription?.cancel();
    super.dispose();
  }
}
