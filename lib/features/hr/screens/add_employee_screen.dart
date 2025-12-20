import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/services/api_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _joiningDateController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();

  // Dropdown values
  String? _selectedDesignation;
  String? _selectedDepartment;
  String? _selectedRole;

  // Data lists
  List<Map<String, String>> _designations = [];
  List<Map<String, String>> _departments = [];
  List<Map<String, String>> _roles = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiService.get('getDesignationList'),
        ApiService.get('getDepartmentList'),
        ApiService.get('getEmployeeRoles'),
      ]);

      if (mounted) {
        setState(() {
          final designationsData = responses[0];
          if (designationsData['status'] == 'success') {
            _designations = (designationsData['data'] as List)
                .map(
                  (e) => {
                    'id': e['id'].toString(),
                    'name': e['name'].toString(),
                  },
                )
                .toList();
          }

          final departmentsData = responses[1];
          if (departmentsData['status'] == 'success') {
            _departments = (departmentsData['data'] as List)
                .map(
                  (e) => {
                    'id': e['id'].toString(),
                    'name': e['name'].toString(),
                  },
                )
                .toList();
          }

          final rolesData = responses[2];
          if (rolesData['status'] == 'success') {
            _roles = (rolesData['data'] as List)
                .map(
                  (e) => {
                    'id': e['id'].toString(),
                    'name': e['name'].toString(),
                  },
                )
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _joiningDateController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee added successfully (Demo)')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile No',
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter mobile number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Role',
                      value: _selectedRole,
                      items: _roles,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select role' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Designation',
                      value: _selectedDesignation,
                      items: _designations,
                      onChanged: (value) {
                        setState(() {
                          _selectedDesignation = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select designation' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Department',
                      value: _selectedDepartment,
                      items: _departments,
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select department' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _joiningDateController,
                      label: 'Joining Date',
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _joiningDateController.text =
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        }
                      },
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please select joining date'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _qualificationController,
                      label: 'Qualification',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Present Address',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Login Details'),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _retypePasswordController,
                      label: 'Retype Password',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please retype password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Social Links'),
                    _buildTextField(
                      controller: _facebookController,
                      label: 'Facebook URL',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _twitterController,
                      label: 'Twitter URL',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _linkedinController,
                      label: 'Linkedin URL',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Employee'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      obscureText: obscureText,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'],
          child: Text(item['name']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
