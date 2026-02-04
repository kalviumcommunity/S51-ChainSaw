import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../models/visitor_model.dart';
import 'add_visitor_screen.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize visitor provider for guard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitorProvider>().initializeForGuard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, VisitorProvider>(
      builder: (context, authProvider, visitorProvider, child) {
        final user = authProvider.user;
        final guardName = user?.name ?? 'Guard';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Guard Dashboard'),
            backgroundColor: AppColors.guardColor,
            actions: [
              // Profile Button
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                tooltip: 'Profile',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  text: 'Pending (${visitorProvider.pendingCount})',
                  icon: const Icon(Icons.hourglass_empty),
                ),
                Tab(
                  text: 'Inside (${visitorProvider.insideCount})',
                  icon: const Icon(Icons.people),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Welcome Banner
              _buildWelcomeBanner(guardName, user?.photoUrl, visitorProvider),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(visitorProvider),
                    _buildInsideTab(visitorProvider),
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
      },
    );
  }

  Widget _buildWelcomeBanner(
      String guardName, String? photoUrl, VisitorProvider visitorProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.guardColor.withAlpha(25),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.guardColor,
            radius: 24,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    guardName.isNotEmpty
                        ? guardName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $guardName',
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
                    const SizedBox(width: 16),
                    Text(
                      'Today: ${visitorProvider.todayCount} visitors',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.guardColor),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(VisitorProvider visitorProvider) {
    if (visitorProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingVisitors = visitorProvider.pendingVisitors;

    if (pendingVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        title: 'No pending visitors',
        subtitle: 'Visitors waiting for approval will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => visitorProvider.refresh(),
      child: ListView.builder(
        key: ValueKey('pending_${pendingVisitors.length}_${pendingVisitors.map((v) => v.id).join('_')}'),
        padding: const EdgeInsets.all(16),
        itemCount: pendingVisitors.length,
        itemBuilder: (context, index) {
          return _buildVisitorCard(pendingVisitors[index], showStatus: true);
        },
      ),
    );
  }

  Widget _buildInsideTab(VisitorProvider visitorProvider) {
    if (visitorProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final insideVisitors = visitorProvider.visitorsInside;

    if (insideVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No visitors inside',
        subtitle: 'Approved visitors will appear here for checkout',
      );
    }

    return RefreshIndicator(
      onRefresh: () => visitorProvider.refresh(),
      child: ListView.builder(
        key: ValueKey('inside_${insideVisitors.length}_${insideVisitors.map((v) => v.id).join('_')}'),
        padding: const EdgeInsets.all(16),
        itemCount: insideVisitors.length,
        itemBuilder: (context, index) {
          return _buildVisitorCard(insideVisitors[index], showCheckout: true);
        },
      ),
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
    VisitorModel visitor, {
    bool showStatus = false,
    bool showCheckout = false,
  }) {
    final timeFormat = DateFormat('hh:mm a');
    final entryTimeStr = timeFormat.format(visitor.entryTime);

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
                    visitor.name.isNotEmpty
                        ? visitor.name[0].toUpperCase()
                        : 'V',
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
                        visitor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        visitor.phone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStatus) _buildStatusBadge(visitor.status),
              ],
            ),
            const Divider(height: 24),
            // Details Row
            Row(
              children: [
                Icon(Icons.apartment, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Flat ${visitor.flatNumber}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  entryTimeStr,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            if (visitor.purpose != null && visitor.purpose!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notes, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    visitor.purpose!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            // Checkout Button
            if (showCheckout) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _checkoutVisitor(visitor.id),
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

  Future<void> _checkoutVisitor(String visitorId) async {
    final visitorProvider = context.read<VisitorProvider>();
    final user = context.read<AuthProvider>().user;

    final success = await visitorProvider.checkoutVisitor(
      visitorId,
      guardId: user?.uid,
      guardName: user?.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Visitor checked out successfully'
              : 'Failed to checkout visitor',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
