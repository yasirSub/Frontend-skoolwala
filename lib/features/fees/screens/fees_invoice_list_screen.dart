import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../services/fee_service.dart';
import '../models/fee_invoice.dart';

class FeesInvoiceListScreen extends StatefulWidget {
  const FeesInvoiceListScreen({super.key});

  @override
  State<FeesInvoiceListScreen> createState() => _FeesInvoiceListScreenState();
}

class _FeesInvoiceListScreenState extends State<FeesInvoiceListScreen> {
  List<FeeInvoice> _invoices = [];
  List<FeeInvoice> _filteredInvoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchController.addListener(_filterInvoices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invoices = await FeeService.getFeesInvoiceList();
      setState(() {
        _invoices = invoices;
        _filteredInvoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Branch ID mismatch')
              ? 'Session error. Please login again.'
              : 'Failed to load invoices';
          _isLoading = false;
        });
      }
      print(e);
    }
  }

  void _filterInvoices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = _invoices;
      } else {
        _filteredInvoices = _invoices.where((inv) {
          final text = '${inv.studentName} ${inv.registerNo} ${inv.className}'
              .toLowerCase();
          return text.contains(query);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'total':
      case 'paid':
        return Colors.green;
      case 'partly':
        return Colors.blue;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'total':
        return 'PAID';
      case 'partly':
        return 'PARTIAL';
      case 'unpaid':
        return 'UNPAID';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Fees Invoice List'),
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
              onPressed: _loadInvoices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_invoices.isEmpty) {
      return const Center(child: Text("No invoices found."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Student, Reg No...',
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
            onRefresh: _loadInvoices,
            child: ListView.builder(
              itemCount: _filteredInvoices.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final invoice = _filteredInvoices[index];
                return _buildInvoiceCard(invoice);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(FeeInvoice invoice) {
    final statusColor = _getStatusColor(invoice.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      invoice.photo != null && invoice.photo!.isNotEmpty
                      ? NetworkImage(invoice.photo!)
                      : null,
                  child: (invoice.photo == null || invoice.photo!.isEmpty)
                      ? Text(
                          invoice.studentName.isNotEmpty
                              ? invoice.studentName
                                    .substring(0, 1)
                                    .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2C3E50),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class: ${invoice.className} (${invoice.sectionName})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        'Reg: ${invoice.registerNo}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    _getStatusText(invoice.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (invoice.feeGroups.isNotEmpty) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  invoice.feeGroups,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[800], fontSize: 12),
                ),
              ),
            ],
            // Action buttons could go here (Collect, Email)
          ],
        ),
      ),
    );
  }
}
