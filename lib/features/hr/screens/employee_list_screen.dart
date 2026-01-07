import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../services/employee_service.dart';
import '../models/employee.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  List<Map<String, dynamic>> _roles = [];
  String? _selectedRoleId;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Roles
      final rolesResponse = await ApiService.get('getEmployeeRoles');
      if (rolesResponse['status'] == 'success') {
        _roles = List<Map<String, dynamic>>.from(rolesResponse['data']);
        // Select the first role by default if available
        if (_roles.isNotEmpty) {
          _selectedRoleId = _roles.first['id'].toString();
        }
      }

      // 2. Fetch Employees (initially for the first role)
      await _loadEmployeesForRole(_selectedRoleId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEmployeesForRole(String? roleId) async {
    setState(() => _isLoading = true);
    try {
      final employees = await EmployeeService.getEmployeeList(roleId: roleId);
      if (mounted) {
        setState(() {
          _employees = employees;
          _filteredEmployees = employees;
          _isLoading = false;
        });
        // Re-apply search filter if any
        if (_searchController.text.isNotEmpty) {
          _filterEmployees();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onRoleSelected(String roleId) {
    if (_selectedRoleId != roleId) {
      setState(() {
        _selectedRoleId = roleId;
      });
      _loadEmployeesForRole(roleId);
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((emp) {
          final name = emp.name.toLowerCase();
          final role = emp.role.toLowerCase();
          final designation = emp.designation?.toLowerCase() ?? '';
          return name.contains(query) ||
              role.contains(query) ||
              designation.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Employee Directory'),
        backgroundColor: AppTheme.darkPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppTheme.darkPurple,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Role Tabs
          if (_roles.isNotEmpty)
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isSelected = role['id'].toString() == _selectedRoleId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(role['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _onRoleSelected(role['id'].toString());
                        }
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.orange
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Employee List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadEmployeesForRole(_selectedRoleId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredEmployees.isEmpty) {
      return const Center(child: Text('No employees found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: employee.photo != null
                          ? NetworkImage(employee.photo!)
                          : null,
                      child: employee.photo == null
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.badge,
                            'ID: ${employee.staffId ?? "N/A"}',
                          ),
                          _buildInfoRow(
                            Icons.work,
                            '${employee.designation ?? "N/A"} (${employee.department ?? "N/A"})',
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            employee.mobileNo ?? "N/A",
                          ),
                          _buildInfoRow(Icons.email, employee.email ?? "N/A"),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // View Action
                      },
                      icon: const Icon(
                        Icons.visibility,
                        size: 18,
                        color: Colors.blue,
                      ),
                      label: const Text(
                        'View',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Delete Action
                      },
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
