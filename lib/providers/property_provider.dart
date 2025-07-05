import 'package:flutter/material.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/models/property.dart';

enum PropertyLoadingState {
  idle,
  loading,
  loaded,
  error,
  searchLoading,
  searchLoaded,
  searchError,
}

class PropertyProvider extends ChangeNotifier {
  // Properties list state
  List<Property> _properties = [];
  List<Property> _searchResults = [];
  List<Property> _featuredProperties = [];
  
  // Loading states
  PropertyLoadingState _state = PropertyLoadingState.idle;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProperties = 0;
  final int _pageSize = 20;
  
  // Search state
  String _currentSearchQuery = '';
  bool _isSearchMode = false;
  
  // Error handling
  String? _error;
  
  // Filters
  Map<String, dynamic> _filters = {};
  String? _sortBy;
  String? _sortOrder;

  // Getters
  List<Property> get properties => _properties;
  List<Property> get searchResults => _searchResults;
  List<Property> get featuredProperties => _featuredProperties;
  List<Property> get displayProperties => _isSearchMode ? _searchResults : _properties;
  
  PropertyLoadingState get state => _state;
  bool get isLoading => _state == PropertyLoadingState.loading || _state == PropertyLoadingState.searchLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _state == PropertyLoadingState.error || _state == PropertyLoadingState.searchError;
  bool get hasData => _properties.isNotEmpty || _searchResults.isNotEmpty;
  bool get hasNextPage => _hasNextPage;
  bool get isSearchMode => _isSearchMode;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalProperties => _totalProperties;
  String get currentSearchQuery => _currentSearchQuery;
  String? get error => _error;
  Map<String, dynamic> get filters => Map.from(_filters);

  // Initialize and load properties
  Future<void> initialize() async {
    await loadProperties();
    await loadFeaturedProperties();
  }

  // Load properties (first page)
  Future<void> loadProperties({bool refresh = false}) async {
    if (refresh || _properties.isEmpty) {
      _currentPage = 1;
      _properties.clear();
    }

    _setState(PropertyLoadingState.loading);
    _clearError();

    try {
      final result = await PropertyService.getProperties(
        page: _currentPage,
        limit: _pageSize,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _filters,
      );

      if (result['success']) {
        final List<Property> newProperties = result['properties'] ?? [];
        
        if (_currentPage == 1) {
          _properties = newProperties;
        } else {
          _properties.addAll(newProperties);
        }
        
        _totalPages = result['totalPages'] ?? 1;
        _totalProperties = result['total'] ?? 0;
        _hasNextPage = result['hasNextPage'] ?? false;
        
        _setState(PropertyLoadingState.loaded);
      } else {
        _setError(result['message'] ?? 'Failed to load properties');
        _setState(PropertyLoadingState.error);
      }
    } catch (e) {
      _setError('Error loading properties: ${e.toString()}');
      _setState(PropertyLoadingState.error);
    }
  }

