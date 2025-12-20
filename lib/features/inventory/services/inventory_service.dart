import '../../../shared/services/http_client.dart';

class InventoryService {
  final HttpClient _client = HttpClient();

  Future<List<dynamic>> getProducts() async {
    final response = await _client.post(
      'getInventoryProducts',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load products');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final response = await _client.post(
      'getInventoryCategories',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load categories');
    }
  }

  Future<List<dynamic>> getStores() async {
    final response = await _client.post(
      'getInventoryStores',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load stores');
    }
  }

  Future<List<dynamic>> getSuppliers() async {
    final response = await _client.post(
      'getInventorySuppliers',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load suppliers');
    }
  }

  Future<List<dynamic>> getUnits() async {
    final response = await _client.post('getInventoryUnits', requireAuth: true);
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load units');
    }
  }

  Future<List<dynamic>> getPurchases() async {
    final response = await _client.post(
      'getInventoryPurchases',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load purchases');
    }
  }

  Future<List<dynamic>> getSales() async {
    final response = await _client.post('getInventorySales', requireAuth: true);
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load sales');
    }
  }

  Future<List<dynamic>> getIssues() async {
    final response = await _client.post(
      'getInventoryIssues',
      requireAuth: true,
    );
    if (response['status'] == 'success') {
      return response['data'] as List<dynamic>;
    } else {
      throw Exception(response['message'] ?? 'Failed to load issues');
    }
  }
}
