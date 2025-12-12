import '../models/menu_item.dart';
import '../services/http_client.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  List<MenuItem>? _cachedMenuItems;
  DateTime? _cacheTime;
  static const int _cacheDurationMinutes = 5;

  /// Fetch menu items from API based on user permissions
  Future<List<MenuItem>> fetchMenuItems({bool forceRefresh = false}) async {
    try {
      // Check cache first
      // Cache check disabled for debugging
      /*
      if (!forceRefresh &&
          _cachedMenuItems != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!).inMinutes < _cacheDurationMinutes) {
        print('📋 MenuService: Using cached menu items (${_cachedMenuItems!.length} items)');
        return _cachedMenuItems!;
      }
      */

      print('📋 MenuService: Fetching menu items from API');

      final response = await HttpClient().post(
        'getUserMenu',
        requireAuth: true,
      );

      print('📋 MenuService: API Response: ${response['status']}');
      print('📋 MenuService: Response message: ${response['message']}');

      if (response['status'] == 'success' && response['data'] != null) {
        final menuData = response['data'] as List<dynamic>? ?? [];
        print('📋 MenuService: Raw menu data count: ${menuData.length}');

        final menuItems = menuData
            .map(
              (item) => MenuItem.fromApiResponse(item as Map<String, dynamic>),
            )
            .toList();

        // Cache the results
        _cachedMenuItems = menuItems;
        _cacheTime = DateTime.now();

        print('✅ MenuService: Loaded ${menuItems.length} menu items');
        for (var item in menuItems) {
          print('   - ${item.id}: ${item.title} (${item.type})');
        }
        return menuItems;
      } else {
        print('❌ MenuService: API returned non-success status');
        throw Exception(response['message'] ?? 'Failed to fetch menu items');
      }
    } catch (e) {
      print('❌ MenuService: Error fetching menu items: $e');
      // Return cached items if available, otherwise return default menu
      if (_cachedMenuItems != null) {
        print(
          '📋 MenuService: Returning cached menu items due to error (${_cachedMenuItems!.length} items)',
        );
        return _cachedMenuItems!;
      }
      print('⚠️ MenuService: Returning default menu (3 items)');
      return _getDefaultMenuItems();
    }
  }

  /// Clear cached menu items
  void clearCache() {
    _cachedMenuItems = null;
    _cacheTime = null;
    print('📋 MenuService: Cache cleared');
  }

  /// Get default menu items if API fails
  List<MenuItem> _getDefaultMenuItems() {
    return [
      const MenuItem(
        id: 'dashboard',
        title: 'Dashboard',
        icon: 'dashboard',
        route: '/dashboard',
        type: 'item',
      ),
      const MenuItem(
        id: 'attendance',
        title: 'Attendance',
        icon: 'event_available',
        route: '/attendance',
        type: 'item',
      ),
      const MenuItem(
        id: 'profile',
        title: 'Profile',
        icon: 'person',
        route: '/profile',
        type: 'item',
      ),
    ];
  }
}
