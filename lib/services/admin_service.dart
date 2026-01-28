import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _flatsRef =>
      _firestore.collection(AppConstants.flatsCollection);

  // ============================================================
  // USER MANAGEMENT
  // ============================================================

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersRef
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _usersRef
          .where(AppConstants.fieldRole, isEqualTo: role)
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  /// Stream all users (real-time)
  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef
        .orderBy(AppConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Stream users by role (real-time)
  Stream<List<UserModel>> streamUsersByRole(String role) {
    return _usersRef
        .where(AppConstants.fieldRole, isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _usersRef.doc(userId).update({
        AppConstants.fieldRole: newRole,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Update user details (admin action)
  Future<void> updateUserDetails({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? flatNumber,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> data = {
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      };

      if (name != null) data[AppConstants.fieldName] = name;
      if (phone != null) data[AppConstants.fieldPhone] = phone;
      if (email != null) data['email'] = email;
      if (flatNumber != null) data[AppConstants.fieldFlatNumber] = flatNumber;
      if (role != null) data[AppConstants.fieldRole] = role;

      await _usersRef.doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user details: $e');
    }
  }

  /// Delete user (admin action)
  Future<void> deleteUser(String userId) async {
    try {
      // Remove user from any flats they're assigned to
      final flatsSnapshot = await _flatsRef
          .where(AppConstants.fieldResidentIds, arrayContains: userId)
          .get();

      final batch = _firestore.batch();

      for (final flatDoc in flatsSnapshot.docs) {
        batch.update(flatDoc.reference, {
          AppConstants.fieldResidentIds: FieldValue.arrayRemove([userId]),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }

      // Delete the user document
      batch.delete(_usersRef.doc(userId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Search users by name or phone
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Get all users and filter client-side (Firestore doesn't support full-text search)
      final snapshot = await _usersRef.get();
      final queryLower = query.toLowerCase();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .where((user) =>
              user.name.toLowerCase().contains(queryLower) ||
              (user.phone?.contains(query) ?? false) ||
              (user.email?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Assign user to flat
  Future<void> assignUserToFlat(String userId, String flatNumber) async {
    try {
      // Update user's flat number
      await _usersRef.doc(userId).update({
        AppConstants.fieldFlatNumber: flatNumber,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });

      // Add user to flat's resident list
      final flatSnapshot = await _flatsRef
          .where(AppConstants.fieldFlatNum, isEqualTo: flatNumber)
          .limit(1)
          .get();

      if (flatSnapshot.docs.isNotEmpty) {
        await flatSnapshot.docs.first.reference.update({
          AppConstants.fieldResidentIds: FieldValue.arrayUnion([userId]),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to assign user to flat: $e');
    }
  }

  /// Remove user from flat
  Future<void> removeUserFromFlat(String userId, String flatNumber) async {
    try {
      // Clear user's flat number
      await _usersRef.doc(userId).update({
        AppConstants.fieldFlatNumber: null,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });

      // Remove user from flat's resident list
      final flatSnapshot = await _flatsRef
          .where(AppConstants.fieldFlatNum, isEqualTo: flatNumber)
          .limit(1)
          .get();

      if (flatSnapshot.docs.isNotEmpty) {
        await flatSnapshot.docs.first.reference.update({
          AppConstants.fieldResidentIds: FieldValue.arrayRemove([userId]),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to remove user from flat: $e');
    }
  }

  // ============================================================
  // USER COUNTS
  // ============================================================

  /// Get user count by role
  Future<Map<String, int>> getUserCountByRole() async {
    try {
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
    } catch (e) {
      throw Exception('Failed to get user count by role: $e');
    }
  }

  /// Get total user count
  Future<int> getTotalUserCount() async {
    try {
      final result = await _usersRef.count().get();
      return result.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get total user count: $e');
    }
  }

  // ============================================================
  // RECENT USERS
  // ============================================================

  /// Get recently registered users
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      final snapshot = await _usersRef
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent users: $e');
    }
  }

  /// Get users registered today
  Future<List<UserModel>> getUsersRegisteredToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _usersRef
          .where(AppConstants.fieldCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy(AppConstants.fieldCreatedAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users registered today: $e');
    }
  }
}
