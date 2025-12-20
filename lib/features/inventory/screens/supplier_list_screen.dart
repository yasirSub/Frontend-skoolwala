import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/inventory_service.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _inventoryService.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
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
        ).showSnackBar(SnackBar(content: Text('Error loading suppliers: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardPrimary,
      appBar: CustomAppBar(
        title: 'Suppliers',
        primaryColor: AppTheme.dashboardPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: AppLoadingIndicator(color: AppTheme.dashboardAccentLight),
            )
          : _suppliers.isEmpty
          ? Center(
              child: Text(
                'No suppliers found',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _suppliers.length,
              itemBuilder: (context, index) {
                final supplier = _suppliers[index];
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
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      supplier['name'] ?? 'Unknown Supplier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (supplier['mobileno'] != null)
                          Text(
                            'Mobile: ${supplier['mobileno']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        if (supplier['company_name'] != null)
                          Text(
                            'Company: ${supplier['company_name']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
