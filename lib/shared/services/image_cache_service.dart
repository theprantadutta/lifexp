import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for intelligent image caching and optimization
class ImageCacheService {
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();
  static final ImageCacheService _instance = ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, String> _diskCacheMap = {};
  
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxDiskCacheSize = 200 * 1024 * 1024; // 200MB
  static const Duration _cacheExpiry = Duration(days: 7);
  
  int _currentMemoryCacheSize = 0;
  Directory? _cacheDirectory;
  bool _initialized = false;

  /// Initialize the image cache service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _cacheDirectory = await getTemporaryDirectory();
      _cacheDirectory = Directory('${_cacheDirectory!.path}/image_cache');
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
      
      await _cleanExpiredCache();
      _initialized = true;
      
      if (kDebugMode) {
        print('ImageCacheService: Initialized with cache directory: ${_cacheDirectory!.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Failed to initialize: $e');
      }
    }
  }

  /// Get optimized image widget
  Widget getOptimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
    BlendMode? colorBlendMode,
    String? semanticLabel,
    bool enableMemoryCache = true,
    FilterQuality filterQuality = FilterQuality.medium,
  }) => FutureBuilder<ImageProvider?>(
      future: _getOptimizedImageProvider(
        imagePath,
        width: width,
        height: height,
        enableMemoryCache: enableMemoryCache,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image(
            image: snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: colorBlendMode,
            semanticLabel: semanticLabel,
            filterQuality: filterQuality,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
          );
        } else if (snapshot.hasError) {
          return _buildErrorWidget(width, height);
        } else {
          return _buildLoadingWidget(width, height);
        }
      },
    );

  /// Get cached or optimized image provider
  Future<ImageProvider?> _getOptimizedImageProvider(
    String imagePath, {
    double? width,
    double? height,
    bool enableMemoryCache = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey(imagePath, width, height);
      
      // Check memory cache first
      if (enableMemoryCache && _memoryCache.containsKey(cacheKey)) {
        return MemoryImage(_memoryCache[cacheKey]!);
      }
      
      // Check disk cache
      final cachedFile = await _getCachedFile(cacheKey);
      if (cachedFile != null && await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        
        if (enableMemoryCache) {
          _addToMemoryCache(cacheKey, bytes);
        }
        
        return MemoryImage(bytes);
      }
      
      // Load and optimize original image
      final optimizedBytes = await _loadAndOptimizeImage(
        imagePath,
        width: width,
        height: height,
      );
      
      if (optimizedBytes != null) {
        // Cache the optimized image
        await _cacheToDisk(cacheKey, optimizedBytes);
        
        if (enableMemoryCache) {
          _addToMemoryCache(cacheKey, optimizedBytes);
        }
        
        return MemoryImage(optimizedBytes);
      }
      
      // Fallback to asset image
      return AssetImage(imagePath);
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Error loading image $imagePath: $e');
      }
      return AssetImage(imagePath);
    }
  }

  /// Load and optimize image
  Future<Uint8List?> _loadAndOptimizeImage(
    String imagePath, {
    double? width,
    double? height,
  }) async {
    try {
      // Load original image
      final data = await rootBundle.load(imagePath);
      final bytes = data.buffer.asUint8List();
      
      // If no resizing needed, return original
      if (width == null && height == null) {
        return bytes;
      }
      
      // Decode and resize image
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width?.round(),
        targetHeight: height?.round(),
      );
      
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      
      // Convert back to bytes
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      image.dispose();
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Error optimizing image $imagePath: $e');
      }
      return null;
    }
  }

  /// Generate cache key
  String _generateCacheKey(String imagePath, double? width, double? height) {
    final dimensions = '${width?.round() ?? 'auto'}x${height?.round() ?? 'auto'}';
    return '${imagePath.hashCode}_$dimensions';
  }

  /// Add image to memory cache
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Check if adding this image would exceed memory limit
    if (_currentMemoryCacheSize + bytes.length > _maxMemoryCacheSize) {
      _evictMemoryCache();
    }
    
    _memoryCache[key] = bytes;
    _currentMemoryCacheSize += bytes.length;
  }

  /// Evict least recently used items from memory cache
  void _evictMemoryCache() {
    // Simple eviction: remove half of the cache
    final keysToRemove = _memoryCache.keys.take(_memoryCache.length ~/ 2).toList();
    
    for (final key in keysToRemove) {
      final bytes = _memoryCache.remove(key);
      if (bytes != null) {
        _currentMemoryCacheSize -= bytes.length;
      }
    }
    
    if (kDebugMode) {
      print('ImageCacheService: Evicted ${keysToRemove.length} items from memory cache');
    }
  }

  /// Cache image to disk
  Future<void> _cacheToDisk(String key, Uint8List bytes) async {
    if (!_initialized || _cacheDirectory == null) return;
    
    try {
      final file = File('${_cacheDirectory!.path}/$key.cache');
      await file.writeAsBytes(bytes);
      _diskCacheMap[key] = file.path;
      
      // Check disk cache size and clean if necessary
      await _checkDiskCacheSize();
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Error caching to disk: $e');
      }
    }
  }

  /// Get cached file
  Future<File?> _getCachedFile(String key) async {
    if (!_initialized || _cacheDirectory == null) return null;
    
    final filePath = _diskCacheMap[key] ?? '${_cacheDirectory!.path}/$key.cache';
    final file = File(filePath);
    
    if (await file.exists()) {
      // Check if file is expired
      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > _cacheExpiry) {
        await file.delete();
        _diskCacheMap.remove(key);
        return null;
      }
      
      return file;
    }
    
    return null;
  }

  /// Check and manage disk cache size
  Future<void> _checkDiskCacheSize() async {
    if (!_initialized || _cacheDirectory == null) return;
    
    try {
      final files = await _cacheDirectory!.list().toList();
      var totalSize = 0;
      final fileStats = <FileSystemEntity, FileStat>{};
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          fileStats[file] = stat;
          totalSize += stat.size;
        }
      }
      
      if (totalSize > _maxDiskCacheSize) {
        // Sort files by last modified (oldest first)
        final sortedFiles = fileStats.entries.toList()
          ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
        
        // Remove oldest files until under limit
        var removedSize = 0;
        for (final entry in sortedFiles) {
          if (totalSize - removedSize <= _maxDiskCacheSize * 0.8) break;
          
          await entry.key.delete();
          removedSize += entry.value.size;
          
          // Remove from disk cache map
          final fileName = entry.key.path.split('/').last.replaceAll('.cache', '');
          _diskCacheMap.remove(fileName);
        }
        
        if (kDebugMode) {
          print('ImageCacheService: Cleaned ${removedSize ~/ 1024}KB from disk cache');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Error checking disk cache size: $e');
      }
    }
  }

  /// Clean expired cache files
  Future<void> _cleanExpiredCache() async {
    if (!_initialized || _cacheDirectory == null) return;
    
    try {
      final files = await _cacheDirectory!.list().toList();
      var cleanedCount = 0;
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified) > _cacheExpiry) {
            await file.delete();
            cleanedCount++;
            
            // Remove from disk cache map
            final fileName = file.path.split('/').last.replaceAll('.cache', '');
            _diskCacheMap.remove(fileName);
          }
        }
      }
      
      if (kDebugMode && cleanedCount > 0) {
        print('ImageCacheService: Cleaned $cleanedCount expired cache files');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ImageCacheService: Error cleaning expired cache: $e');
      }
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;
    
    // Clear disk cache
    if (_initialized && _cacheDirectory != null) {
      try {
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        _diskCacheMap.clear();
        
        if (kDebugMode) {
          print('ImageCacheService: Cleared all cache');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ImageCacheService: Error clearing cache: $e');
        }
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() => {
      'memoryCache': {
        'itemCount': _memoryCache.length,
        'sizeBytes': _currentMemoryCacheSize,
        'sizeMB': (_currentMemoryCacheSize / (1024 * 1024)).toStringAsFixed(2),
      },
      'diskCache': {
        'itemCount': _diskCacheMap.length,
        'directory': _cacheDirectory?.path ?? 'Not initialized',
      },
      'limits': {
        'maxMemoryMB': (_maxMemoryCacheSize / (1024 * 1024)).toStringAsFixed(0),
        'maxDiskMB': (_maxDiskCacheSize / (1024 * 1024)).toStringAsFixed(0),
        'expiryDays': _cacheExpiry.inDays,
      },
    };

  /// Build loading widget
  Widget _buildLoadingWidget(double? width, double? height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

  /// Build error widget
  Widget _buildErrorWidget(double? width, double? height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );

  /// Preload images
  Future<void> preloadImages(List<String> imagePaths, BuildContext context) async {
    for (final imagePath in imagePaths) {
      try {
        await precacheImage(AssetImage(imagePath), context);
      } catch (e) {
        if (kDebugMode) {
          print('ImageCacheService: Error preloading $imagePath: $e');
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.clear();
    _diskCacheMap.clear();
    _currentMemoryCacheSize = 0;
    _initialized = false;
  }
}