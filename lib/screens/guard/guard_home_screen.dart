import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'add_visitor_screen.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Replace with actual data from provider
  final String _guardName = 'Guard';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Dashboard'),
        backgroundColor: AppColors.guardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Inside', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Welcome Banner
          _buildWelcomeBanner(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildInsideTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddVisitor(context),
        backgroundColor: AppColors.guardColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Visitor'),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.guardColor.withAlpha(25),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.guardColor,
            radius: 24,
            child: Text(
              _guardName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $_guardName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'On Duty',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    // TODO: Replace with actual data from provider
    final List<Map<String, dynamic>> pendingVisitors = [];

    if (pendingVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        title: 'No pending visitors',
        subtitle: 'Visitors waiting for approval will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingVisitors.length,
      itemBuilder: (context, index) {
        return _buildVisitorCard(pendingVisitors[index], showStatus: true);
      },
    );
  }

  Widget _buildInsideTab() {
    // TODO: Replace with actual data from provider
    final List<Map<String, dynamic>> insideVisitors = [];

    if (insideVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No visitors inside',
        subtitle: 'Approved visitors will appear here for checkout',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insideVisitors.length,
      itemBuilder: (context, index) {
        return _buildVisitorCard(insideVisitors[index], showCheckout: true);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorCard(
    Map<String, dynamic> visitor, {
    bool showStatus = false,
    bool showCheckout = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(50),
                  child: Text(
                    (visitor['name'] as String? ?? 'V').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor['name'] ?? 'Visitor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        visitor['phone'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStatus) _buildStatusBadge(visitor['status'] ?? 'pending'),
              ],
            ),
            const Divider(height: 24),
            // Details Row
            Row(
              children: [
                Icon(Icons.apartment, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Flat ${visitor['flatNumber'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  visitor['entryTime'] ?? '--:--',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            // Checkout Button
            if (showCheckout) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _checkoutVisitor(visitor['id']),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Check Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.pending;
        text = 'Pending';
        break;
      case 'approved':
        color = AppColors.approved;
        text = 'Approved';
        break;
      case 'denied':
        color = AppColors.denied;
        text = 'Denied';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToAddVisitor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVisitorScreen()),
    );
  }

  void _checkoutVisitor(String? visitorId) {
    // TODO: Implement checkout logic with provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visitor checked out successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout with provider
              Navigator.pushReplacementNamed(context, AppRoutes.phoneInput);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
