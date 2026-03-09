import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/screens/landlord/landlord_property_upload_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/utils/image_helper.dart';

class LandlordPropertyManagementScreen extends StatefulWidget {
  final User user;
  final Landlord landlord;
  final List<Property> properties;

  const LandlordPropertyManagementScreen({
    super.key,
    required this.user,
    required this.landlord,
    required this.properties,
  });

  @override
  State<LandlordPropertyManagementScreen> createState() => _LandlordPropertyManagementScreenState();
}

class _LandlordPropertyManagementScreenState extends State<LandlordPropertyManagementScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Property> _properties = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final List<String> _filterOptions = ['All', 'Available', 'Booked', 'Under Review', 'Featured', 'Verified'];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      //debugPrint('🏠 Loading properties for landlord: ${widget.user.id}');

      // Get auth token
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Authentication required. Please log in again.';
        });
        return;
      }

      // Fetch properties from API
      final result = await PropertyService.getPropertiesByLandlord(widget.user.id, token: token);

      if (result['success'] == true) {
        final List<Property> properties = result['properties'] ?? [];

        // Update landlord information in properties since API doesn't provide it
        final updatedProperties = properties.map((property) {
          return Property(
            id: property.id,
            title: property.title,
            description: property.description,
            price: property.price,
            deposit: property.deposit,
            isRent: property.isRent,
            parking: property.parking,
            isSale: property.isSale,
            priceType: property.priceType,
            location: property.location,
            address: property.address,
            type: property.type,
            bedrooms: property.bedrooms,
            bathrooms: property.bathrooms,
            area: property.area,
            amenities: property.amenities,
            images: property.images,
            landlordId: property.landlordId,
            landlordName: widget.user.name, // Fill from widget.user
            landlordPhone: widget.user.phone, // Fill from widget.user
            landlordEmail: widget.user.email, // Fill from widget.user
            rating: property.rating,
            reviewCount: property.reviewCount,
            status: property.status,
            availabilityStatus: property.availabilityStatus,
            availableFrom: property.availableFrom,
            createdAt: property.createdAt,
            updatedAt: property.updatedAt,
            latitude: property.latitude,
            longitude: property.longitude,
            isFeatured: property.isFeatured,
            isVerified: property.isVerified,
            views: property.views,
            shares: property.shares,
            favourites: property.favourites,
            neighborhood: property.neighborhood,
            user: property.user,
            propertyMap: property.propertyMap,
            safetyAndSecurity: property.safetyAndSecurity,
            nearbyPlaces: property.nearbyPlaces,
          );
        }).toList();

        setState(() {
          _properties = updatedProperties;
          _isLoading = false;
          _hasError = false;
        });

        //debugPrint('✅ Successfully loaded ${properties.length} properties');
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to load properties';
        });
        //debugPrint('❌ Failed to load properties: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'An error occurred while loading properties. Please try again.';
      });
      //debugPrint('❌ Error loading properties: $e');
    }
  }

  List<Property> get _filteredProperties {
    List<Property> filtered = _properties;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) => property.title.toLowerCase().contains(_searchQuery.toLowerCase()) || property.location.toLowerCase().contains(_searchQuery.toLowerCase()) || property.propertyTypeString.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Available':
          filtered = filtered.where((p) => p.status == PropertyStatus.available).toList();
          break;
        case 'Booked':
          filtered = filtered.where((p) => p.status == PropertyStatus.booked).toList();
          break;
        case 'Under Review':
          filtered = filtered.where((p) => p.status == PropertyStatus.pending).toList();
          break;
        case 'Featured':
          filtered = filtered.where((p) => p.isFeatured).toList();
          break;
        case 'Verified':
          filtered = filtered.where((p) => p.isVerified).toList();
          break;
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 70),
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsRow(),
              _isLoading
                  ? _buildLoadingState()
                  : _hasError
                      ? _buildErrorState()
                      : _filteredProperties.isEmpty
                          ? _buildEmptyState()
                          : _buildPropertiesList(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your properties...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16),
          Text(
            'Error Loading Properties',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Failed to load properties. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadProperties,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryblue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppTheme.blackColor,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'My Properties',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_properties.length} properties listed',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSearchAndFilters(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search properties...',
              hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              prefixIcon: Icon(Icons.search, color: AppTheme.getSecondaryTextColor(context)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              final isSelected = _selectedFilter == filter;
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                  },
                  backgroundColor: AppTheme.getBackgroundColor(context),
                  selectedColor: AppTheme.primaryblue,
                  checkmarkColor: AppTheme.whiteColor,
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryblue : AppTheme.greyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final availableCount = _properties.where((p) => p.availabilityStatus == true).length;
    final bookedCount = _properties.where((p) => p.status == PropertyStatus.booked).length;
    final underReviewCount = _properties.where((p) => p.status == PropertyStatus.pending).length;
    final featuredCount = _properties.where((p) => p.isFeatured).length;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Available', availableCount, Colors.green),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem('Booked', bookedCount, Colors.orange),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem('Review', underReviewCount, Colors.blue),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem('Featured', featuredCount, Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.lightGreyColor,
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredProperties.length,
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: _buildPropertyListCard(property),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProperties.length,
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return _buildPropertyGridCard(property);
      },
    );
  }

  String _formatLargePrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else {
      return ProfileService().currencyConverter(price: price.toInt());
    }
  }

  Widget _buildPropertyListCard(Property property) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  color: AppTheme.lightGreyColor,
                ),
                child: Stack(
                  children: [
                    if (property.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: _buildPropertyImage(
                          property.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    else
                      Center(child: Icon(Icons.home, color: AppTheme.getSecondaryTextColor(context), size: 40)),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (property.isFeatured)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (property.isVerified)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(property.status),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        property.propertyTypeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryblue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppTheme.greyColor),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location,
                              style: TextStyle(
                                fontSize: 14,
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
                          _buildSpecItem(Icons.bed, '${property.bedrooms}'),
                          SizedBox(width: 12),
                          _buildSpecItem(Icons.bathtub, '${property.bathrooms}'),
                          SizedBox(width: 12),
                          _buildSpecItem(Icons.square_foot, '${property.area.toInt()}m²'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "${_formatLargePrice(property.price)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryblue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ' ${property.priceType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                          ),
                          Spacer(),
                          if (property.rating > 0) ...[
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${property.reviewCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Created: ${_formatDate(property.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePropertyAction(value, property),
                  color: AppTheme.getCardColor(context),
                  surfaceTintColor: AppTheme.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: AppTheme.getTextColor(context)),
                          SizedBox(width: 8),
                          Text(
                            'View Details',
                            style: TextStyle(color: AppTheme.getTextColor(context)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: AppTheme.getTextColor(context)),
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(color: AppTheme.getTextColor(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.more_vert, color: AppTheme.getTextColor(context), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyGridCard(Property property) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: AppTheme.lightGreyColor,
              ),
              child: Stack(
                children: [
                  if (property.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: _buildPropertyImage(
                        property.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else
                    Center(child: Icon(Icons.home, color: AppTheme.getSecondaryTextColor(context), size: 40)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusChip(property.status),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (property.isFeatured)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (property.isVerified)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      onSelected: (value) => _handlePropertyAction(value, property),
                      color: AppTheme.getCardColor(context),
                      surfaceTintColor: AppTheme.whiteColor,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: AppTheme.getTextColor(context)),
                              SizedBox(width: 8),
                              Text(
                                'View Details',
                                style: TextStyle(color: AppTheme.getTextColor(context)),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: AppTheme.getTextColor(context)),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(color: AppTheme.getTextColor(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.getCardColor(context).withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.getTextColor(context).withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.more_vert, color: AppTheme.getTextColor(context), size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    property.propertyTypeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryblue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: AppTheme.getSecondaryTextColor(context)),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      _buildSpecItem(Icons.bed, '${property.bedrooms}', size: 10),
                      SizedBox(width: 8),
                      _buildSpecItem(Icons.bathtub, '${property.bathrooms}', size: 10),
                      SizedBox(width: 8),
                      _buildSpecItem(Icons.square_foot, '${property.area.toInt()}m²', size: 10),
                    ],
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${ProfileService().currencyConverter(price: property.price.toInt())}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryblue,
                              ),
                            ),
                            Text(
                              property.priceType,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (property.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.getSecondaryTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${property.reviewCount})',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text, {double size = 12}) {
    return Row(
      children: [
        Icon(icon, size: size, color: AppTheme.getSecondaryTextColor(context)),
        SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: size - 2,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PropertyStatus status) {
    Color color;
    String text;
    switch (status) {
      case PropertyStatus.available || PropertyStatus.approved:
        color = Colors.green;
        text = 'Available';
        break;
      case PropertyStatus.booked:
        color = Colors.orange;
        text = 'Booked';
        break;
      case PropertyStatus.pending:
        color = Colors.blue;
        text = 'Pending';
        break;
      case PropertyStatus.unavailable || PropertyStatus.rejected:
        color = Colors.red;
        text = 'Unavailable';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.lightGreyColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 64,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All' ? 'No properties found' : 'No properties yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All' ? 'Try adjusting your search or filters' : 'Start by adding your first property',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddProperty,
      backgroundColor: AppTheme.primaryblue,
      icon: Icon(Icons.add, color: AppTheme.whiteColor),
      label: Text(
        'Add Property',
        style: TextStyle(
          color: AppTheme.whiteColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd-MMM-yyyy").format(date);
  }

  Widget _buildPropertyImage(String imagePath, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    // Use ImageHelper to get the full URL for both network and relative paths
    final fullImageUrl = ImageHelper.getFullImageUrl(imagePath);

    return Image.network(
      fullImageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.lightGreyColor,
          child: Icon(Icons.image_not_supported, color: AppTheme.getSecondaryTextColor(context)),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppTheme.lightGreyColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandlordPropertyUploadScreen(
          user: widget.user,
          landlord: widget.landlord,
          property: null,
        ),
      ),
    );

    // Refresh properties if upload was successful
    if (result == true) {
      _loadProperties();
    }
  }

  void _handlePropertyAction(String action, Property property) {
    switch (action) {
      case 'view':
        _viewPropertyDetails(property);
        break;
      case 'edit':
        _editProperty(property);
        break;
      case 'feature':
        _toggleFeatureProperty(property);
        break;
      case 'delete':
        _deleteProperty(property);
        break;
    }
  }

  void _viewPropertyDetails(Property property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPropertyDetailsModal(property),
    );
  }

  Widget _buildPropertyDetailsModal(Property property) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Property Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (property.images.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: CarouselView(
                        itemExtent: 300, // The fixed size of each item
                        shrinkExtent: 200, // The minimum size items shrink to as they scroll away
                        children: List.generate(property.images.length, (int index) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.lightGreyColor,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildPropertyImage(
                                property.images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                      if (property.isFeatured)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (property.isVerified)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        property.propertyTypeString,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryblue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      _buildStatusChip(property.status),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.getSecondaryTextColor(context)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.location,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              property.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: AppTheme.primaryblue),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Property Price",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${ProfileService().currencyConverter(price: property.price.toInt())}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryblue,
                              ),
                            ),
                            Text(
                              property.priceType,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: AppTheme.primaryblue),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Initial Deposit",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${ProfileService().currencyConverter(price: property.deposit.toInt())}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryblue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Property Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Bedrooms', '${property.bedrooms}', Icons.bed),
                        _buildDetailRow('Bathrooms', '${property.bathrooms}', Icons.bathtub),
                        _buildDetailRow('Area', '${property.area.toInt()} m²', Icons.square_foot),
                        _buildDetailRow('For Rent', property.isRent ? 'yes' : 'no', Icons.house_rounded),
                        _buildDetailRow('For Sale', property.isSale ? 'yes' : 'no', Icons.house_rounded),
                        _buildDetailRow('Has parking', property.parking ? 'yes' : 'no', Icons.garage),
                        if (property.rating > 0) _buildDetailRow('Rating', '${property.rating.toStringAsFixed(1)} (${property.reviewCount} reviews)', Icons.star),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  if (property.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      property.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  if (property.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenities
                          .map((amenity) => Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  amenity,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryblue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                  Text(
                    'Property Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Created', _formatDate(property.createdAt), Icons.calendar_today),
                        _buildDetailRow('Last Updated', _formatDate(property.updatedAt), Icons.update),
                        if (property.availableFrom != null) _buildDetailRow('Available From', _formatDate(property.availableFrom!), Icons.event_available),
                        // _buildDetailRow('Property ID', property.id, Icons.tag),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.getSecondaryTextColor(context)),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _editProperty(Property property) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandlordPropertyUploadScreen(
          user: widget.user,
          landlord: widget.landlord,
          property: property,
        ),
      ),
    );

    // Refresh properties if upload was successful
    if (result == true) {
      _loadProperties();
    }
  }

  void _duplicateProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.copy, color: AppTheme.primaryblue),
            SizedBox(width: 8),
            Text(
              'Duplicate Property',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to duplicate "${property.title}"?',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.getSecondaryTextColor(context)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The duplicated property will be created as a draft.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.whiteColor),
                      SizedBox(width: 8),
                      Text(
                        'Property duplicated successfully!',
                        style: TextStyle(color: AppTheme.lightGreyColor),
                      ),
                    ],
                  ),
                  duration: Duration(milliseconds: 500),
                  backgroundColor: AppTheme.primaryblue,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryblue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Duplicate', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _toggleFeatureProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              property.isFeatured ? Icons.star : Icons.star_border,
              color: property.isFeatured ? Colors.amber : AppTheme.primaryblue,
            ),
            SizedBox(width: 8),
            Text(
              property.isFeatured ? 'Unfeature Property' : 'Feature Property',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.isFeatured ? 'Remove "${property.title}" from featured properties?' : 'Add "${property.title}" to featured properties?',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (property.isFeatured ? Colors.amber : AppTheme.primaryblue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: property.isFeatured ? const Color.fromARGB(255, 226, 175, 22) : AppTheme.primaryblue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property.isFeatured ? 'Featured properties get more visibility.' : 'Featured properties appear at the top of search results.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.whiteColor),
                      SizedBox(width: 8),
                      Text(
                        property.isFeatured ? 'Property removed from featured!' : 'Property added to featured!',
                        style: TextStyle(color: AppTheme.lightGreyColor),
                      ),
                    ],
                  ),
                  backgroundColor: property.isFeatured ? Colors.red : AppTheme.primaryblue,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 500),
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: property.isFeatured ? const Color.fromARGB(255, 226, 175, 22) : AppTheme.primaryblue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              property.isFeatured ? 'Unfeature' : 'Feature',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Property',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${property.title}"?',
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All property data will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Deleting property...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  duration: Duration(seconds: 30), // Long duration for loading
                  backgroundColor: AppTheme.primaryblue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(16),
                ),
              );

              try {
                // Get auth token
                final token = await AuthService.getCurrentToken();
                if (token == null || token.isEmpty) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Authentication required. Please log in again.', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                // Call delete API
                final result = await PropertyService.deleteProperty(
                  propertyId: property.id,
                  token: token,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (result['success'] == true) {
                  // Refresh the properties list
                  _loadProperties();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Property deleted successfully!', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      duration: Duration(milliseconds: 2000),
                      margin: EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to delete property', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting property: $e', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }
}
