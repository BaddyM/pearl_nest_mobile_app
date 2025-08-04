import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/blocs/property/property_event.dart';
import 'package:pearlnest/blocs/property/property_state.dart';
import 'package:pearlnest/models/property.dart';

class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  List<Property> _allProperties = [];
  Map<String, dynamic> _currentFilters = {};
  String? _currentSearchQuery;
  int _currentPage = 1;
  bool _hasReachedMax = false;
  static const int _pageSize = 20;

  PropertyBloc() : super(PropertyInitial()) {
    on<PropertyFetchRequested>(_onPropertyFetchRequested);
    on<PropertySearchRequested>(_onPropertySearchRequested);
    on<PropertyRefreshRequested>(_onPropertyRefreshRequested);
    on<PropertyLoadMoreRequested>(_onPropertyLoadMoreRequested);
    on<PropertyFavoriteToggled>(_onPropertyFavoriteToggled);
    on<PropertyFilterApplied>(_onPropertyFilterApplied);
  }

  Future<void> _onPropertyFetchRequested(
    PropertyFetchRequested event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyLoading) return;

    emit(PropertyLoading());

    try {
      debugPrint('PropertyBloc: Fetching properties - page: ${event.page}, limit: ${event.limit}');

      final result = await PropertyService.getProperties(
        page: event.page,
        limit: event.limit,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      if (result['success'] == true) {
        final properties = result['properties'] as List<Property>;
        final totalCount = result['totalCount'] as int;

        _allProperties = properties;
        _currentPage = event.page;
        _currentFilters = event.filters ?? {};
        _currentSearchQuery = null;
        _hasReachedMax = properties.length < event.limit;

        debugPrint('PropertyBloc: Properties fetched successfully - ${properties.length} properties');

        emit(PropertyLoaded(
          properties: properties,
          hasReachedMax: _hasReachedMax,
          currentPage: _currentPage,
          totalCount: totalCount,
          filters: _currentFilters,
        ));
      } else {
        debugPrint('PropertyBloc: Failed to fetch properties - ${result['message']}');
        emit(PropertyError(message: result['message'] ?? 'Failed to fetch properties'));
      }
    } catch (e, stackTrace) {
      debugPrint('PropertyBloc: Error fetching properties - $e');
      debugPrint('PropertyBloc: Stack trace - $stackTrace');
      emit(PropertyError(message: 'Network error. Please check your connection.'));
    }
  }

  Future<void> _onPropertySearchRequested(
    PropertySearchRequested event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyLoading) return;

    emit(PropertyLoading());

    try {
      debugPrint('PropertyBloc: Searching properties - query: ${event.searchString}');

      final result = await PropertyService.searchProperties(
        searchString: event.searchString,
        page: event.page,
        limit: event.limit,
        filters: event.filters,
      );

      if (result['success'] == true) {
        final properties = result['properties'] as List<Property>;
        final totalCount = result['totalCount'] as int;

        _allProperties = properties;
        _currentPage = event.page;
        _currentFilters = event.filters ?? {};
        _currentSearchQuery = event.searchString;
        _hasReachedMax = properties.length < event.limit;

        debugPrint('PropertyBloc: Property search completed - ${properties.length} results');

        emit(PropertyLoaded(
          properties: properties,
          hasReachedMax: _hasReachedMax,
          currentPage: _currentPage,
          totalCount: totalCount,
          searchQuery: _currentSearchQuery,
          filters: _currentFilters,
        ));
      } else {
        debugPrint('PropertyBloc: Property search failed - ${result['message']}');
        emit(PropertyError(message: result['message'] ?? 'Search failed'));
      }
    } catch (e, stackTrace) {
      debugPrint('PropertyBloc: Error searching properties - $e');
      debugPrint('PropertyBloc: Stack trace - $stackTrace');
      emit(PropertyError(message: 'Network error. Please check your connection.'));
    }
  }

  Future<void> _onPropertyRefreshRequested(
    PropertyRefreshRequested event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyLoaded) {
      final currentState = state as PropertyLoaded;
      emit(PropertyRefreshing(properties: currentState.properties));

      try {
        debugPrint('PropertyBloc: Refreshing properties');

        // Refresh with current search query or filters
        if (_currentSearchQuery != null) {
          add(PropertySearchRequested(
            searchString: _currentSearchQuery!,
            page: 1,
            limit: _pageSize,
            filters: _currentFilters,
          ));
        } else {
          add(PropertyFetchRequested(
            page: 1,
            limit: _pageSize,
            filters: _currentFilters,
          ));
        }
      } catch (e) {
        debugPrint('PropertyBloc: Error refreshing properties - $e');
        emit(PropertyError(message: 'Failed to refresh properties'));
      }
    } else {
      // If not in loaded state, just fetch fresh data
      add(PropertyFetchRequested(page: 1, limit: _pageSize));
    }
  }

  Future<void> _onPropertyLoadMoreRequested(
    PropertyLoadMoreRequested event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyLoaded && !_hasReachedMax) {
      final currentState = state as PropertyLoaded;
      emit(PropertyLoadingMore(properties: currentState.properties));

      try {
        debugPrint('PropertyBloc: Loading more properties - page: ${_currentPage + 1}');

        final result = _currentSearchQuery != null
            ? await PropertyService.searchProperties(
                searchString: _currentSearchQuery!,
                page: _currentPage + 1,
                limit: _pageSize,
                filters: _currentFilters,
              )
            : await PropertyService.getProperties(
                page: _currentPage + 1,
                limit: _pageSize,
                filters: _currentFilters,
              );

        if (result['success'] == true) {
          final newProperties = result['properties'] as List<Property>;
          final totalCount = result['totalCount'] as int;

          _allProperties.addAll(newProperties);
          _currentPage++;
          _hasReachedMax = newProperties.length < _pageSize;

          debugPrint('PropertyBloc: More properties loaded - ${newProperties.length} new properties');

          emit(PropertyLoaded(
            properties: List.from(_allProperties),
            hasReachedMax: _hasReachedMax,
            currentPage: _currentPage,
            totalCount: totalCount,
            searchQuery: _currentSearchQuery,
            filters: _currentFilters,
          ));
        } else {
          debugPrint('PropertyBloc: Failed to load more properties - ${result['message']}');
          emit(PropertyError(message: result['message'] ?? 'Failed to load more properties'));
        }
      } catch (e, stackTrace) {
        debugPrint('PropertyBloc: Error loading more properties - $e');
        debugPrint('PropertyBloc: Stack trace - $stackTrace');
        emit(PropertyError(message: 'Network error. Please check your connection.'));
      }
    }
  }

  Future<void> _onPropertyFavoriteToggled(
    PropertyFavoriteToggled event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyLoaded) {
      final currentState = state as PropertyLoaded;

      try {
        debugPrint('PropertyBloc: Toggling favorite for property ${event.propertyId}');

        // Find the property and toggle its favorite status optimistically
        final updatedProperties = currentState.properties.map((property) {
          if (property.id == event.propertyId) {
            // For now, we'll just return the same property since we don't have a favorite field
            // This is a placeholder for when the Property model supports favorites
            return property;
          }
          return property;
        }).toList();

        // Update the state optimistically
        emit(currentState.copyWith(properties: updatedProperties));

        // TODO: Implement actual API call to toggle favorite
        // For now, we'll just update the UI optimistically
        debugPrint('PropertyBloc: Favorite toggled optimistically');
      } catch (e) {
        debugPrint('PropertyBloc: Error toggling favorite - $e');
        // Revert the state if needed
        emit(currentState);
      }
    }
  }

  Future<void> _onPropertyFilterApplied(
    PropertyFilterApplied event,
    Emitter<PropertyState> emit,
  ) async {
    debugPrint('PropertyBloc: Applying filters - ${event.filters}');

    _currentFilters = event.filters;

    // Apply filters by refetching data
    if (_currentSearchQuery != null) {
      add(PropertySearchRequested(
        searchString: _currentSearchQuery!,
        page: 1,
        limit: _pageSize,
        filters: event.filters,
      ));
    } else {
      add(PropertyFetchRequested(
        page: 1,
        limit: _pageSize,
        filters: event.filters,
      ));
    }
  }
}
