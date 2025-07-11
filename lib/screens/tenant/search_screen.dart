// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/filters_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/app_config.dart';
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
    this.selectedAmenities = const [],
  });

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
    return propertyType != 'All' ||
        priceRange.start != 0 ||
        priceRange.end != 5000 ||
        bedrooms != null ||
        selectedAmenities.isNotEmpty;
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
    _searchController.addListener(_performSearch);
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      setState(() {
        _filteredProperties = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await PropertyService.searchProperties(searchString: searchQuery);
    if (result['success'] == true) {
      setState(() {
        _filteredProperties = List<Property>.from(result['properties'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _filteredProperties = [];
        _errorMessage = result['message'] ?? 'Failed to load properties.';
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

  void _applySorting() {
    switch (_sortBy) {
      case 'Price Low to High':
        _filteredProperties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High to Low':
        _filteredProperties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        _filteredProperties.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Recent':
      default:
        _filteredProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  void _toggleFavorite(String propertyId) {
    setState(() {
      if (widget.user.favoriteProperties.contains(propertyId)) {
        widget.user.favoriteProperties.remove(propertyId);
      } else {
        widget.user.favoriteProperties.add(propertyId);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _filters.clear();
      _sortBy = 'Recent';
      _performSearch();
    });
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
              child: _buildSearchResults(),
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
        style: TextStyle(color: AppTheme.getTextColor(context),),
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
                color: _filters.hasActiveFilters 
                    ? AppTheme.primaryblue 
                    : AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filters.hasActiveFilters 
                      ? AppTheme.primaryblue 
                      : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: _filters.hasActiveFilters 
                        ? AppTheme.whiteColor 
                        : AppTheme.getSecondaryTextColor(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _filters.hasActiveFilters ? 'Filters Applied' : 'Filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: _filters.hasActiveFilters 
                          ? AppTheme.whiteColor 
                          : AppTheme.getSecondaryTextColor(context),
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
        SizedBox(width: 12),
        GestureDetector(
          onTap: _showSortOptions,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryblue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 18,
                  color: AppTheme.primaryblue,
                ),
                SizedBox(width: 8),
                Text(
                  _sortBy,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              ...(_sortOptions.map((option) {
                final isSelected = _sortBy == option;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryblue : AppTheme.getTextColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryblue,
                          size: 20,
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    _performSearch();
                    Navigator.pop(context);
                  },
                );
              }).toList()),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

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
        Expanded(
          child: _filteredProperties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 100,),
                  itemCount: _filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = _filteredProperties[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: _buildPropertyCard(property),
                    );
                  },
                ),
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
    final formattedPrice = NumberFormat('#,##0').format(property.price);
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
                        onTap: () => _toggleFavorite(property.id),
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
                            widget.user.favoriteProperties.contains(property.id)
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: widget.user.favoriteProperties.contains(property.id)
                                ? Colors.red
                                : AppTheme.getSecondaryTextColor(context),
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
                      color: property.availabilityStatus == AvailabilityStatus.availableNow
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: AppTheme.whiteColor,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? 'Available Now'
                              : 'Available Later',
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
                                'UGX$formattedPrice',
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
                          if (property.availabilityStatus == AvailabilityStatus.availableLater &&
                               property.availableFrom != null)
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
