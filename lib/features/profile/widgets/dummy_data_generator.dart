// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:skoolwala/features/profile/services/dummy_data_service.dart';
import 'package:skoolwala/shared/services/api_service.dart';

class DummyDataGenerator extends StatefulWidget {
  final int staffId;
  final String staffName;

  const DummyDataGenerator({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<DummyDataGenerator> createState() => _DummyDataGeneratorState();
}

class _DummyDataGeneratorState extends State<DummyDataGenerator> {
  String _selectedType = 'today';
  String _selectedPattern = 'mixed';
  bool _isLoading = false;
  String? _lastResult;

  final List<Map<String, String>> _types = [
    {
      'value': 'today',
      'label': 'Today Only',
      'description': 'Generate attendance for today',
    },
    {
      'value': 'month',
      'label': 'Current Month',
      'description': 'Generate attendance for entire month',
    },
    {
      'value': 'year',
      'label': 'Current Year',
      'description': 'Generate attendance for entire year',
    },
  ];

  final List<Map<String, String>> _patterns = [
    {
      'value': 'mixed',
      'label': 'Mixed Pattern',
      'description': '85% Present, 10% Absent, 5% Late',
    },
    {
      'value': 'present',
      'label': 'Always Present',
      'description': 'Generate only present records',
    },
    {
      'value': 'absent',
      'label': 'Always Absent',
      'description': 'Generate only absent records',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.developer_mode,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Generate dummy attendance data for ${widget.staffName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Type Selection
          Text(
            'Select Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          ..._types.map(
            (type) => _buildRadioOption(
              value: type['value']!,
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              title: type['label']!,
              description: type['description']!,
            ),
          ),

          const SizedBox(height: 20),

          // Pattern Selection
          Text(
            'Select Attendance Pattern',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          ..._patterns.map(
            (pattern) => _buildRadioOption(
              value: pattern['value']!,
              groupValue: _selectedPattern,
              onChanged: (value) => setState(() => _selectedPattern = value!),
              title: pattern['label']!,
              description: pattern['description']!,
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(_isLoading ? 'Generating...' : 'Generate Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteData,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Debug Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                print('🔧 Debug button pressed!');
                print('🔧 Staff ID: ${widget.staffId}');
                print('🔧 Staff Name: ${widget.staffName}');
                print('🔧 Selected Type: $_selectedType');
                print('🔧 Selected Pattern: $_selectedPattern');
                print('🔧 Loading State: $_isLoading');
                print('🔧 API URL: ${ApiService.currentApiUrl}');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Debug: Staff ID ${widget.staffId}, Type: $_selectedType, Pattern: $_selectedPattern',
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Result Display
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastResult!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Warning
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This feature is only available in development mode',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String title,
    required String description,
  }) {
    final isSelected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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

  Future<void> _generateData() async {
    print('🔘 Generate Data button pressed!');
    print('🔘 Current loading state: $_isLoading');

    if (_isLoading) {
      print('⚠️ Already loading, ignoring button press');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    print('🔘 Loading state set to true');

    // Show detailed loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Generating $_selectedType attendance data...'),
            const SizedBox(height: 8),
            Text(
              'Pattern: $_selectedPattern',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'API: ${ApiService.currentApiUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Staff ID: ${widget.staffId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      print('🚀 Starting dummy data generation');
      print('📊 Staff ID: ${widget.staffId}');
      print('📊 Staff Name: ${widget.staffName}');
      print('📊 Type: $_selectedType');
      print('📊 Pattern: $_selectedPattern');
      print('🌐 API URL: ${ApiService.currentApiUrl}');

      // Test API connection first
      print('🔍 Testing API connection...');
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception(
          'API connection failed. Please check your network connection and backend server.',
        );
      }
      print('✅ API connection test passed');

      // Generate the data
      print('📝 Calling generateDummyData API...');
      final result = await DummyDataService.generateDummyData(
        staffId: widget.staffId,
        type: _selectedType,
        pattern: _selectedPattern,
      );

      print('✅ Generation result: $result');

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['status'] == 'success') {
        setState(() {
          _lastResult = result['message'];
        });

        // Show detailed success dialog
        _showDetailedResult('Generate Data', result);

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to generate data');
      }
    } catch (e) {
      print('❌ Generation error: $e');

      // Close loading dialog
      Navigator.of(context).pop();

      setState(() {
        _lastResult = 'Error: $e';
      });

      // Show detailed error dialog
      _showDetailedError('Generate Data', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🔘 Loading state set to false');
    }
  }

  Future<void> _deleteData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete all $_selectedType attendance data for ${widget.staffName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await DummyDataService.deleteAttendanceData(
        staffId: widget.staffId,
        type: _selectedType,
      );

      if (result['status'] == 'success') {
        setState(() {
          _lastResult = result['message'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to delete data');
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDetailedResult(String operation, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation - Success'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ ${result['message'] ?? 'Operation completed successfully'}',
              ),
              if (result['generated_count'] != null) ...[
                const SizedBox(height: 8),
                Text('📊 Generated: ${result['generated_count']} records'),
              ],
              if (result['type'] != null) ...[
                const SizedBox(height: 4),
                Text('📅 Type: ${result['type']}'),
              ],
              if (result['pattern'] != null) ...[
                const SizedBox(height: 4),
                Text('🎯 Pattern: ${result['pattern']}'),
              ],
              if (result['staff_name'] != null) ...[
                const SizedBox(height: 4),
                Text('👤 Staff: ${result['staff_name']}'),
              ],
              const SizedBox(height: 12),
              const Text(
                '🔍 Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDetailedError(String operation, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation - Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ ${error.toString()}'),
              const SizedBox(height: 12),
              const Text(
                '🔍 Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API URL: ${ApiService.currentApiUrl}'),
                    Text('Staff ID: ${widget.staffId}'),
                    Text('Staff Name: ${widget.staffName}'),
                    Text('Type: $_selectedType'),
                    Text('Pattern: $_selectedPattern'),
                    Text('Error Type: ${error.runtimeType}'),
                    Text('Timestamp: ${DateTime.now().toIso8601String()}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
