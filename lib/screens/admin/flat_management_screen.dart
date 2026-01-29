import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/flat_model.dart';
import 'add_edit_flat_screen.dart';

class FlatManagementScreen extends StatefulWidget {
  const FlatManagementScreen({super.key});

  @override
  State<FlatManagementScreen> createState() => _FlatManagementScreenState();
}

class _FlatManagementScreenState extends State<FlatManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBlock = 'All';
  String _selectedStatus = 'All'; // All, Occupied, Vacant

  // Mock data - will be replaced with provider in PR9
  final List<FlatModel> _mockFlats = [
    FlatModel(
      id: '1',
      flatNumber: '101',
      block: 'A',
      residentIds: ['user1', 'user2'],
      ownerName: 'John Doe',
      ownerPhone: '9876543210',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    FlatModel(
      id: '2',
      flatNumber: '102',
      block: 'A',
      residentIds: [],
      ownerName: null,
      ownerPhone: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    FlatModel(
      id: '3',
      flatNumber: '201',
      block: 'A',
      residentIds: ['user3'],
      ownerName: 'Jane Smith',
      ownerPhone: '9876543211',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    FlatModel(
      id: '4',
      flatNumber: '101',
      block: 'B',
      residentIds: ['user4'],
      ownerName: 'Bob Wilson',
      ownerPhone: '9876543212',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
    FlatModel(
      id: '5',
      flatNumber: '102',
      block: 'B',
      residentIds: [],
      ownerName: null,
      ownerPhone: null,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
  ];

  List<String> get _blocks => ['All', 'A', 'B', 'C', 'D'];

  List<FlatModel> get _filteredFlats {
    var flats = _mockFlats;

    // Filter by block
    if (_selectedBlock != 'All') {
      flats = flats.where((flat) => flat.block == _selectedBlock).toList();
    }

    // Filter by status
    if (_selectedStatus == 'Occupied') {
      flats = flats.where((flat) => flat.residentIds.isNotEmpty).toList();
    } else if (_selectedStatus == 'Vacant') {
      flats = flats.where((flat) => flat.residentIds.isEmpty).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      flats = flats.where((flat) =>
          flat.flatNumber.toLowerCase().contains(query) ||
          flat.block.toLowerCase().contains(query) ||
          (flat.ownerName?.toLowerCase().contains(query) ?? false)).toList();
    }

    return flats;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilter(),

        // Stats Summary
        _buildStatsSummary(),

        // Flat List
        Expanded(
          child: _buildFlatList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by flat number, block, or owner...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
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
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              // Block Filter
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Block',
                  value: _selectedBlock,
                  items: _blocks,
                  onChanged: (value) {
                    setState(() {
                      _selectedBlock = value ?? 'All';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Status',
                  value: _selectedStatus,
                  items: ['All', 'Occupied', 'Vacant'],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'All';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final totalFlats = _mockFlats.length;
    final occupiedFlats = _mockFlats.where((f) => f.residentIds.isNotEmpty).length;
    final vacantFlats = totalFlats - occupiedFlats;
    final filteredCount = _filteredFlats.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip('Total: $totalFlats', AppColors.primary),
          const SizedBox(width: 8),
          _buildStatChip('Occupied: $occupiedFlats', AppColors.success),
          const SizedBox(width: 8),
          _buildStatChip('Vacant: $vacantFlats', AppColors.warning),
          const Spacer(),
          Text(
            'Showing $filteredCount',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.adminColor),
            onPressed: _navigateToAddFlat,
            tooltip: 'Add Flat',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFlatList() {
    final flats = _filteredFlats;

    if (flats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No flats found',
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

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh from provider in PR9
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: flats.length,
        itemBuilder: (context, index) {
          return _buildFlatCard(flats[index]);
        },
      ),
    );
  }

  Widget _buildFlatCard(FlatModel flat) {
    final isOccupied = flat.residentIds.isNotEmpty;
    final statusColor = isOccupied ? AppColors.success : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditFlat(flat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flat Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    flat.block,
                    style: const TextStyle(
                      color: AppColors.adminColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Flat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${flat.block}-${flat.flatNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOccupied ? 'Occupied' : 'Vacant',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (flat.ownerName != null)
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            flat.ownerName!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${flat.residentCount} resident${flat.residentCount != 1 ? 's' : ''}',
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

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddFlat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditFlatScreen(),
      ),
    );
  }

  void _navigateToEditFlat(FlatModel flat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFlatScreen(flat: flat),
      ),
    );
  }
}
