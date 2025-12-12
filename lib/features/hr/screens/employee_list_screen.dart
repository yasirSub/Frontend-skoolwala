import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await EmployeeService.getEmployeeList();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Branch ID mismatch')
              ? 'Session error. Please login again.'
              : 'Failed to load employees';
          _isLoading = false;
        });
      }
      print(e);
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
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
              onPressed: _loadEmployees,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return const Center(child: Text("No employees found."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by Name, Role, Designation...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEmployees,
            child: ListView.builder(
              itemCount: _filteredEmployees.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final employee = _filteredEmployees[index];
                return _buildEmployeeCard(employee);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: employee.photo != null && employee.photo!.isNotEmpty
              ? NetworkImage(employee.photo!)
              : null,
          child: (employee.photo == null || employee.photo!.isEmpty)
              ? Text(
                  employee.name.isNotEmpty
                      ? employee.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2C3E50),
                  ),
                )
              : null,
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    employee.role,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (employee.designation != null &&
                    employee.designation!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      employee.designation!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            if (employee.department != null &&
                employee.department!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Dept: ${employee.department}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            if (employee.mobileNo != null && employee.mobileNo!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    employee.mobileNo!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
