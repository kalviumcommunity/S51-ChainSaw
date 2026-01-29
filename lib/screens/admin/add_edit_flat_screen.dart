import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/flat_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class AddEditFlatScreen extends StatefulWidget {
  final FlatModel? flat;

  const AddEditFlatScreen({super.key, this.flat});

  bool get isEditing => flat != null;

  @override
  State<AddEditFlatScreen> createState() => _AddEditFlatScreenState();
}

class _AddEditFlatScreenState extends State<AddEditFlatScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _flatNumberController;
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;
  late String _selectedBlock;

  // Available blocks
  final List<String> _blocks = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _flatNumberController = TextEditingController(text: widget.flat?.flatNumber ?? '');
    _ownerNameController = TextEditingController(text: widget.flat?.ownerName ?? '');
    _ownerPhoneController = TextEditingController(text: widget.flat?.ownerPhone ?? '');
    _selectedBlock = widget.flat?.block ?? 'A';
  }

  @override
  void dispose() {
    _flatNumberController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Flat' : 'Add Flat'),
        backgroundColor: AppColors.adminColor,
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete Flat',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flat Info Section
                    _buildSectionHeader('Flat Information'),
                    const SizedBox(height: 16),
                    _buildFlatInfoSection(),
                    const SizedBox(height: 24),

                    // Owner Info Section
                    _buildSectionHeader('Owner Information (Optional)'),
                    const SizedBox(height: 16),
                    _buildOwnerInfoSection(),
                    const SizedBox(height: 24),

                    // Residents Section (only for editing)
                    if (widget.isEditing) ...[
                      _buildSectionHeader('Residents'),
                      const SizedBox(height: 16),
                      _buildResidentsSection(),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.adminColor,
      ),
    );
  }

  Widget _buildFlatInfoSection() {
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
          // Block Selection
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Block',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBlock,
                          isExpanded: true,
                          items: _blocks.map((block) {
                            return DropdownMenuItem<String>(
                              value: block,
                              child: Text('Block $block'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBlock = value ?? 'A';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Flat Number
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _flatNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Flat Number',
                    hintText: 'e.g., 101, 202',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter flat number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.adminColor.withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apartment, color: AppColors.adminColor),
                const SizedBox(width: 8),
                Text(
                  'Preview: $_selectedBlock-${_flatNumberController.text.isEmpty ? '___' : _flatNumberController.text}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoSection() {
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
          // Owner Name
          TextFormField(
            controller: _ownerNameController,
            decoration: const InputDecoration(
              labelText: 'Owner Name',
              hintText: 'Enter owner\'s full name',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Owner Phone
          TextFormField(
            controller: _ownerPhoneController,
            decoration: const InputDecoration(
              labelText: 'Owner Phone',
              hintText: 'Enter 10-digit phone number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResidentsSection() {
    final residents = widget.flat?.residentIds ?? [];

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${residents.length} Resident${residents.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddResidentDialog(adminProvider),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adminColor,
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (residents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No residents assigned',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: residents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final residentId = residents[index];
                    final user = adminProvider.getUserById(residentId);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.residentColor.withAlpha(25),
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.residentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(user?.name ?? 'Unknown User'),
                      subtitle: Text(
                        user?.phone ?? residentId,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                        onPressed: () => _removeResident(adminProvider, residentId),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveFlat,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.isEditing ? 'Save Changes' : 'Create Flat',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveFlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final adminProvider = context.read<AdminProvider>();
    bool success;

    if (widget.isEditing) {
      success = await adminProvider.updateFlat(
        flatId: widget.flat!.id,
        flatNumber: _flatNumberController.text.trim(),
        block: _selectedBlock,
        ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim().isEmpty ? null : _ownerPhoneController.text.trim(),
      );
    } else {
      success = await adminProvider.createFlat(
        flatNumber: _flatNumberController.text.trim(),
        block: _selectedBlock,
        ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim().isEmpty ? null : _ownerPhoneController.text.trim(),
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Flat updated successfully' : 'Flat created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.errorMessage ?? 'Failed to save flat'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flat'),
        content: Text(
          'Are you sure you want to delete ${widget.flat?.block}-${widget.flat?.flatNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteFlat();
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

  Future<void> _deleteFlat() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.deleteFlat(widget.flat!.id);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flat deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.errorMessage ?? 'Failed to delete flat'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddResidentDialog(AdminProvider adminProvider) {
    final searchController = TextEditingController();
    List<UserModel> searchResults = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Resident'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchResults = adminProvider.searchUsersForAssignment(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (searchController.text.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Type to search for residents',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (searchResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No residents found',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final isAlreadyAdded = widget.flat?.residentIds.contains(user.uid) ?? false;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.residentColor.withAlpha(25),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.residentColor),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.phone ?? ''),
                            trailing: isAlreadyAdded
                                ? const Icon(Icons.check, color: AppColors.success)
                                : IconButton(
                                    icon: const Icon(Icons.add_circle, color: AppColors.adminColor),
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _addResident(adminProvider, user.uid);
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addResident(AdminProvider adminProvider, String residentId) async {
    if (widget.flat == null) return;

    setState(() {
      _isLoading = true;
    });

    final success = await adminProvider.addResidentToFlat(widget.flat!.id, residentId);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resident added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh the flat data
      adminProvider.loadAllFlats();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.errorMessage ?? 'Failed to add resident'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeResident(AdminProvider adminProvider, String residentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Resident'),
        content: const Text('Are you sure you want to remove this resident from the flat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              setState(() {
                _isLoading = true;
              });

              final success = await adminProvider.removeResidentFromFlat(
                widget.flat!.id,
                residentId,
              );

              setState(() {
                _isLoading = false;
              });

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resident removed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                adminProvider.loadAllFlats();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(adminProvider.errorMessage ?? 'Failed to remove resident'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
