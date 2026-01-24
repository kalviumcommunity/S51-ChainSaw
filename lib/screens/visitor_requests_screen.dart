import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VisitorRequestsScreen extends StatelessWidget {
  const VisitorRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real data from provider
    final pendingVisitors = [
      {'name': 'John Doe', 'phone': '9876543210', 'time': '10:30 AM', 'purpose': 'Delivery'},
      {'name': 'Jane Smith', 'phone': '9876543211', 'time': '11:15 AM', 'purpose': 'Guest'},
      {'name': 'Bob Wilson', 'phone': '9876543212', 'time': '11:45 AM', 'purpose': 'Maintenance'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Requests'),
        backgroundColor: AppColors.residentColor,
      ),
      body: pendingVisitors.isEmpty
          ? Center(
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
            )
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh data from provider
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingVisitors.length,
                itemBuilder: (context, index) {
                  final visitor = pendingVisitors[index];
                  return _buildRequestCard(context, visitor);
                },
              ),
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, String> visitor) {
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
                    visitor['name']![0],
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
                        visitor['name']!,
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
                            visitor['phone']!,
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
                _buildInfoItem(Icons.access_time, 'Time', visitor['time']!),
                const SizedBox(width: 24),
                _buildInfoItem(Icons.notes, 'Purpose', visitor['purpose']!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeny(context, visitor['name']!),
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
                    onPressed: () => _handleApprove(context, visitor['name']!),
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

  void _handleApprove(BuildContext context, String visitorName) {
    // TODO: Implement with provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$visitorName approved'),
        backgroundColor: AppColors.approved,
      ),
    );
  }

  void _handleDeny(BuildContext context, String visitorName) {
    // TODO: Implement with provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$visitorName denied'),
        backgroundColor: AppColors.denied,
      ),
    );
  }
}