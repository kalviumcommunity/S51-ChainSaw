import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/activity_log_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String _selectedFilter = 'All';
  String _selectedDateRange = 'Today';

  // Mock data - will be replaced with provider in PR9
  final List<ActivityLog> _mockLogs = [
    ActivityLog(
      id: '1',
      type: ActivityType.userCreated,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'user1',
      targetName: 'John Doe',
      description: 'Created new resident: John Doe',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ActivityLog(
      id: '2',
      type: ActivityType.roleChanged,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'user2',
      targetName: 'Jane Smith',
      description: 'Changed role of Jane Smith from resident to guard',
      metadata: {'oldRole': 'resident', 'newRole': 'guard'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ActivityLog(
      id: '3',
      type: ActivityType.flatCreated,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'flat1',
      targetName: 'A-101',
      description: 'Created flat: A-101',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ActivityLog(
      id: '4',
      type: ActivityType.residentAssigned,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'user3',
      targetName: 'Bob Wilson',
      description: 'Assigned Bob Wilson to flat A-102',
      metadata: {'flatNumber': 'A-102'},
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityLog(
      id: '5',
      type: ActivityType.userDeleted,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'user4',
      targetName: 'Test User',
      description: 'Deleted user: Test User',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ActivityLog(
      id: '6',
      type: ActivityType.flatUpdated,
      adminId: 'admin1',
      adminName: 'Admin User',
      targetId: 'flat2',
      targetName: 'B-201',
      description: 'Updated flat: B-201',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<ActivityLog> get _filteredLogs {
    var logs = _mockLogs;

    // Filter by type category
    if (_selectedFilter != 'All') {
      logs = logs.where((log) => log.category == _selectedFilter).toList();
    }

    // Filter by date range
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (_selectedDateRange) {
      case 'Today':
        logs = logs.where((log) => log.createdAt.isAfter(startOfToday)).toList();
        break;
      case 'This Week':
        final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
        logs = logs.where((log) => log.createdAt.isAfter(startOfWeek)).toList();
        break;
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        logs = logs.where((log) => log.createdAt.isAfter(startOfMonth)).toList();
        break;
    }

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Section
        _buildFilterSection(),

        // Stats Summary
        _buildStatsSummary(),

        // Activity List
        Expanded(
          child: _buildActivityList(),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Users'),
                const SizedBox(width: 8),
                _buildFilterChip('Flats'),
                const SizedBox(width: 8),
                _buildFilterChip('Visitors'),
                const SizedBox(width: 8),
                _buildFilterChip('Settings'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Date Range Filter
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              _buildDateRangeChip('Today'),
              const SizedBox(width: 8),
              _buildDateRangeChip('This Week'),
              const SizedBox(width: 8),
              _buildDateRangeChip('This Month'),
              const SizedBox(width: 8),
              _buildDateRangeChip('All Time'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppColors.adminColor.withAlpha(50),
      checkmarkColor: AppColors.adminColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateRangeChip(String label) {
    final isSelected = _selectedDateRange == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateRange = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.adminColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.adminColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final logs = _filteredLogs;
    final userActions = logs.where((l) => l.category == 'Users').length;
    final flatActions = logs.where((l) => l.category == 'Flats').length;
    final visitorActions = logs.where((l) => l.category == 'Visitors').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatBadge('Total', logs.length, AppColors.primary),
          const SizedBox(width: 8),
          _buildStatBadge('Users', userActions, AppColors.info),
          const SizedBox(width: 8),
          _buildStatBadge('Flats', flatActions, AppColors.secondary),
          const SizedBox(width: 8),
          _buildStatBadge('Visitors', visitorActions, AppColors.success),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.adminColor),
            onPressed: () {
              // TODO: Refresh from provider in PR9
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refresh will be implemented in PR9'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final logs = _filteredLogs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No activity found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    // Group logs by date
    final groupedLogs = _groupLogsByDate(logs);

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh from provider in PR9
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groupedLogs.length,
        itemBuilder: (context, index) {
          final date = groupedLogs.keys.elementAt(index);
          final dateLogs = groupedLogs[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatDateHeader(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              // Logs for this date
              ...dateLogs.map((log) => _buildActivityCard(log)),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<ActivityLog>> _groupLogsByDate(List<ActivityLog> logs) {
    final grouped = <String, List<ActivityLog>>{};

    for (final log in logs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(log);
    }

    return grouped;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today) || date.isAfter(today)) {
      return 'Today';
    } else if (date.isAtSameMomentAs(yesterday) || (date.isAfter(yesterday) && date.isBefore(today))) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    }
  }

  Widget _buildActivityCard(ActivityLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showActivityDetails(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Activity Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getActivityColor(log.type).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getActivityIcon(log.type),
                  color: _getActivityColor(log.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Activity Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(log.category).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.category,
                            style: TextStyle(
                              color: _getCategoryColor(log.category),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          log.adminName,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(log.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.userCreated:
        return Icons.person_add;
      case ActivityType.userUpdated:
        return Icons.edit;
      case ActivityType.userDeleted:
        return Icons.person_remove;
      case ActivityType.roleChanged:
        return Icons.swap_horiz;
      case ActivityType.flatCreated:
        return Icons.add_home;
      case ActivityType.flatUpdated:
        return Icons.home;
      case ActivityType.flatDeleted:
        return Icons.home_work;
      case ActivityType.residentAssigned:
        return Icons.person_add_alt;
      case ActivityType.residentRemoved:
        return Icons.person_off;
      case ActivityType.visitorApproved:
        return Icons.check_circle;
      case ActivityType.visitorDenied:
        return Icons.cancel;
      case ActivityType.visitorCheckedOut:
        return Icons.exit_to_app;
      case ActivityType.settingsUpdated:
        return Icons.settings;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.userCreated:
      case ActivityType.flatCreated:
      case ActivityType.residentAssigned:
      case ActivityType.visitorApproved:
        return AppColors.success;
      case ActivityType.userUpdated:
      case ActivityType.flatUpdated:
      case ActivityType.roleChanged:
      case ActivityType.settingsUpdated:
        return AppColors.info;
      case ActivityType.userDeleted:
      case ActivityType.flatDeleted:
      case ActivityType.residentRemoved:
      case ActivityType.visitorDenied:
        return AppColors.error;
      case ActivityType.visitorCheckedOut:
        return AppColors.warning;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Users':
        return AppColors.info;
      case 'Flats':
        return AppColors.secondary;
      case 'Visitors':
        return AppColors.success;
      case 'Settings':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  void _showActivityDetails(ActivityLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildActivityDetailsSheet(log),
    );
  }

  Widget _buildActivityDetailsSheet(ActivityLog log) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getActivityColor(log.type).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getActivityIcon(log.type),
                  color: _getActivityColor(log.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      log.category,
                      style: TextStyle(
                        color: _getCategoryColor(log.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          _buildDetailRow('Description', log.description),
          const Divider(height: 24),

          // Admin
          _buildDetailRow('Performed by', log.adminName),
          const Divider(height: 24),

          // Target
          _buildDetailRow('Target', log.targetName),
          const Divider(height: 24),

          // Time
          _buildDetailRow(
            'Time',
            DateFormat('MMMM d, yyyy at h:mm a').format(log.createdAt),
          ),

          // Metadata
          if (log.metadata != null && log.metadata!.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Additional Details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...log.metadata!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_formatMetadataKey(entry.key)}: ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('${entry.value}'),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
