import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../models/visitor_model.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize visitor provider for resident
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.flatNumber != null && user!.flatNumber!.isNotEmpty) {
        context.read<VisitorProvider>().initializeForResident(user.flatNumber!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, VisitorProvider>(
      builder: (context, authProvider, visitorProvider, child) {
        final user = authProvider.user;
        final pendingCount = visitorProvider.pendingCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Resident Dashboard'),
            backgroundColor: AppColors.residentColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
            ],
          ),
          body: _buildBody(visitorProvider, user),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: pendingCount > 0
                    ? Badge(
                        label: Text('$pendingCount'),
                        child: const Icon(Icons.notifications_outlined),
                      )
                    : const Icon(Icons.notifications_outlined),
                selectedIcon: pendingCount > 0
                    ? Badge(
                        label: Text('$pendingCount'),
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
                label: 'Requests',
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(VisitorProvider visitorProvider, user) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(visitorProvider, user);
      case 1:
        return _buildRequestsTab(visitorProvider);
      case 2:
        return _buildHistoryTab(visitorProvider);
      default:
        return _buildHomeTab(visitorProvider, user);
    }
  }

  Widget _buildHomeTab(VisitorProvider visitorProvider, user) {
    return RefreshIndicator(
      onRefresh: () => visitorProvider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(user?.name ?? 'Resident', user?.flatNumber),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(visitorProvider),
            const SizedBox(height: 24),

            // Pending Requests Section
            _buildSectionHeader('Pending Requests', onViewAll: () {
              setState(() {
                _selectedIndex = 1;
              });
            }),
            const SizedBox(height: 12),
            _buildPendingRequestsList(visitorProvider),
            const SizedBox(height: 24),

            // Currently Inside Section
            _buildSectionHeader('Visitors Inside', onViewAll: () {
              setState(() {
                _selectedIndex = 2;
              });
            }),
            const SizedBox(height: 12),
            _buildVisitorsInsideList(visitorProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String? flatNumber) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.residentColor, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.residentColor.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Flat: ${flatNumber ?? 'Not assigned'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(VisitorProvider visitorProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${visitorProvider.pendingCount}',
            Icons.pending_actions,
            AppColors.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Inside',
            '${visitorProvider.insideCount}',
            Icons.login,
            AppColors.approved,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Today',
            '${visitorProvider.todayCount}',
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
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildPendingRequestsList(VisitorProvider visitorProvider) {
    final pendingVisitors = visitorProvider.flatPendingVisitors;

    if (visitorProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingVisitors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        message: 'No pending requests',
      );
    }

    return Column(
      children: pendingVisitors.take(3).map((visitor) {
        return _buildPendingVisitorCard(visitor, visitorProvider);
      }).toList(),
    );
  }

  Widget _buildPendingVisitorCard(VisitorModel visitor, VisitorProvider visitorProvider) {
    final timeFormat = DateFormat('hh:mm a');
    final entryTimeStr = timeFormat.format(visitor.entryTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.pending.withAlpha(100)),
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.pending.withAlpha(50),
                child: Text(
                  visitor.name.isNotEmpty ? visitor.name[0] : 'V',
                  style: const TextStyle(
                    color: AppColors.pending,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      visitor.purpose ?? 'No purpose specified',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                entryTimeStr,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleDeny(visitor.id, visitorProvider),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.denied,
                    side: const BorderSide(color: AppColors.denied),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(visitor.id, visitorProvider),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.approved,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorsInsideList(VisitorProvider visitorProvider) {
    final visitorsInside = visitorProvider.flatVisitorsInside;

    if (visitorProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (visitorsInside.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        message: 'No visitors inside',
      );
    }

    return Column(
      children: visitorsInside.take(3).map((visitor) {
        return _buildVisitorInsideCard(visitor);
      }).toList(),
    );
  }

  Widget _buildVisitorInsideCard(VisitorModel visitor) {
    final timeFormat = DateFormat('hh:mm a');
    final entryTimeStr = timeFormat.format(visitor.entryTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.approved.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.approved.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.approved.withAlpha(50),
            radius: 20,
            child: Text(
              visitor.name.isNotEmpty ? visitor.name[0] : 'V',
              style: const TextStyle(
                color: AppColors.approved,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  visitor.purpose ?? 'No purpose',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.approved,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Inside',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Since $entryTimeStr',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(VisitorProvider visitorProvider) {
    final pendingVisitors = visitorProvider.flatPendingVisitors;

    if (visitorProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingVisitors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => visitorProvider.refresh(),
      child: ListView.builder(
        key: ValueKey('requests_${pendingVisitors.length}_${pendingVisitors.map((v) => v.id).join('_')}'),
        padding: const EdgeInsets.all(16),
        itemCount: pendingVisitors.length,
        itemBuilder: (context, index) {
          final visitor = pendingVisitors[index];
          return _buildRequestCard(visitor, visitorProvider);
        },
      ),
    );
  }

  Widget _buildRequestCard(VisitorModel visitor, VisitorProvider visitorProvider) {
    final timeFormat = DateFormat('hh:mm a');
    final entryTimeStr = timeFormat.format(visitor.entryTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.pending.withAlpha(50),
                  radius: 28,
                  child: Text(
                    visitor.name.isNotEmpty ? visitor.name[0] : 'V',
                    style: const TextStyle(
                      color: AppColors.pending,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            visitor.phone,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pending.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppColors.pending,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(Icons.access_time, 'Time', entryTimeStr),
                const SizedBox(width: 24),
                _buildInfoItem(Icons.notes, 'Purpose', visitor.purpose ?? 'Not specified'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeny(visitor.id, visitorProvider),
                    icon: const Icon(Icons.close),
                    label: const Text('Deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.denied,
                      side: const BorderSide(color: AppColors.denied),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(visitor.id, visitorProvider),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approved,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(VisitorProvider visitorProvider) {
    return VisitorHistoryTab(visitorProvider: visitorProvider);
  }

  Future<void> _handleApprove(String visitorId, VisitorProvider visitorProvider) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final success = await visitorProvider.approveVisitor(
      visitorId,
      user.uid,
      approvedByName: user.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Visitor approved' : 'Failed to approve visitor'),
        backgroundColor: success ? AppColors.approved : AppColors.error,
      ),
    );
  }

  Future<void> _handleDeny(String visitorId, VisitorProvider visitorProvider) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final success = await visitorProvider.denyVisitor(
      visitorId,
      user.uid,
      deniedByName: user.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Visitor denied' : 'Failed to deny visitor'),
        backgroundColor: success ? AppColors.denied : AppColors.error,
      ),
    );
  }
}

// Embedded Visitor History Tab
class VisitorHistoryTab extends StatefulWidget {
  final VisitorProvider visitorProvider;

  const VisitorHistoryTab({super.key, required this.visitorProvider});

  @override
  State<VisitorHistoryTab> createState() => _VisitorHistoryTabState();
}

class _VisitorHistoryTabState extends State<VisitorHistoryTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allVisitors = widget.visitorProvider.flatVisitors;
    final filteredVisitors = _selectedFilter == 'All'
        ? allVisitors
        : widget.visitorProvider.getVisitorsByStatus(_selectedFilter.toLowerCase());

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Denied'),
                const SizedBox(width: 8),
                _buildFilterChip('Checked_out'),
              ],
            ),
          ),
        ),

        // Visitor List
        Expanded(
          child: widget.visitorProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredVisitors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No visitor history',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => widget.visitorProvider.refresh(),
                      child: ListView.builder(
                        key: ValueKey('history_${filteredVisitors.length}_${filteredVisitors.map((v) => v.id).join('_')}'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredVisitors.length,
                        itemBuilder: (context, index) {
                          final visitor = filteredVisitors[index];
                          return _buildHistoryCard(visitor);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final displayLabel = label == 'Checked_out' ? 'Checked Out' : label;

    return FilterChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppColors.residentColor.withAlpha(50),
      checkmarkColor: AppColors.residentColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.residentColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildHistoryCard(VisitorModel visitor) {
    final status = visitor.status;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('MMM d');
    final entryTimeStr = '${dateFormat.format(visitor.entryTime)} at ${timeFormat.format(visitor.entryTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(50),
          child: Text(
            visitor.name.isNotEmpty ? visitor.name[0] : 'V',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          visitor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(visitor.purpose ?? 'No purpose'),
            const SizedBox(height: 4),
            Text(
              entryTimeStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.approved;
      case 'denied':
        return AppColors.denied;
      case 'checked_out':
        return AppColors.checkedOut;
      default:
        return AppColors.pending;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'denied':
        return Icons.cancel;
      case 'checked_out':
        return Icons.logout;
      default:
        return Icons.pending;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Inside';
      case 'denied':
        return 'Denied';
      case 'checked_out':
        return 'Left';
      default:
        return 'Pending';
    }
  }
}
