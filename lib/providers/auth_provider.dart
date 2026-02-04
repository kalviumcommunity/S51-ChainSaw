import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/flat_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FlatService _flatService = FlatService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _verificationId;
  String? _errorMessage;
  bool _isNewUser = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get verificationId => _verificationId;
  String? get errorMessage => _errorMessage;
  bool get isNewUser => _isNewUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  List<String> get linkedProviders => _authService.getLinkedProviders();

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _user = await _userService.getUser(firebaseUser.uid);
        if (_user != null) {
          _isNewUser = false;
          _status = AuthStatus.authenticated;
        } else {
          // User exists in Firebase Auth but not in Firestore
          _isNewUser = true;
          _status = AuthStatus.authenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // ============================================================
  // PHONE AUTHENTICATION
  // ============================================================

  Future<void> sendOTP(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (String verificationId) {
        _verificationId = verificationId;
        _status = AuthStatus.otpSent;
        notifyListeners();
      },
      onError: (String error) {
        _errorMessage = error;
        _status = AuthStatus.error;
        notifyListeners();
      },
      onAutoVerify: (PhoneAuthCredential credential) async {
        await _signInWithPhoneCredential(credential);
      },
    );
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'Verification ID not found. Please resend OTP.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.verifyOTP(
        verificationId: _verificationId!,
        otp: otp,
      );

      if (userCredential != null) {
        return await _handleSuccessfulAuth(userCredential, 'phone');
      } else {
        _errorMessage = 'Verification failed';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _authService.signInWithPhoneCredential(credential);
      if (userCredential != null) {
        await _handleSuccessfulAuth(userCredential, 'phone');
      }
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  // ============================================================
  // EMAIL AUTHENTICATION
  // ============================================================

  Future<bool> signUpWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        return await _handleSuccessfulAuth(userCredential, 'password');
      } else {
        _errorMessage = 'Sign up failed';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        return await _handleSuccessfulAuth(userCredential, 'password');
      } else {
        _errorMessage = 'Sign in failed';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // GOOGLE AUTHENTICATION
  // ============================================================

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        return await _handleSuccessfulAuth(userCredential, 'google.com');
      } else {
        // User cancelled
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // ACCOUNT LINKING
  // ============================================================

  Future<bool> linkPhone(String verificationId, String otp) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.linkPhoneNumber(
        verificationId: verificationId,
        otp: otp,
      );

      if (userCredential != null) {
        // Update user in Firestore
        final phone = userCredential.user?.phoneNumber;
        if (phone != null && _user != null) {
          await _userService.updatePhone(_user!.uid, phone);
          await _userService.addAuthMethod(_user!.uid, 'phone');
          _user = await _userService.getUser(_user!.uid);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.linkEmail(
        email: email,
        password: password,
      );

      if (userCredential != null && _user != null) {
        await _userService.updateEmail(_user!.uid, email);
        await _userService.addAuthMethod(_user!.uid, 'password');
        _user = await _userService.getUser(_user!.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.linkGoogle();

      if (userCredential != null && _user != null) {
        final googleUser = userCredential.user;
        if (googleUser != null) {
          await _userService.updateEmail(_user!.uid, googleUser.email ?? '');
          await _userService.addAuthMethod(_user!.uid, 'google.com');
          _user = await _userService.getUser(_user!.uid);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlinkProvider(String providerId) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.unlinkProvider(providerId);

      if (_user != null) {
        await _userService.removeAuthMethod(_user!.uid, providerId);
        _user = await _userService.getUser(_user!.uid);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // REGISTRATION
  // ============================================================

  Future<bool> completeRegistration({
    required String name,
    required String role,
    String? flatNumber,
  }) async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      _errorMessage = 'User not found';
      return false;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final authMethods = _authService.getLinkedProviders();

      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name,
        role: role,
        phone: firebaseUser.phoneNumber,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        flatNumber: flatNumber,
        authMethods: authMethods,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userService.createUser(newUser);

      // If resident, auto-create flat (if needed) and link resident to it
      if (role == 'resident' && flatNumber != null && flatNumber.isNotEmpty) {
        await _flatService.assignResidentToFlatByNumber(
          flatNumber,
          firebaseUser.uid,
        );
      }

      _user = newUser;
      _isNewUser = false;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // COMMON
  // ============================================================

  Future<bool> _handleSuccessfulAuth(
    UserCredential userCredential,
    String authMethod,
  ) async {
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) return false;

    // Check if user exists in Firestore
    final existingUser = await _userService.getUser(firebaseUser.uid);

    if (existingUser != null) {
      _user = existingUser;
      _isNewUser = false;

      // Update auth method if not already added
      if (!existingUser.authMethods.contains(authMethod)) {
        await _userService.addAuthMethod(firebaseUser.uid, authMethod);
        _user = await _userService.getUser(firebaseUser.uid);
      }
    } else {
      _isNewUser = true;
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _verificationId = null;
    _isNewUser = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _status = AuthStatus.error;
    notifyListeners();
  }
}
