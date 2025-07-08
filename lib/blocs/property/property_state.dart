import 'package:equatable/equatable.dart';
import 'package:pearlnest/models/property.dart';

// States for PropertyBloc
abstract class PropertyState extends Equatable {
  const PropertyState();
  
  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {}

class PropertyLoading extends PropertyState {}

class PropertyLoaded extends PropertyState {
  final List<Property> properties;
  final bool hasReachedMax;
  final int currentPage;
  final int totalCount;
  final String? searchQuery;
  final Map<String, dynamic>? filters;
  
  const PropertyLoaded({
    required this.properties,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.searchQuery,
    this.filters,
  });
  
  PropertyLoaded copyWith({
    List<Property>? properties,
    bool? hasReachedMax,
    int? currentPage,
    int? totalCount,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) {
    return PropertyLoaded(
      properties: properties ?? this.properties,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
  
  @override
  List<Object?> get props => [
    properties,
    hasReachedMax,
    currentPage,
    totalCount,
    searchQuery,
    filters,
  ];
}

class PropertyError extends PropertyState {
  final String message;
  final String? code;
  
  const PropertyError({required this.message, this.code});
  
  @override
  List<Object?> get props => [message, code];
}

class PropertyRefreshing extends PropertyState {
  final List<Property> properties;
  
  const PropertyRefreshing({required this.properties});
  
  @override
  List<Object?> get props => [properties];
}

class PropertyLoadingMore extends PropertyState {
  final List<Property> properties;
  
  const PropertyLoadingMore({required this.properties});
  
  @override
  List<Object?> get props => [properties];
}
