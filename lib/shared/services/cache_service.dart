import 'dart:convert';
import 'persistent_storage.dart';

/// Generic caching service for API responses
/// Supports both in-memory and persistent caching
class CacheService {
  // In-memory cache with timestamps
  static final Map<String, _CacheEntry> _memoryCache = {};

  // Default cache durations (in minutes)
  static const int defaultTtlMinutes = 5;
  static const int shortTtlMinutes = 2;
  static const int longTtlMinutes = 30;

  /// Get cached data (memory first, then persistent)
  static Future<T?> get<T>({
    required String key,
    int ttlMinutes = defaultTtlMinutes,
    bool persistentOnly = false,
  }) async {
    // Check memory cache first (faster)
    if (!persistentOnly) {
      final memEntry = _memoryCache[key];
      if (memEntry != null && !memEntry.isExpired(ttlMinutes)) {
        print('📦 CacheService: Memory hit for $key');
        return memEntry.data as T?;
      }
    }

    // Check persistent cache
    try {
      final stored = await PersistentStorage.getString('cache_$key');
      if (stored != null) {
        final cacheData = json.decode(stored) as Map<String, dynamic>;
        final timestamp = DateTime.parse(cacheData['timestamp'] as String);
        final ageMinutes = DateTime.now().difference(timestamp).inMinutes;

        if (ageMinutes < ttlMinutes) {
          final data = cacheData['data'];
          // Refresh memory cache
          _memoryCache[key] = _CacheEntry(data: data, timestamp: timestamp);
          print(
            '📦 CacheService: Persistent hit for $key (age: ${ageMinutes}m)',
          );
          return data as T?;
        } else {
          print(
            '📦 CacheService: Persistent expired for $key (age: ${ageMinutes}m > ${ttlMinutes}m)',
          );
        }
      }
    } catch (e) {
      print('📦 CacheService: Error reading cache for $key: $e');
    }

    return null;
  }

  /// Store data in cache (both memory and persistent)
  static Future<void> set({
    required String key,
    required dynamic data,
    bool persistToStorage = true,
  }) async {
    final now = DateTime.now();

    // Store in memory
    _memoryCache[key] = _CacheEntry(data: data, timestamp: now);

    // Store persistently
    if (persistToStorage) {
      try {
        final cacheData = {'data': data, 'timestamp': now.toIso8601String()};
        await PersistentStorage.setString('cache_$key', json.encode(cacheData));
        print('📦 CacheService: Cached $key');
      } catch (e) {
        print('📦 CacheService: Error saving cache for $key: $e');
      }
    }
  }

  /// Remove specific cache entry
  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await PersistentStorage.remove('cache_$key');
    print('📦 CacheService: Removed cache for $key');
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    _memoryCache.clear();
    // Note: This doesn't clear persistent cache - would need to track all keys
    print('📦 CacheService: Cleared memory cache');
  }

  /// Clear cache entries matching a pattern
  static void clearPattern(String pattern) {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.contains(pattern))
        .toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }
    print(
      '📦 CacheService: Cleared ${keysToRemove.length} entries matching "$pattern"',
    );
  }

  /// Generate a cache key from parameters
  static String generateKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return '${prefix}_${sortedParams.entries.map((e) => '${e.key}=${e.value}').join('_')}';
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});

  bool isExpired(int ttlMinutes) {
    return DateTime.now().difference(timestamp).inMinutes >= ttlMinutes;
  }
}
