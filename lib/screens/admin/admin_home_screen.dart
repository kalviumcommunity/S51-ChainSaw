import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize admin provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.adminColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Flats',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildFlatsTab();
      case 3:
        return _buildActivityTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh stats from provider
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Overview Stats
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildOverviewStats(),
            const SizedBox(height: 24),

            // User Stats
            const Text(
              'Users by Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildUserStats(),
            const SizedBox(height: 24),

            // Visitor Stats
            const Text(
              'Visitor Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildVisitorStats(),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminColor, AppColors.adminColor.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 24,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your community',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppColors.success, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    // TODO: Replace with real data from provider
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            '24',
            Icons.people,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Flats',
            '50',
            Icons.apartment,
            AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Today',
            '12',
            Icons.today,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    // TODO: Replace with real data from provider
    return Row(
      children: [
        Expanded(
          child: _buildUserRoleCard(
            'Guards',
            '5',
            Icons.security,
            AppColors.guardColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUserRoleCard(
            'Residents',
            '18',
            Icons.home,
            AppColors.residentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUserRoleCard(
            'Admins',
            '1',
            Icons.admin_panel_settings,
            AppColors.adminColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRoleCard(String role, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(50),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorStats() {
    // TODO: Replace with real data from provider
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildVisitorStatRow('Pending', 3, AppColors.pending),
          const Divider(height: 20),
          _buildVisitorStatRow('Inside', 5, AppColors.approved),
          const Divider(height: 20),
          _buildVisitorStatRow('Checked Out Today', 8, AppColors.checkedOut),
          const Divider(height: 20),
          _buildVisitorStatRow('Denied Today', 1, AppColors.denied),
        ],
      ),
    );
  }

  Widget _buildVisitorStatRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Add User',
            Icons.person_add,
            AppColors.primary,
            () {
              // TODO: Navigate to add user
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Add Flat',
            Icons.add_home,
            AppColors.secondary,
            () {
              // TODO: Navigate to add flat
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Reports',
            Icons.analytics,
            AppColors.info,
            () {
              // TODO: Navigate to reports
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentActivityList(),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    // TODO: Replace with real data from provider
    final activities = [
      {'action': 'New user registered', 'user': 'John Doe', 'time': '2 min ago', 'icon': Icons.person_add},
      {'action': 'Visitor approved', 'user': 'Flat A-101', 'time': '5 min ago', 'icon': Icons.check_circle},
      {'action': 'Guard logged in', 'user': 'Security 1', 'time': '10 min ago', 'icon': Icons.login},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.adminColor.withAlpha(25),
              child: Icon(
                activity['icon'] as IconData,
                color: AppColors.adminColor,
                size: 20,
              ),
            ),
            title: Text(
              activity['action'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              activity['user'] as String,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              activity['time'] as String,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    // Placeholder - will be replaced with UserManagementScreen content
    return const Center(
      child: Text('Users Tab - Navigate to User Management'),
    );
  }

  Widget _buildFlatsTab() {
    // Placeholder - will be implemented in PR7
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Flat Management',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in PR7',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    // Placeholder - will be implemented in PR7
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Activity Logs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in PR7',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
