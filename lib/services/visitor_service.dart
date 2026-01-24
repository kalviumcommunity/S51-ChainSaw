import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor_model.dart';
import '../core/constants/app_constants.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _visitorsRef =>
      _firestore.collection(AppConstants.visitorsCollection);

  // ============================================================
  // CREATE
  // ============================================================

  /// Add a new visitor to Firestore
  Future<String> addVisitor(VisitorModel visitor) async {
    try {
      final docRef = await _visitorsRef.add(visitor.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add visitor: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  /// Get a single visitor by ID
  Future<VisitorModel?> getVisitor(String visitorId) async {
    try {
      final doc = await _visitorsRef.doc(visitorId).get();
      if (doc.exists && doc.data() != null) {
        return VisitorModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get visitor: $e');
    }
  }

  /// Get all visitors (for admin)
  Future<List<VisitorModel>> getAllVisitors() async {
    try {
      final snapshot = await _visitorsRef
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get visitors: $e');
    }
  }

  /// Get visitors by status
  Future<List<VisitorModel>> getVisitorsByStatus(String status) async {
    try {
      final snapshot = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: status)
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get visitors by status: $e');
    }
  }

  /// Get visitors for a specific flat
  Future<List<VisitorModel>> getVisitorsForFlat(String flatNumber) async {
    try {
      final snapshot = await _visitorsRef
          .where(AppConstants.fieldVisitorFlat, isEqualTo: flatNumber)
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get visitors for flat: $e');
    }
  }

  /// Get pending visitors for a specific flat
  Future<List<VisitorModel>> getPendingVisitorsForFlat(String flatNumber) async {
    try {
      final snapshot = await _visitorsRef
          .where(AppConstants.fieldVisitorFlat, isEqualTo: flatNumber)
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusPending)
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending visitors: $e');
    }
  }

  /// Get visitors currently inside (approved but not checked out)
  Future<List<VisitorModel>> getVisitorsInside() async {
    try {
      final snapshot = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusApproved)
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get visitors inside: $e');
    }
  }

  // ============================================================
  // REAL-TIME STREAMS
  // ============================================================

  /// Stream of all pending visitors
  Stream<List<VisitorModel>> streamPendingVisitors() {
    return _visitorsRef
        .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusPending)
        .orderBy(AppConstants.fieldEntryTime, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of visitors inside (approved)
  Stream<List<VisitorModel>> streamVisitorsInside() {
    return _visitorsRef
        .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusApproved)
        .orderBy(AppConstants.fieldEntryTime, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of pending visitors for a specific flat
  Stream<List<VisitorModel>> streamPendingVisitorsForFlat(String flatNumber) {
    return _visitorsRef
        .where(AppConstants.fieldVisitorFlat, isEqualTo: flatNumber)
        .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusPending)
        .orderBy(AppConstants.fieldEntryTime, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of all visitors for a specific flat
  Stream<List<VisitorModel>> streamVisitorsForFlat(String flatNumber) {
    return _visitorsRef
        .where(AppConstants.fieldVisitorFlat, isEqualTo: flatNumber)
        .orderBy(AppConstants.fieldEntryTime, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// Update visitor status (approve/deny)
  Future<void> updateVisitorStatus({
    required String visitorId,
    required String status,
    String? approvedBy,
    String? deniedBy,
  }) async {
    try {
      final Map<String, dynamic> data = {
        AppConstants.fieldVisitorStatus: status,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      };

      if (status == AppConstants.statusApproved && approvedBy != null) {
        data[AppConstants.fieldApprovedBy] = approvedBy;
      }

      if (status == AppConstants.statusDenied && deniedBy != null) {
        data[AppConstants.fieldDeniedBy] = deniedBy;
      }

      await _visitorsRef.doc(visitorId).update(data);
    } catch (e) {
      throw Exception('Failed to update visitor status: $e');
    }
  }

  /// Approve a visitor
  Future<void> approveVisitor(String visitorId, String approvedBy) async {
    await updateVisitorStatus(
      visitorId: visitorId,
      status: AppConstants.statusApproved,
      approvedBy: approvedBy,
    );
  }

  /// Deny a visitor
  Future<void> denyVisitor(String visitorId, String deniedBy) async {
    await updateVisitorStatus(
      visitorId: visitorId,
      status: AppConstants.statusDenied,
      deniedBy: deniedBy,
    );
  }

  /// Check out a visitor
  Future<void> checkoutVisitor(String visitorId) async {
    try {
      await _visitorsRef.doc(visitorId).update({
        AppConstants.fieldVisitorStatus: AppConstants.statusCheckedOut,
        AppConstants.fieldExitTime: FieldValue.serverTimestamp(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to checkout visitor: $e');
    }
  }

  /// Update visitor details
  Future<void> updateVisitor(String visitorId, Map<String, dynamic> data) async {
    try {
      data[AppConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _visitorsRef.doc(visitorId).update(data);
    } catch (e) {
      throw Exception('Failed to update visitor: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete a visitor (admin only)
  Future<void> deleteVisitor(String visitorId) async {
    try {
      await _visitorsRef.doc(visitorId).delete();
    } catch (e) {
      throw Exception('Failed to delete visitor: $e');
    }
  }

  // ============================================================
  // QUERIES
  // ============================================================

  /// Get visitors for today
  Future<List<VisitorModel>> getTodayVisitors() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _visitorsRef
          .where(AppConstants.fieldEntryTime,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where(AppConstants.fieldEntryTime,
              isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy(AppConstants.fieldEntryTime, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VisitorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get today visitors: $e');
    }
  }

  /// Get visitor count by status
  Future<Map<String, int>> getVisitorCountByStatus() async {
    try {
      final pending = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusPending)
          .count()
          .get();

      final approved = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusApproved)
          .count()
          .get();

      final denied = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusDenied)
          .count()
          .get();

      final checkedOut = await _visitorsRef
          .where(AppConstants.fieldVisitorStatus, isEqualTo: AppConstants.statusCheckedOut)
          .count()
          .get();

      return {
        AppConstants.statusPending: pending.count ?? 0,
        AppConstants.statusApproved: approved.count ?? 0,
        AppConstants.statusDenied: denied.count ?? 0,
        AppConstants.statusCheckedOut: checkedOut.count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get visitor count: $e');
    }
  }
}