  // Load more properties (pagination)
  Future<void> loadMoreProperties() async {
    if (_isLoadingMore || !_hasNextPage || _state == PropertyLoadingState.loading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await PropertyService.getProperties(
        page: nextPage,
        limit: _pageSize,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _filters,
      );

      if (result['success']) {
        final List<Property> newProperties = result['properties'] ?? [];
        _properties.addAll(newProperties);
        _currentPage = nextPage;
        _hasNextPage = result['hasNextPage'] ?? false;
      } else {
        _setError(result['message'] ?? 'Failed to load more properties');
      }
    } catch (e) {
      _setError('Error loading more properties: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Search properties
  Future<void> searchProperties(String query, {bool newSearch = true}) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    if (newSearch) {
      _currentPage = 1;
      _searchResults.clear();
      _currentSearchQuery = query.trim();
      _isSearchMode = true;
    }

    _setState(PropertyLoadingState.searchLoading);
    _clearError();

    try {
      final result = await PropertyService.searchProperties(
        searchString: query.trim(),
        page: _currentPage,
        limit: _pageSize,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _filters,
      );

      if (result['success']) {
        final List<Property> searchProperties = result['properties'] ?? [];
        
        if (_currentPage == 1) {
          _searchResults = searchProperties;
        } else {
          _searchResults.addAll(searchProperties);
        }
        
        _totalPages = result['totalPages'] ?? 1;
        _totalProperties = result['total'] ?? 0;
        _hasNextPage = result['hasNextPage'] ?? false;
        
        _setState(PropertyLoadingState.searchLoaded);
      } else {
        _setError(result['message'] ?? 'Search failed');
        _setState(PropertyLoadingState.searchError);
      }
    } catch (e) {
      _setError('Search error: ${e.toString()}');
      _setState(PropertyLoadingState.searchError);
    }
  }

  // Load more search results
  Future<void> loadMoreSearchResults() async {
    if (_isLoadingMore || !_hasNextPage || !_isSearchMode || _currentSearchQuery.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await PropertyService.searchProperties(
        searchString: _currentSearchQuery,
        page: nextPage,
        limit: _pageSize,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _filters,
      );

      if (result['success']) {
        final List<Property> newProperties = result['properties'] ?? [];
        _searchResults.addAll(newProperties);
        _currentPage = nextPage;
        _hasNextPage = result['hasNextPage'] ?? false;
      } else {
        _setError(result['message'] ?? 'Failed to load more search results');
      }
    } catch (e) {
      _setError('Error loading more search results: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load featured properties
  Future<void> loadFeaturedProperties({int limit = 10}) async {
    try {
      final result = await PropertyService.getFeaturedProperties(limit: limit);

      if (result['success']) {
        _featuredProperties = result['properties'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading featured properties: $e');
      // Don't show error for featured properties as it's not critical
    }
  }

  // Clear search and return to normal view
  void clearSearch() {
    _isSearchMode = false;
    _currentSearchQuery = '';
    _searchResults.clear();
    _currentPage = 1;
    _setState(PropertyLoadingState.loaded);
  }

  // Apply filters
  Future<void> applyFilters(Map<String, dynamic> newFilters) async {
    _filters = Map.from(newFilters);
    if (_isSearchMode) {
      await searchProperties(_currentSearchQuery, newSearch: true);
    } else {
      await loadProperties(refresh: true);
    }
  }

  // Clear filters
  Future<void> clearFilters() async {
    _filters.clear();
    if (_isSearchMode) {
      await searchProperties(_currentSearchQuery, newSearch: true);
    } else {
      await loadProperties(refresh: true);
    }
  }

  // Apply sorting
  Future<void> applySorting(String sortBy, String sortOrder) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    if (_isSearchMode) {
      await searchProperties(_currentSearchQuery, newSearch: true);
    } else {
      await loadProperties(refresh: true);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    if (_isSearchMode && _currentSearchQuery.isNotEmpty) {
      await searchProperties(_currentSearchQuery, newSearch: true);
    } else {
      await loadProperties(refresh: true);
    }
    await loadFeaturedProperties();
  }

  // Get property by ID from current list
  Property? getPropertyById(String id) {
    try {
      return displayProperties.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add property to favorites (local state update)
  void toggleFavorite(String propertyId) {
    for (var property in _properties) {
      if (property.id == propertyId) {
        // This would need to be implemented in the Property model
        // property.toggleFavorite();
        break;
      }
    }
    for (var property in _searchResults) {
      if (property.id == propertyId) {
        // property.toggleFavorite();
        break;
      }
    }
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _properties.clear();
    _searchResults.clear();
    _featuredProperties.clear();
    _currentPage = 1;
    _totalPages = 1;
    _totalProperties = 0;
    _hasNextPage = false;
    _isSearchMode = false;
    _currentSearchQuery = '';
    _filters.clear();
    _sortBy = null;
    _sortOrder = null;
    _clearError();
    _setState(PropertyLoadingState.idle);
  }

  // Private helper methods
  void _setState(PropertyLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
