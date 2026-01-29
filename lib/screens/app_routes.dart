import 'package:flutter/material.dart';

import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/phone_input_screen.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/guard/guard_home_screen.dart';
import '../../screens/guard/add_visitor_screen.dart';
import '../../screens/resident/resident_home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/add_edit_flat_screen.dart';
import '../../models/flat_model.dart';

class AppRoutes {
  AppRoutes._();

  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String phoneInput = '/phone-input';
  static const String otpVerification = '/otp-verification';
  static const String roleSelection = '/role-selection';
  static const String guardHome = '/guard-home';
  static const String addVisitor = '/add-visitor';
  static const String residentHome = '/resident-home';
  static const String adminHome = '/admin-home';
  static const String addFlat = '/add-flat';
  static const String editFlat = '/edit-flat';
  static const String profile = '/profile';

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case phoneInput:
        return MaterialPageRoute(builder: (_) => const PhoneInputScreen());

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            verificationId: args['verificationId'],
            phoneNumber: args['phoneNumber'],
          ),
        );

      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case guardHome:
        return MaterialPageRoute(builder: (_) => const GuardHomeScreen());

      case addVisitor:
        return MaterialPageRoute(builder: (_) => const AddVisitorScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case residentHome:
        return MaterialPageRoute(builder: (_) => const ResidentHomeScreen());

      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());

      case addFlat:
        return MaterialPageRoute(builder: (_) => const AddEditFlatScreen());

      case editFlat:
        final flat = settings.arguments as FlatModel;
        return MaterialPageRoute(
          builder: (_) => AddEditFlatScreen(flat: flat),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
