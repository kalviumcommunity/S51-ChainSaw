import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _flatNumberController = TextEditingController();
  String _selectedRole = '';
  String _selectedBlock = 'A';

  final List<String> _blocks = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flatNumberController.dispose();
    super.dispose();
  }

  String get _fullFlatNumber => '$_selectedBlock-${_flatNumberController.text.trim()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us a bit about yourself',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < AppConstants.minNameLength) {
                      return 'Name must be at least ${AppConstants.minNameLength} characters';
                    }
                    if (value.length > AppConstants.maxNameLength) {
                      return 'Name must be less than ${AppConstants.maxNameLength} characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Role Selection
                const Text(
                  'Select your role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Role Cards
                _buildRoleCard(
                  role: AppConstants.roleGuard,
                  title: 'Guard',
                  description: 'Register visitors and manage entry/exit',
                  icon: Icons.security,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildRoleCard(
                  role: AppConstants.roleResident,
                  title: 'Resident',
                  description: 'Approve or deny visitor requests',
                  icon: Icons.home,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 12),
                _buildRoleCard(
                  role: AppConstants.roleAdmin,
                  title: 'Admin',
                  description: 'View all logs and manage the system',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                ),

                // Flat Number (only for residents)
                if (_selectedRole == AppConstants.roleResident) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Your Flat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Block Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBlock,
                          decoration: const InputDecoration(
                            labelText: 'Block',
                            prefixIcon: Icon(Icons.domain),
                          ),
                          items: _blocks.map((block) {
                            return DropdownMenuItem(
                              value: block,
                              child: Text('Block $block'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBlock = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Flat Number
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _flatNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Flat No.',
                            hintText: '101',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (value) {
                            if (_selectedRole == AppConstants.roleResident) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d+$').hasMatch(value)) {
                                return 'Numbers only';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preview
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Flat: $_fullFlatNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Error Message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Continue Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _completeRegistration(context),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withAlpha(25) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _completeRegistration(BuildContext context) async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeRegistration(
      name: _nameController.text.trim(),
      role: _selectedRole,
      flatNumber: _selectedRole == AppConstants.roleResident
          ? _fullFlatNumber
          : null,
    );

    if (!mounted) return;

    if (success) {
      _navigateToHome(context, _selectedRole);
    }
  }

  void _navigateToHome(BuildContext context, String role) {
    String route;
    switch (role) {
      case 'guard':
        route = AppRoutes.guardHome;
        break;
      case 'resident':
        route = AppRoutes.residentHome;
        break;
      case 'admin':
        route = AppRoutes.adminHome;
        break;
      default:
        route = AppRoutes.login;
    }
    Navigator.pushReplacementNamed(context, route);
  }
}