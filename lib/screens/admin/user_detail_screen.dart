import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late UserModel _user;
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _flatController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _user.name);
    _phoneController = TextEditingController(text: _user.phone ?? '');
    _emailController = TextEditingController(text: _user.email ?? '');
    _flatController = TextEditingController(text: _user.flatNumber ?? '');
    _selectedRole = _user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(_user.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'User Details'),
        backgroundColor: AppColors.adminColor,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit User',
            ),
          if (!_isEditing)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete User', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(roleColor),
                  const SizedBox(height: 24),

                  // User Info Section
                  _isEditing ? _buildEditForm() : _buildInfoSection(),
                  const SizedBox(height: 24),

                  // Auth Methods Section
                  if (!_isEditing) _buildAuthMethodsSection(),
                  if (!_isEditing) const SizedBox(height: 24),

                  // Activity Section
                  if (!_isEditing) _buildActivitySection(),

                  // Save/Cancel Buttons for Edit Mode
                  if (_isEditing) _buildEditActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: roleColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withAlpha(50)),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: roleColor.withAlpha(50),
            radius: 48,
            backgroundImage: _user.photoUrl != null ? NetworkImage(_user.photoUrl!) : null,
            child: _user.photoUrl == null
                ? Text(
                    _user.name.isNotEmpty ? _user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getRoleIcon(_user.role), color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _capitalizeFirst(_user.role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.phone,
            label: 'Phone',
            value: _user.phone ?? 'Not provided',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.email,
            label: 'Email',
            value: _user.email ?? 'Not provided',
          ),
          if (_user.role == AppConstants.roleResident) ...[
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.apartment,
              label: 'Flat Number',
              value: _user.flatNumber ?? 'Not assigned',
            ),
          ],
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.calendar_today,
            label: 'Joined',
            value: DateFormat('MMM d, yyyy').format(_user.createdAt),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.update,
            label: 'Last Updated',
            value: DateFormat('MMM d, yyyy - h:mm a').format(_user.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.adminColor.withAlpha(25),
        child: Icon(icon, color: AppColors.adminColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEditForm() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Phone Field
          TextField(
            controller: _phoneController,
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
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Flat Field (only for residents)
          if (_selectedRole == AppConstants.roleResident) ...[
            TextField(
              controller: _flatController,
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
            'Role',
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
                Icons.security,
                AppColors.guardColor,
              ),
              const SizedBox(width: 8),
              _buildRoleOption(
                'Resident',
                AppConstants.roleResident,
                Icons.home,
                AppColors.residentColor,
              ),
              const SizedBox(width: 8),
              _buildRoleOption(
                'Admin',
                AppConstants.roleAdmin,
                Icons.admin_panel_settings,
                AppColors.adminColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedRole == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = value;
          });
        },
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

  Widget _buildAuthMethodsSection() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Authentication Methods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _user.authMethods.map((method) {
              return Chip(
                avatar: Icon(
                  _getAuthIcon(method),
                  size: 18,
                  color: AppColors.adminColor,
                ),
                label: Text(AppConstants.authProviderNames[method] ?? method),
                backgroundColor: AppColors.adminColor.withAlpha(15),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem('Account Created', DateFormat('MMM d, yyyy').format(_user.createdAt)),
          _buildActivityItem('Last Updated', DateFormat('MMM d, yyyy').format(_user.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String action, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.adminColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _initControllers(); // Reset to original values
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final adminProvider = context.read<AdminProvider>();

    final success = await adminProvider.updateUserDetails(
      userId: _user.uid,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      flatNumber: _selectedRole == AppConstants.roleResident
          ? (_flatController.text.trim().isEmpty ? null : _flatController.text.trim())
          : null,
      role: _selectedRole,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Update local user data
      setState(() {
        _user = UserModel(
          uid: _user.uid,
          name: _nameController.text.trim(),
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          photoUrl: _user.photoUrl,
          flatNumber: _selectedRole == AppConstants.roleResident
              ? (_flatController.text.trim().isEmpty ? null : _flatController.text.trim())
              : null,
          authMethods: _user.authMethods,
          fcmToken: _user.fcmToken,
          createdAt: _user.createdAt,
          updatedAt: DateTime.now(),
        );
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.errorMessage ?? 'Failed to update user'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    if (action == 'delete') {
      _showDeleteConfirmation();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${_user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.deleteUser(_user.uid);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // Go back to user list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.errorMessage ?? 'Failed to delete user'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  IconData _getAuthIcon(String method) {
    switch (method) {
      case AppConstants.providerPhone:
        return Icons.phone;
      case AppConstants.providerEmail:
        return Icons.email;
      case AppConstants.providerGoogle:
        return Icons.g_mobiledata;
      default:
        return Icons.lock;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
