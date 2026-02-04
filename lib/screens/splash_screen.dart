import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay initialization to after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Initialize auth provider and check auth state
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    _navigateToNext(authProvider);
  }

  void _navigateToNext(AuthProvider authProvider) {
    String route;

    if (authProvider.isAuthenticated) {
      if (authProvider.isNewUser || authProvider.user == null) {
        // User authenticated but profile not complete
        route = AppRoutes.roleSelection;
      } else {
        // Initialize notifications for authenticated user
        context.read<NotificationProvider>().initialize(authProvider.user!.uid);

        // Navigate to appropriate home based on role
        route = _getHomeRoute(authProvider.user!.role);
      }
    } else {
      // Not authenticated, go to login
      route = AppRoutes.login;
    }

    Navigator.pushReplacementNamed(context, route);
  }

  String _getHomeRoute(String role) {
    switch (role) {
      case 'guard':
        return AppRoutes.guardHome;
      case 'resident':
        return AppRoutes.residentHome;
      case 'admin':
        return AppRoutes.adminHome;
      default:
        return AppRoutes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shield,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'GateKeeper',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visitor Management System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
