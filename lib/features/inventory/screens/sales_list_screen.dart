import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/inventory_service.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final sales = await _inventoryService.getSales();
      if (mounted) {
        setState(() {
          _sales = sales;
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
        ).showSnackBar(SnackBar(content: Text('Error loading sales: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardPrimary,
      appBar: CustomAppBar(
        title: 'Sales',
        primaryColor: AppTheme.dashboardPrimary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: AppLoadingIndicator(color: AppTheme.dashboardAccentLight),
            )
          : _sales.isEmpty
          ? Center(
              child: Text(
                'No sales found',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
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
                      child: const Icon(Icons.sell, color: Colors.green),
                    ),
                    title: Text(
                      sale['product_name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill No: ${sale['bill_no'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Date: ${sale['date'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'Qty: ${sale['quantity'] ?? '0'}',
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
