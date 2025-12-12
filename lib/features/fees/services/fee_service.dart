import '../../../shared/services/api_service.dart';
import '../models/fee_invoice.dart';

class FeeService {
  static Future<List<FeeInvoice>> getFeesInvoiceList({
    String? classId,
    String? sectionId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (classId != null) queryParams['class_id'] = classId;
      if (sectionId != null) queryParams['section_id'] = sectionId;

      final data = await ApiService.get(
        'getFeesInvoiceList',
        queryParams: queryParams,
      );

      if (data['status'] == 'success') {
        final List<dynamic> invoiceData = data['data'];
        return invoiceData.map((json) => FeeInvoice.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load invoices');
      }
    } catch (e) {
      throw Exception('Error fetching invoice list: $e');
    }
  }
}
