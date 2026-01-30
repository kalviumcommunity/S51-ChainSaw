import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../models/visitor_model.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  String _selectedFilter = 'All';

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
    return Consumer<VisitorProvider>(
      builder: (context, visitorProvider, child) {
        final allVisitors = visitorProvider.flatVisitors;
        final filteredVisitors = _selectedFilter == 'All'
            ? allVisitors
            : visitorProvider.getVisitorsByStatus(_selectedFilter.toLowerCase());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Visitor History'),
            backgroundColor: AppColors.residentColor,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', allVisitors.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved',
                          visitorProvider.getVisitorsByStatus('approved').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Denied',
                          visitorProvider.getVisitorsByStatus('denied').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Checked_out',
                          visitorProvider.getVisitorsByStatus('checked_out').length),
                    ],
                  ),
                ),
              ),

              // Visitor List
              Expanded(
                child: visitorProvider.isLoading && allVisitors.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredVisitors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No visitor history',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Visitors will appear here once approved or denied',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => visitorProvider.refresh(),
                            child: ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    final displayLabel = label == 'Checked_out' ? 'Checked Out' : label;

    return FilterChip(
      label: Text('$displayLabel ($count)'),
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
    final dateFormat = DateFormat('MMM d, yyyy');
    final entryTimeStr = timeFormat.format(visitor.entryTime);
    final entryDateStr = dateFormat.format(visitor.entryTime);

    // Calculate relative date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate =
        DateTime(visitor.entryTime.year, visitor.entryTime.month, visitor.entryTime.day);

    String relativeDate;
    if (entryDate == today) {
      relativeDate = 'Today';
    } else if (entryDate == yesterday) {
      relativeDate = 'Yesterday';
    } else {
      relativeDate = entryDateStr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showVisitorDetails(visitor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withAlpha(50),
                radius: 24,
                child: Text(
                  visitor.name.isNotEmpty ? visitor.name[0] : 'V',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.notes, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visitor.purpose ?? 'No purpose specified',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '$relativeDate at $entryTimeStr',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
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
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitorDetails(VisitorModel visitor) {
    final status = visitor.status;
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final entryTimeStr = timeFormat.format(visitor.entryTime);
    final entryDateStr = dateFormat.format(visitor.entryTime);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withAlpha(50),
                    radius: 32,
                    child: Text(
                      visitor.name.isNotEmpty ? visitor.name[0] : 'V',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
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
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.phone, 'Phone', visitor.phone),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.notes, 'Purpose', visitor.purpose ?? 'Not specified'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, 'Date', entryDateStr),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Entry Time', entryTimeStr),
              if (visitor.exitTime != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.logout, 'Exit Time',
                    timeFormat.format(visitor.exitTime!)),
              ],
              if (visitor.guardName != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.security, 'Guard', visitor.guardName!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
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
