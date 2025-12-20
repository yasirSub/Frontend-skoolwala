import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/inventory_service.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _issues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _inventoryService.getIssues();
      if (mounted) {
        setState(() {
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading issues: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardPrimary,
      appBar: CustomAppBar(
        title: 'Issues',
        primaryColor: AppTheme.dashboardPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: AppLoadingIndicator(color: AppTheme.dashboardAccentLight),
            )
          : _issues.isEmpty
          ? Center(
              child: Text(
                'No issues found',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _issues.length,
              itemBuilder: (context, index) {
                final issue = _issues[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning, color: Colors.orange),
                    ),
                    title: Text(
                      issue['product_name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issued To: ${issue['issued_to'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Date: ${issue['date'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'Qty: ${issue['quantity'] ?? '0'}',
                      style: const TextStyle(
                        color: AppTheme.dashboardAccentLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
