import 'dart:collection';

/// LRU (Least Recently Used) Cache implementation
///
/// This service provides an efficient LRU cache that automatically evicts
/// least recently used items when the cache reaches its maximum capacity.
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache;
  int _hits = 0;
  int _misses = 0;

  /// Creates an LRU cache with the specified maximum size
  LRUCache(this.maxSize) : _cache = LinkedHashMap<K, V>();

  /// Resets hit/miss counters
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Gets the value associated with the key, or null if not found
  ///
  /// Accessing a value updates its position in the LRU order
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      _misses++;
      return null;
    }

    // Move to end (most recently used)
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
      _hits++;
      return value as V;
    }
    _misses++;
    return null;
  }

  /// Adds or updates a key-value pair in the cache
  ///
  /// If the cache exceeds its maximum size, the least recently used
  /// item will be automatically evicted
  void put(K key, V value) {
    // Remove if already exists to update position
    _cache.remove(key);
    
    // Add to end (most recently used)
    _cache[key] = value;
    
    // Evict least recently used if over capacity
    if (_cache.length > maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  /// Removes a key-value pair from the cache
  bool remove(K key) => _cache.remove(key) != null;

  /// Checks if the cache contains a key
  bool containsKey(K key) => _cache.containsKey(key);

  /// Gets the current size of the cache
  int get length => _cache.length;

  /// Clears all items from the cache
  void clear() => _cache.clear();

  /// Gets all keys in the cache (ordered from least to most recently used)
  Iterable<K> get keys => _cache.keys;

  /// Gets all values in the cache (ordered from least to most recently used)
  Iterable<V> get values => _cache.values;

  /// Gets cache statistics
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': maxSize,
        'hits': _hits,
        'misses': _misses,
        'hitRate': _cacheHitRate,
      };

  /// Calculates cache hit rate
  double get _cacheHitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;
}