import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilter(adminProvider),

            // User Count Summary
            _buildUserCountSummary(adminProvider),

            // User List
            Expanded(
              child: adminProvider.isLoading && adminProvider.allUsers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserList(adminProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(AdminProvider adminProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        adminProvider.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              adminProvider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', adminProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Guard', adminProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Resident', adminProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Admin', adminProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AdminProvider adminProvider) {
    final isSelected = adminProvider.roleFilter == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        adminProvider.setRoleFilter(label);
      },
      selectedColor: AppColors.adminColor.withAlpha(50),
      checkmarkColor: AppColors.adminColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCountSummary(AdminProvider adminProvider) {
    final filteredCount = adminProvider.filteredUsers.length;
    final totalCount = adminProvider.allUsers.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Showing $filteredCount of $totalCount users',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add User'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.adminColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(AdminProvider adminProvider) {
    final users = adminProvider.filteredUsers;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
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
      onRefresh: () => adminProvider.loadAllUsers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToUserDetail(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: roleColor.withAlpha(50),
                radius: 28,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 12, color: roleColor),
                              const SizedBox(width: 4),
                              Text(
                                _capitalizeFirst(user.role),
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          user.phone ?? 'No phone',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (user.flatNumber != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.apartment, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Flat ${user.flatNumber}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleGuard:
        return AppColors.guardColor;
      case AppConstants.roleResident:
        return AppColors.residentColor;
      case AppConstants.roleAdmin:
        return AppColors.adminColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case AppConstants.roleGuard:
        return Icons.security;
      case AppConstants.roleResident:
        return Icons.home;
      case AppConstants.roleAdmin:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _navigateToUserDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(user: user),
      ),
    );
  }

  void _showAddUserDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddUserSheet(),
    );
  }

  Widget _buildAddUserSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final flatController = TextEditingController();
    String selectedRole = AppConstants.roleResident;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 8),

              // Email Field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Flat Number Field (only for residents)
              if (selectedRole == AppConstants.roleResident) ...[
                TextField(
                  controller: flatController,
                  decoration: const InputDecoration(
                    labelText: 'Flat Number',
                    prefixIcon: Icon(Icons.apartment),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
              ],

              // Role Selection
              const Text(
                'Select Role',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRoleOption(
                    'Guard',
                    AppConstants.roleGuard,
                    selectedRole,
                    Icons.security,
                    AppColors.guardColor,
                    (role) => setSheetState(() => selectedRole = role),
                  ),
                  const SizedBox(width: 8),
                  _buildRoleOption(
                    'Resident',
                    AppConstants.roleResident,
                    selectedRole,
                    Icons.home,
                    AppColors.residentColor,
                    (role) => setSheetState(() => selectedRole = role),
                  ),
                  const SizedBox(width: 8),
                  _buildRoleOption(
                    'Admin',
                    AppConstants.roleAdmin,
                    selectedRole,
                    Icons.admin_panel_settings,
                    AppColors.adminColor,
                    (role) => setSheetState(() => selectedRole = role),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in name and phone number'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    // Note: Creating users requires Firebase Auth
                    // This is a placeholder - full user creation would need admin SDK
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User creation requires admin SDK - feature coming soon'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add User'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(
    String label,
    String value,
    String selectedValue,
    IconData icon,
    Color color,
    Function(String) onSelect,
  ) {
    final isSelected = selectedValue == value;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
