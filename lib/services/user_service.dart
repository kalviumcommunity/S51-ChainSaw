import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // Create new user
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toJson());
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _usersRef.doc(uid).update(data);
  }

  // Update FCM token
  Future<void> updateFcmToken(String uid, String token) async {
    await updateUser(uid, {'fcmToken': token});
  }

  // Update auth methods
  Future<void> updateAuthMethods(String uid, List<String> authMethods) async {
    await updateUser(uid, {'authMethods': authMethods});
  }

  // Add auth method
  Future<void> addAuthMethod(String uid, String method) async {
    await _usersRef.doc(uid).update({
      'authMethods': FieldValue.arrayUnion([method]),
      'updatedAt': Timestamp.now(),
    });
  }

  // Remove auth method
  Future<void> removeAuthMethod(String uid, String method) async {
    await _usersRef.doc(uid).update({
      'authMethods': FieldValue.arrayRemove([method]),
      'updatedAt': Timestamp.now(),
    });
  }

  // Update email
  Future<void> updateEmail(String uid, String email) async {
    await updateUser(uid, {'email': email});
  }

  // Update phone
  Future<void> updatePhone(String uid, String phone) async {
    await updateUser(uid, {'phone': phone});
  }

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }
}
