// Events for PropertyBloc
abstract class PropertyEvent {}

class PropertyFetchRequested extends PropertyEvent {
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;
  final Map<String, dynamic>? filters;
  
  PropertyFetchRequested({
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder,
    this.filters,
  });
}

class PropertySearchRequested extends PropertyEvent {
  final String searchString;
  final int page;
  final int limit;
  final Map<String, dynamic>? filters;
  
  PropertySearchRequested({
    required this.searchString,
    this.page = 1,
    this.limit = 20,
    this.filters,
  });
}

class PropertyRefreshRequested extends PropertyEvent {}

class PropertyLoadMoreRequested extends PropertyEvent {}

class PropertyFavoriteToggled extends PropertyEvent {
  final String propertyId;
  
  PropertyFavoriteToggled({required this.propertyId});
}

class PropertyFilterApplied extends PropertyEvent {
  final Map<String, dynamic> filters;
  
  PropertyFilterApplied({required this.filters});
}
