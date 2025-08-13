import 'dart:async';
import 'package:flutter/material.dart';

/// Service for implementing lazy loading of large data sets
class LazyLoadingService<T> {

  LazyLoadingService({
    required Future<List<T>> Function(int offset, int limit) dataLoader,
    int pageSize = 20,
    int preloadThreshold = 5,
  }) : _dataLoader = dataLoader,
       _pageSize = pageSize,
       _preloadThreshold = preloadThreshold;
  final Future<List<T>> Function(int offset, int limit) _dataLoader;
  final int _pageSize;
  final int _preloadThreshold;
  
  final List<T> _items = [];
  final Set<int> _loadingPages = {};
  final StreamController<LazyLoadingState<T>> _stateController = 
      StreamController<LazyLoadingState<T>>.broadcast();
  
  bool _hasMoreData = true;
  bool _isInitialLoading = false;
  String? _error;
  int _currentPage = 0;

  /// Current state stream
  Stream<LazyLoadingState<T>> get stateStream => _stateController.stream;
  
  /// Current items
  List<T> get items => List.unmodifiable(_items);
  
  /// Whether there's more data to load
  bool get hasMoreData => _hasMoreData;
  
  /// Whether initial loading is in progress
  bool get isInitialLoading => _isInitialLoading;
  
  /// Current error message
  String? get error => _error;
  
  /// Total number of loaded items
  int get itemCount => _items.length;

  /// Initialize and load first page
  Future<void> initialize() async {
    if (_isInitialLoading) return;
    
    _isInitialLoading = true;
    _error = null;
    _emitState();
    
    try {
      await _loadPage(0);
      _isInitialLoading = false;
      _emitState();
    } catch (e) {
      _isInitialLoading = false;
      _error = e.toString();
      _emitState();
    }
  }

  /// Load more data
  Future<void> loadMore() async {
    if (!_hasMoreData || _loadingPages.contains(_currentPage + 1)) return;
    
    await _loadPage(_currentPage + 1);
  }

  /// Refresh all data
  Future<void> refresh() async {
    _items.clear();
    _loadingPages.clear();
    _hasMoreData = true;
    _currentPage = 0;
    _error = null;
    
    await initialize();
  }

  /// Load specific page
  Future<void> _loadPage(int page) async {
    if (_loadingPages.contains(page)) return;
    
    _loadingPages.add(page);
    _emitState();
    
    try {
      final offset = page * _pageSize;
      final newItems = await _dataLoader(offset, _pageSize);
      
      if (newItems.isEmpty) {
        _hasMoreData = false;
      } else {
        if (page == 0) {
          _items.clear();
        }
        
        // Insert items at correct position
        final insertIndex = page * _pageSize;
        if (insertIndex <= _items.length) {
          _items.insertAll(insertIndex, newItems);
        } else {
          _items.addAll(newItems);
        }
        
        _currentPage = page;
        
        if (newItems.length < _pageSize) {
          _hasMoreData = false;
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingPages.remove(page);
      _emitState();
    }
  }

  /// Check if should preload more data
  void checkPreload(int currentIndex) {
    if (_hasMoreData && 
        currentIndex >= _items.length - _preloadThreshold &&
        !_loadingPages.contains(_currentPage + 1)) {
      loadMore();
    }
  }

  /// Emit current state
  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(LazyLoadingState<T>(
        items: items,
        isLoading: _loadingPages.isNotEmpty,
        isInitialLoading: _isInitialLoading,
        hasMoreData: _hasMoreData,
        error: _error,
      ));
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    _items.clear();
    _loadingPages.clear();
  }
}

/// State class for lazy loading
class LazyLoadingState<T> {

  const LazyLoadingState({
    required this.items,
    required this.isLoading,
    required this.isInitialLoading,
    required this.hasMoreData,
    this.error,
  });
  final List<T> items;
  final bool isLoading;
  final bool isInitialLoading;
  final bool hasMoreData;
  final String? error;

  bool get hasError => error != null;
  bool get isEmpty => items.isEmpty && !isInitialLoading;
}

/// Widget for lazy loading lists
class LazyLoadingListView<T> extends StatefulWidget {

  const LazyLoadingListView({
    required this.service, required this.itemBuilder, super.key,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
  });
  final LazyLoadingService<T> service;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Initialize service if not already done
    if (widget.service.itemCount == 0 && !widget.service.isInitialLoading) {
      widget.service.initialize();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      widget.service.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<LazyLoadingState<T>>(
      stream: widget.service.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        
        if (state == null) {
          return _buildLoading();
        }
        
        if (state.hasError && state.isEmpty) {
          return _buildError(state.error!);
        }
        
        if (state.isEmpty) {
          return _buildEmpty();
        }
        
        return RefreshIndicator(
          onRefresh: widget.service.refresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            shrinkWrap: widget.shrinkWrap,
            itemCount: state.items.length + (state.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              // Check for preloading
              widget.service.checkPreload(index);
              
              if (index < state.items.length) {
                return widget.itemBuilder(context, state.items[index], index);
              } else {
                // Loading indicator at the end
                return _buildLoadingIndicator();
              }
            },
          ),
        );
      },
    );

  Widget _buildLoading() => widget.loadingBuilder?.call(context) ?? 
        const Center(child: CircularProgressIndicator());

  Widget _buildError(String error) => widget.errorBuilder?.call(context, error) ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.service.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );

  Widget _buildEmpty() => widget.emptyBuilder?.call(context) ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );

  Widget _buildLoadingIndicator() => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
}

/// Widget for lazy loading grids
class LazyLoadingGridView<T> extends StatefulWidget {

  const LazyLoadingGridView({
    required this.service, required this.itemBuilder, required this.gridDelegate, super.key,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
  });
  final LazyLoadingService<T> service;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;

  @override
  State<LazyLoadingGridView<T>> createState() => _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    if (widget.service.itemCount == 0 && !widget.service.isInitialLoading) {
      widget.service.initialize();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      widget.service.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<LazyLoadingState<T>>(
      stream: widget.service.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        
        if (state == null) {
          return _buildLoading();
        }
        
        if (state.hasError && state.isEmpty) {
          return _buildError(state.error!);
        }
        
        if (state.isEmpty) {
          return _buildEmpty();
        }
        
        return RefreshIndicator(
          onRefresh: widget.service.refresh,
          child: GridView.builder(
            controller: _scrollController,
            padding: widget.padding,
            shrinkWrap: widget.shrinkWrap,
            gridDelegate: widget.gridDelegate,
            itemCount: state.items.length + (state.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              widget.service.checkPreload(index);
              
              if (index < state.items.length) {
                return widget.itemBuilder(context, state.items[index], index);
              } else {
                return _buildLoadingIndicator();
              }
            },
          ),
        );
      },
    );

  Widget _buildLoading() => widget.loadingBuilder?.call(context) ?? 
        const Center(child: CircularProgressIndicator());

  Widget _buildError(String error) => widget.errorBuilder?.call(context, error) ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.service.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );

  Widget _buildEmpty() => widget.emptyBuilder?.call(context) ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );

  Widget _buildLoadingIndicator() => const Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ),
    );
}