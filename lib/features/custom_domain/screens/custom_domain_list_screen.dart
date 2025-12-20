import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/custom_domain_service.dart';

class CustomDomainListScreen extends StatefulWidget {
  const CustomDomainListScreen({super.key});

  @override
  State<CustomDomainListScreen> createState() => _CustomDomainListScreenState();
}

class _CustomDomainListScreenState extends State<CustomDomainListScreen> {
  final CustomDomainService _customDomainService = CustomDomainService();
  List<dynamic> _domains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    try {
      final domains = await _customDomainService.getCustomDomains();
      if (mounted) {
        setState(() {
          _domains = domains;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading custom domains: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardPrimary,
      appBar: CustomAppBar(
        title: 'Custom Domains',
        primaryColor: AppTheme.dashboardPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: AppLoadingIndicator(color: AppTheme.dashboardAccentLight),
            )
          : _domains.isEmpty
          ? Center(
              child: Text(
                'No custom domains found',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _domains.length,
              itemBuilder: (context, index) {
                final domain = _domains[index];
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
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.language, color: Colors.blue),
                    ),
                    title: Text(
                      domain['url'] ?? 'Unknown URL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${domain['status'] == '1' ? 'Approved' : (domain['status'] == '2' ? 'Rejected' : 'Pending')}',
                          style: TextStyle(
                            color: domain['status'] == '1'
                                ? Colors.green
                                : (domain['status'] == '2'
                                      ? Colors.red
                                      : Colors.orange),
                          ),
                        ),
                        if (domain['comments'] != null &&
                            domain['comments'].toString().isNotEmpty)
                          Text(
                            'Comments: ${domain['comments']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
