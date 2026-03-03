// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/filters_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  final User user;
  final List<Property>? allProperties;

  const SearchScreen({
    super.key,
    required this.user,
    this.allProperties,
  });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class SearchFilters {
  String propertyType;
  RangeValues priceRange;
  int? bedrooms;
  List<String> selectedAmenities;

  SearchFilters({
    this.propertyType = 'All',
    this.priceRange = const RangeValues(0, 5000),
    this.bedrooms,
    List<String>? selectedAmenities,
  }) : selectedAmenities = selectedAmenities ?? [];

  SearchFilters copyWith({
    String? propertyType,
    RangeValues? priceRange,
    int? bedrooms,
    List<String>? selectedAmenities,
  }) {
    return SearchFilters(
      propertyType: propertyType ?? this.propertyType,
      priceRange: priceRange ?? this.priceRange,
      bedrooms: bedrooms ?? this.bedrooms,
      selectedAmenities: selectedAmenities ?? List.from(this.selectedAmenities),
    );
  }

  bool get hasActiveFilters {
    return propertyType != 'All' || priceRange.start != 0 || priceRange.end != 5000 || bedrooms != null || selectedAmenities.isNotEmpty;
  }

  void clear() {
    propertyType = 'All';
    priceRange = RangeValues(0, 5000);
    bedrooms = null;
    selectedAmenities.clear();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilters _filters = SearchFilters();
  List<Property> _filteredProperties = [];
  bool _isLoading = false;
  String _sortBy = 'Recent';
  String? _errorMessage;

  final List<String> _sortOptions = [
    'Recent',
    'Price Low to High',
    'Price High to Low',
    'Rating',
  ];

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(_performSearch);
    _performSearch();
  }

  @override
  void dispose() {
    // _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to check if current user has favorited this property
  bool _isPropertyFavorited(Property property) {
    return property.favourites.any((favourite) => favourite['userId'] == widget.user.id);
  }

  Future<void> _performSearch() async {
    final searchQuery = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Property> result;

      // Text search takes priority - use text search API with filters
      result = await PropertyService.searchProperties(
        searchString: searchQuery,
        sortBy: _getSortField(_sortBy),
        sortOrder: _getSortOrder(_sortBy),
        filters: _buildApiFilters(),
      );

      List<Property> apiProperties = List<Property>.from(result);
      List<Property> properties = apiProperties.where((property) => property.availabilityStatus == true).toList();

      // Apply local filters for features not supported by API
      properties = _applyLocalFilters(properties);

      setState(() {
        _filteredProperties = properties;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error performing search: $e');
      setState(() {
        _filteredProperties = [];
        _errorMessage = 'An error occurred while searching. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Helper to get full image URL
  String _getFullImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }

  // Helper to convert UI sort option to API sort field
  String? _getSortField(String sortBy) {
    switch (sortBy) {
      case 'Price Low to High':
      case 'Price High to Low':
        return 'price';
      case 'Rating':
        return 'rating';
      case 'Recent':
      default:
        return 'createdAt';
    }
  }

  // Helper to convert UI sort option to API sort order
  String? _getSortOrder(String sortBy) {
    switch (sortBy) {
      case 'Price Low to High':
        return 'asc';
      case 'Price High to Low':
      case 'Rating':
      case 'Recent':
      default:
        return 'desc';
    }
  }

  // Helper to build API filters from UI filters
  Map<String, dynamic> _buildApiFilters() {
    final filters = <String, dynamic>{};

    // Only add filters that the API supports
    // Property type filter - let's handle this locally for now
    if (_filters.propertyType != 'All') {
      filters['propertyType'] = _filters.propertyType;
    }

    // Bedrooms filter - let's handle this locally for now
    if (_filters.bedrooms != null) {
      filters['bedrooms'] = _filters.bedrooms;
    }

    // Price range is handled by the price search API, not as a filter
    // For text search, we'll apply price filtering locally

    filters['priceRange'] = _filters.priceRange.end.toInt();

    // Amenities filter - let's handle this locally for now
    if (_filters.selectedAmenities.isNotEmpty) {
      filters['amenities'] = _filters.selectedAmenities;
    }

    return filters;
  }

  // Helper to apply local filters that aren't supported by API
  List<Property> _applyLocalFilters(List<Property> properties) {
    List<Property> filtered = List.from(properties);

    // Apply property type filter locally if needed
    if (_filters.propertyType != 'All') {
      filtered = filtered.where((property) => property.type.toString().split('.').last.toLowerCase() == _filters.propertyType.toLowerCase()).toList();
    }

    // Apply bedrooms filter locally if needed
    if (_filters.bedrooms != null) {
      filtered = filtered.where((property) => property.bedrooms == _filters.bedrooms).toList();
    }

    // Apply amenities filter locally if needed
    if (_filters.selectedAmenities.isNotEmpty) {
      filtered = filtered.where((property) {
        final propertyAmenities = property.amenities.map((a) => a.toLowerCase()).toList();
        return _filters.selectedAmenities.every((amenity) => propertyAmenities.contains(amenity.toLowerCase()));
      }).toList();
    }

    // Apply price range filter locally if we're doing text search
    // (price search API handles this, but text search might need local filtering)
    if (_filters.priceRange.start != 0 || _filters.priceRange.end != 5000) {
      filtered = filtered.where((property) => property.price >= _filters.priceRange.start && property.price <= _filters.priceRange.end).toList();
    }

    return filtered;
  }

  // Toggle favorite status for a property
  Future<void> _toggleFavorite(Property property) async {
    try {
      final wasLiked = _isPropertyFavorited(property);

      // Optimistically update the UI for better UX
      setState(() {
        if (wasLiked) {
          // Remove from favorites
          property.favourites.removeWhere((favourite) => favourite['userId'] == widget.user.id);
        } else {
          // Add to favorites
          property.favourites.add({
            'userId': widget.user.id,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      });

      // Make API call to sync with server
      //debugPrint('🤍 Toggling favorite for property: ${property.id}');
      final result = await FavoritesService.toggleFavorite(property.id);

      if (result['success'] == true) {
        // Success - UI is already updated optimistically
        final message = wasLiked ? 'Removed from favorites' : 'Added to favorites';
        //debugPrint('✅ $message for property: ${property.id}');

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppTheme.primaryblue,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // API call failed, revert the optimistic update
        setState(() {
          if (wasLiked) {
            // Revert: add back to favorites
            property.favourites.add({
              'userId': widget.user.id,
              'createdAt': DateTime.now().toIso8601String(),
            });
          } else {
            // Revert: remove from favorites
            property.favourites.removeWhere((favourite) => favourite['userId'] == widget.user.id);
          }
        });

        //debugPrint('❌ Failed to toggle favorite for property: ${property.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update favorites. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      //debugPrint('❌ Error toggling favorite: $e');

      // Revert the optimistic update on error
      final wasLiked = _isPropertyFavorited(property);
      setState(() {
        if (!wasLiked) {
          // Revert: add back to favorites
          property.favourites.add({
            'userId': widget.user.id,
            'createdAt': DateTime.now().toIso8601String(),
          });
        } else {
          // Revert: remove from favorites
          property.favourites.removeWhere((favourite) => favourite['userId'] == widget.user.id);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _clearFilters() {
    // Check if there are any filters to clear
    final hasSearchText = _searchController.text.trim().isNotEmpty;
    final hasActiveFilters = _filters.hasActiveFilters;
    final isNotDefaultSort = _sortBy != 'Recent';

    if (!hasSearchText && !hasActiveFilters && !isNotDefaultSort) {
      // No filters to clear, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No filters to clear'),
          backgroundColor: AppTheme.getSecondaryTextColor(context),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _searchController.clear();
      _filters.clear();
      _sortBy = 'Recent';
      _performSearch();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filters cleared successfully'),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openFilters() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiltersScreen(
          currentFilters: _filters,
          allProperties: _filteredProperties,
        ),
      ),
    );

    if (result != null && result is SearchFilters) {
      setState(() {
        _filters = result;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildSearchResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.getBackgroundColor(context),
            AppTheme.primaryblue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Properties',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Find your perfect home',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _clearFilters,
                  icon: Icon(
                    Icons.clear_all,
                    color: AppTheme.primaryblue,
                  ),
                  tooltip: 'Clear Filters',
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSearchBar(),
          SizedBox(height: 16),
          _buildFilterAndSort(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppTheme.getTextColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search by location, property name...',
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.search, color: AppTheme.primaryblue, size: 22),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.getSecondaryTextColor(context)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onEditingComplete: _performSearch,
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _openFilters,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _filters.hasActiveFilters ? AppTheme.primaryblue : AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filters.hasActiveFilters ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: _filters.hasActiveFilters ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _filters.hasActiveFilters ? 'Filters Applied' : 'Filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: _filters.hasActiveFilters ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_filters.hasActiveFilters) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextColor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_getActiveFiltersCount()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryblue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // SizedBox(width: 12),
        // GestureDetector(
        //   // onTap: _showSortOptions,
        //   child: Container(
        //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //     decoration: BoxDecoration(
        //       color: AppTheme.primaryblue.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(color: AppTheme.primaryblue.withOpacity(0.3)),
        //     ),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         Icon(
        //           Icons.sort,
        //           size: 18,
        //           color: AppTheme.primaryblue,
        //         ),
        //         SizedBox(width: 8),
        //         Text(
        //           _sortBy,
        //           style: TextStyle(
        //             fontSize: 14,
        //             color: AppTheme.primaryblue,
        //             fontWeight: FontWeight.w600,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_filters.propertyType != 'All') count++;
    if (_filters.priceRange.start != 0 || _filters.priceRange.end != 5000) count++;
    if (_filters.bedrooms != null) count++;
    if (_filters.selectedAmenities.isNotEmpty) count++;
    return count;
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        '${_filteredProperties.length} properties found',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.getSecondaryTextColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // void _showSortOptions() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return SingleChildScrollView(
  //         child: Container(
  //           margin: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: AppTheme.getCardColor(context),
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 padding: EdgeInsets.all(20),
  //                 decoration: BoxDecoration(
  //                   border: Border(
  //                     bottom: BorderSide(
  //                       color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
  //                     ),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Text(
  //                       'Sort By',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: AppTheme.getTextColor(context),
  //                       ),
  //                     ),
  //                     Spacer(),
  //                     GestureDetector(
  //                       onTap: () => Navigator.pop(context),
  //                       child: Icon(
  //                         Icons.close,
  //                         color: AppTheme.getSecondaryTextColor(context),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               ...(_sortOptions.map((option) {
  //                 final isSelected = _sortBy == option;
  //                 return ListTile(
  //                   contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  //                   title: Text(
  //                     option,
  //                     style: TextStyle(
  //                       color: isSelected ? AppTheme.primaryblue : AppTheme.getTextColor(context),
  //                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                   trailing: isSelected
  //                       ? Icon(
  //                           Icons.check_circle,
  //                           color: AppTheme.primaryblue,
  //                           size: 20,
  //                         )
  //                       : Container(
  //                           width: 20,
  //                           height: 20,
  //                           decoration: BoxDecoration(
  //                             shape: BoxShape.circle,
  //                             border: Border.all(
  //                               color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
  //                               width: 2,
  //                             ),
  //                           ),
  //                         ),
  //                   onTap: () {
  //                     setState(() {
  //                       _sortBy = option;
  //                     });
  //                     _performSearch();
  //                     Navigator.pop(context);
  //                   },
  //                 );
  //               }).toList()),
  //               SizedBox(height: 16),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryblue),
          SizedBox(height: 16),
          Text(
            'Loading properties...',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)));
    }
    return Column(
      children: [
        _buildResultsCount(),
        _filteredProperties.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                shrinkWrap: true, // Important: allows ListView to size itself
                physics: NeverScrollableScrollPhysics(), // Disable ListView scrolling since parent ScrollView handles it
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 100,
                ),
                itemCount: _filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = _filteredProperties[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: _buildPropertyCard(property),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria\nor filters to find more properties',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryblue,
              foregroundColor: AppTheme.whiteColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final formattedPrice = ProfileService().currencyConverter(price: property.price.toInt());
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
              property: property,
              user: widget.user,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getTextColor(context).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: AppTheme.lightGreyColor,
                  ),
                  child: property.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            _getFullImageUrl(property.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.lightGreyColor,
                                      AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.getSecondaryTextColor(context),
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryblue.withOpacity(0.1),
                                AppTheme.accentGreen.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.home_rounded,
                              color: AppTheme.primaryblue,
                              size: 50,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryblue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.propertyTypeString,
                              style: TextStyle(
                                color: AppTheme.whiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (property.isFeatured) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Featured',
                                style: TextStyle(
                                  color: AppTheme.whiteColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(property),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.whiteColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.getTextColor(context).withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPropertyFavorited(property) ? Icons.favorite : Icons.favorite_outline,
                            color: _isPropertyFavorited(property) ? Colors.red : AppTheme.getSecondaryTextColor(context),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: property.availabilityStatus == true ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.availabilityStatus == true ? Icons.check_circle : Icons.schedule,
                          color: AppTheme.whiteColor,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          property.availabilityStatus == true ? 'Available Now' : 'Available Later',
                          style: TextStyle(
                            color: AppTheme.whiteColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '${property.rating}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.primaryblue,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if (property.bedrooms > 0) ...[
                        Icon(
                          Icons.bed,
                          size: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${property.bedrooms}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      if (property.bathrooms > 0) ...[
                        Icon(
                          Icons.bathroom,
                          size: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${property.bathrooms}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.square_foot,
                        size: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${property.area.toInt()} sqft',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${property.reviewCount} reviews',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$formattedPrice',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryblue,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                property.priceType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getSecondaryTextColor(context),
                                ),
                              ),
                            ],
                          ),
                          if (property.availabilityStatus == false && property.availableFrom != null)
                            Text(
                              'Available from ${_formatDate(property.availableFrom!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 30) {
      return '$difference days';
    } else if (difference < 365) {
      final months = (difference / 30).round();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (difference / 365).round();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }
}
