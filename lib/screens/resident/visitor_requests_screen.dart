import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../models/visitor_model.dart';

class VisitorRequestsScreen extends StatefulWidget {
  const VisitorRequestsScreen({super.key});

  @override
  State<VisitorRequestsScreen> createState() => _VisitorRequestsScreenState();
}

class _VisitorRequestsScreenState extends State<VisitorRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize visitor provider for resident if not already done
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
        final pendingVisitors = visitorProvider.flatPendingVisitors;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Visitor Requests'),
            backgroundColor: AppColors.residentColor,
            foregroundColor: Colors.white,
          ),
          body: visitorProvider.isLoading && pendingVisitors.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : pendingVisitors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.grey.shade300),
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
                    )
                  : RefreshIndicator(
                      onRefresh: () => visitorProvider.refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingVisitors.length,
                        itemBuilder: (context, index) {
                          final visitor = pendingVisitors[index];
                          return _buildRequestCard(
                              context, visitor, visitorProvider);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildRequestCard(
      BuildContext context, VisitorModel visitor, VisitorProvider visitorProvider) {
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
                _buildInfoItem(
                    Icons.notes, 'Purpose', visitor.purpose ?? 'Not specified'),
              ],
            ),
            if (visitor.guardName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(Icons.security, 'Guard', visitor.guardName!),
                ],
              ),
            ],
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
                      foregroundColor: Colors.white,
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

  Future<void> _handleApprove(
      String visitorId, VisitorProvider visitorProvider) async {
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

  Future<void> _handleDeny(
      String visitorId, VisitorProvider visitorProvider) async {
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
