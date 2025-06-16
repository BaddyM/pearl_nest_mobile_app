import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/screens/landlord/landlord_property_upload_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

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
  bool _isGridView = false;
  List<Property> _properties = [];
  final List<String> _filterOptions = ['All', 'Available', 'Booked', 'Under Review', 'Featured', 'Verified'];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties() async {
    setState(() {
    });
    _properties = [
      Property(
        id: '1',
        title: 'Modern Downtown Apartment',
        description: 'Beautiful modern apartment in the heart of downtown with stunning city views.',
        price: 1200,
        priceType: 'per month',
        location: 'Downtown',
        address: '123 Main St, Downtown',
        type: PropertyType.apartment,
        bedrooms: 2,
        bathrooms: 2,
        area: 85.5,
        amenities: ['WiFi', 'Parking', 'Gym', 'AC'],
        images: ['assets/images/img1.jpg', 'assets/images/img2.jpg'],
        landlordId: widget.landlord.id,
        landlordName: widget.user.name,
        landlordPhone: widget.user.phone,
        landlordEmail: widget.user.email,
        rating: 4.5,
        reviewCount: 12,
        status: PropertyStatus.available,
        availabilityStatus: AvailabilityStatus.availableNow,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
        latitude: 0.0,
        longitude: 0.0,
        isFeatured: true,
        isVerified: true,
      ),
      Property(
        id: '2',
        title: 'Cozy Studio Near University',
        description: 'Perfect for students, this cozy studio is just minutes from the university campus.',
        price: 800,
        priceType: 'per month',
        location: 'University District',
        address: '456 College Ave, University District',
        type: PropertyType.studio,
        bedrooms: 0,
        bathrooms: 1,
        area: 45.0,
        amenities: ['WiFi', 'Kitchen', 'Laundry'],
        images: ['assets/images/img3.jpg', 'assets/images/img4.jpg'],
        landlordId: widget.landlord.id,
        landlordName: widget.user.name,
        landlordPhone: widget.user.phone,
        landlordEmail: widget.user.email,
        rating: 4.2,
        reviewCount: 8,
        status: PropertyStatus.booked,
        availabilityStatus: AvailabilityStatus.availableLater,
        availableFrom: DateTime.now().add(Duration(days: 45)),
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        updatedAt: DateTime.now().subtract(Duration(days: 10)),
        latitude: 0.0,
        longitude: 0.0,
        isFeatured: false,
        isVerified: true,
      ),
      Property(
        id: '3',
        title: 'Luxury Family House',
        description: 'Spacious family house with garden, perfect for families with children.',
        price: 2500,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Oak Street, Suburbs',
        type: PropertyType.house,
        bedrooms: 4,
        bathrooms: 3,
        area: 180.0,
        amenities: ['WiFi', 'Parking', 'Garden', 'Garage', 'Pet Friendly'],
        images: ['assets/images/img5.jpg', 'assets/images/img6.jpg'],
        landlordId: widget.landlord.id,
        landlordName: widget.user.name,
        landlordPhone: widget.user.phone,
        landlordEmail: widget.user.email,
        rating: 4.8,
        reviewCount: 15,
        status: PropertyStatus.available,
        availabilityStatus: AvailabilityStatus.availableNow,
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
        latitude: 0.0,
        longitude: 0.0,
        isFeatured: true,
        isVerified: true,
      ),
      Property(
        id: '4',
        title: 'Beachfront Condo',
        description: 'Amazing oceanview condo with private balcony and beach access.',
        price: 150,
        priceType: 'per night',
        location: 'Beachfront',
        address: '321 Ocean Drive, Beachfront',
        type: PropertyType.condo,
        bedrooms: 1,
        bathrooms: 1,
        area: 65.0,
        amenities: ['WiFi', 'Beach Access', 'Pool', 'Balcony'],
        images: ['assets/images/img7.jpg'],
        landlordId: widget.landlord.id,
        landlordName: widget.user.name,
        landlordPhone: widget.user.phone,
        landlordEmail: widget.user.email,
        rating: 4.7,
        reviewCount: 23,
        status: PropertyStatus.available,
        availabilityStatus: AvailabilityStatus.availableNow,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
        latitude: 0.0,
        longitude: 0.0,
        isFeatured: true,
        isVerified: true,
      ),
      Property(
        id: '5',
        title: 'Budget Hostel Room',
        description: 'Clean and affordable hostel room perfect for backpackers and budget travelers.',
        price: 25,
        priceType: 'per night',
        location: 'City Center',
        address: '555 Budget St, City Center',
        type: PropertyType.hostel,
        bedrooms: 1,
        bathrooms: 1,
        area: 20.0,
        amenities: ['WiFi', 'Shared Kitchen', 'Lockers'],
        images: ['assets/images/img8.jpg'],
        landlordId: widget.landlord.id,
        landlordName: widget.user.name,
        landlordPhone: widget.user.phone,
        landlordEmail: widget.user.email,
        rating: 3.9,
        reviewCount: 45,
        status: PropertyStatus.booked,
        availabilityStatus: AvailabilityStatus.availableLater,
        availableFrom: DateTime.now().add(Duration(days: 14)),
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        updatedAt: DateTime.now().subtract(Duration(days: 3)),
        latitude: 0.0,
        longitude: 0.0,
        isFeatured: true,
        isVerified: true,
      ),
    ];
  }

  List<Property> get _filteredProperties {
    List<Property> filtered = _properties;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) =>
          property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          property.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          property.propertyTypeString.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
          filtered = filtered.where((p) => !p.isVerified).toList();
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
      backgroundColor: AppTheme.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsRow(),
              _filteredProperties.isEmpty
                  ? _buildEmptyState()
                  : _buildPropertiesList(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
            AppTheme.whiteColor,
            AppTheme.primaryblue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.greyColor.withValues(alpha: 0.1),
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
                      'My Properties',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_properties.length} properties listed',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyColor,
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
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isGridView = false),
                      icon: Icon(
                        Icons.view_list,
                        color: !_isGridView ? AppTheme.primaryblue : AppTheme.greyColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = true),
                      icon: Icon(
                        Icons.grid_view,
                        color: _isGridView ? AppTheme.primaryblue : AppTheme.greyColor,
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
            color: AppTheme.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.greyColor.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search properties...',
              hintStyle: TextStyle(color: AppTheme.greyColor),
              prefixIcon: Icon(Icons.search, color: AppTheme.greyColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(color: AppTheme.blackColor),
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
                      color: isSelected ? AppTheme.whiteColor : AppTheme.greyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                  },
                  backgroundColor: AppTheme.whiteColor,
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
    final availableCount = _properties.where((p) => p.status == PropertyStatus.available).length;
    final bookedCount = _properties.where((p) => p.status == PropertyStatus.booked).length;
    final underReviewCount = _properties.where((p) => !p.isVerified).length;
    final featuredCount = _properties.where((p) => p.isFeatured).length;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blackColor.withValues(alpha: 0.05),
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
            fontSize: 11,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: _isGridView ? _buildGridView() : _buildListView(),
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

  Widget _buildPropertyListCard(Property property) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blackColor.withValues(alpha: 0.05),
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
                        child: Image.asset(
                          property.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.lightGreyColor,
                              child: Icon(Icons.image_not_supported, color: AppTheme.greyColor),
                            );
                          },
                        ),
                      )
                    else
                      Center(child: Icon(Icons.home, color: AppTheme.greyColor, size: 40)),
                    
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
                                color: AppTheme.blackColor,
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
                                color: AppTheme.greyColor,
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
                            '\$${property.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryblue,
                            ),
                          ),
                          Text(
                            ' ${property.priceType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyColor,
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
                                color: AppTheme.greyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${property.reviewCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.greyColor,
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
              color: AppTheme.lightGreyColor.withValues(alpha: 0.3),
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
                      color: AppTheme.greyColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePropertyAction(value, property),
                  color: AppTheme.whiteColor,
                  surfaceTintColor: AppTheme.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: AppTheme.blackColor),
                          SizedBox(width: 8),
                          Text('View Details',
                          style: TextStyle(color: AppTheme.blackColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: AppTheme.blackColor),
                          SizedBox(width: 8),
                          Text('Edit',
                          style: TextStyle(color: AppTheme.blackColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16, color: AppTheme.blackColor),
                          SizedBox(width: 8),
                          Text('Duplicate',
                          style: TextStyle(color: AppTheme.blackColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'feature',
                      child: Row(
                        children: [
                          Icon(property.isFeatured ? Icons.star : Icons.star_border, size: 16, color: AppTheme.blackColor),
                          SizedBox(width: 8),
                          Text(property.isFeatured ? 'Unfeature' : 'Feature',
                          style: TextStyle(color: AppTheme.blackColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.whiteColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.more_vert, color: AppTheme.blackColor, size: 20),
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
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blackColor.withValues(alpha: 0.05),
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
                      child: Image.asset(
                        property.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.lightGreyColor,
                            child: Icon(Icons.image_not_supported, color: AppTheme.greyColor),
                          );
                        },
                      ),
                    )
                  else
                    Center(child: Icon(Icons.home, color: AppTheme.greyColor, size: 40)),
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
                      color: AppTheme.whiteColor,
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
                              Icon(Icons.visibility, size: 16, color: AppTheme.blackColor),
                              SizedBox(width: 8),
                              Text(
                                'View Details',
                                style: TextStyle(color: AppTheme.blackColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: AppTheme.blackColor),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(color: AppTheme.blackColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16, color: AppTheme.blackColor),
                              SizedBox(width: 8),
                              Text(
                                'Duplicate',
                                style: TextStyle(color: AppTheme.blackColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'feature',
                          child: Row(
                            children: [
                              Icon(
                                property.isFeatured ? Icons.star : Icons.star_border,
                                size: 16,
                                color: AppTheme.blackColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                property.isFeatured ? 'Unfeature' : 'Feature',
                                style: TextStyle(color: AppTheme.blackColor),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.whiteColor.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.blackColor.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.more_vert, color: AppTheme.blackColor, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
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
                      color: AppTheme.blackColor,
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
                      Icon(Icons.location_on, size: 12, color: AppTheme.greyColor),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
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
                              '\$${property.price.toStringAsFixed(0)}',
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
                                color: AppTheme.greyColor,
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
                                color: AppTheme.greyColor,
                                fontWeight: FontWeight.w600,
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
        Icon(icon, size: size, color: AppTheme.greyColor),
        SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: size - 2,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PropertyStatus status) {
    Color color;
    String text;

    switch (status) {
      case PropertyStatus.available:
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
      case PropertyStatus.unavailable:
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
                color: AppTheme.greyColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No properties found'
                  : 'No properties yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Start by adding your first property',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
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
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToAddProperty() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandlordPropertyUploadScreen(
          user: widget.user,
          landlord: widget.landlord,
          property: null,
        ),
      ),
    );
  }

  void _handlePropertyAction(String action, Property property) {
    switch (action) {
      case 'view':
        _viewPropertyDetails(property);
        break;
      case 'edit':
        _editProperty(property);
        break;
      case 'duplicate':
        _duplicateProperty(property);
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
        color: AppTheme.whiteColor,
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
              color: AppTheme.greyColor.withValues(alpha: 0.3),
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
                      color: AppTheme.blackColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.greyColor),
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
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.lightGreyColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          property.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.lightGreyColor,
                              child: Icon(Icons.image_not_supported, color: AppTheme.greyColor),
                            );
                          },
                        ),
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
                            color: AppTheme.blackColor,
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
                      Icon(Icons.location_on, color: AppTheme.greyColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.location,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.blackColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              property.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.greyColor,
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
                              '\$${property.price.toStringAsFixed(0)}',
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
                  
                  Text(
                    'Property Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreyColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Bedrooms', '${property.bedrooms}', Icons.bed),
                        _buildDetailRow('Bathrooms', '${property.bathrooms}', Icons.bathtub),
                        _buildDetailRow('Area', '${property.area.toInt()} m²', Icons.square_foot),
                        if (property.rating > 0)
                          _buildDetailRow('Rating', '${property.rating.toStringAsFixed(1)} (${property.reviewCount} reviews)', Icons.star),
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
                        color: AppTheme.blackColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      property.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyColor,
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
                        color: AppTheme.blackColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenities.map((amenity) => Container(
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
                      )).toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                  
                  Text(
                    'Property Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreyColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Created', _formatDate(property.createdAt), Icons.calendar_today),
                        _buildDetailRow('Last Updated', _formatDate(property.updatedAt), Icons.update),
                        if (property.availableFrom != null)
                          _buildDetailRow('Available From', _formatDate(property.availableFrom!), Icons.event_available),
                        _buildDetailRow('Property ID', property.id, Icons.tag),
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
          Icon(icon, size: 20, color: AppTheme.greyColor),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.blackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _editProperty(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandlordPropertyUploadScreen(
          user: widget.user,
          landlord: widget.landlord,
          property: property,
        ),
      ),
    );
  }

  void _duplicateProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.copy, color: AppTheme.primaryblue),
            SizedBox(width: 8),
            Text('Duplicate Property',
            style: TextStyle(
              color: AppTheme.blackColor
            ),),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to duplicate "${property.title}"?',
            style: TextStyle(color: AppTheme.blackColor),),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreyColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.greyColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The duplicated property will be created as a draft.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.blackColor,
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
              style: TextStyle(color: AppTheme.greyColor),
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
                      Text('Property duplicated successfully!', style: TextStyle(color: AppTheme.lightGreyColor),),
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
        backgroundColor: AppTheme.whiteColor,
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
            Text(property.isFeatured ? 'Unfeature Property' : 'Feature Property',
            style: TextStyle(color: AppTheme.blackColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.isFeatured
                  ? 'Remove "${property.title}" from featured properties?'
                  : 'Add "${property.title}" to featured properties?',
              style: TextStyle(color: AppTheme.blackColor),
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
                    color: property.isFeatured ? Colors.amber : AppTheme.primaryblue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property.isFeatured
                          ? 'Featured properties get more visibility.'
                          : 'Featured properties appear at the top of search results.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.blackColor,
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
              style: TextStyle(color: AppTheme.greyColor),
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
                        property.isFeatured
                            ? 'Property removed from featured!'
                            : 'Property added to featured!',
                      style: TextStyle(color: AppTheme.lightGreyColor),),
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
              backgroundColor: property.isFeatured ? Colors.amber : AppTheme.primaryblue,
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
        backgroundColor: AppTheme.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Property',
              style: TextStyle(
                color: AppTheme.blackColor
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${property.title}"?',
            style: TextStyle(
              color: AppTheme.blackColor
            ),),
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
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.whiteColor),
                      SizedBox(width: 8),
                      Text('Property deleted successfully!', style: TextStyle(color: AppTheme.lightGreyColor),),
                    ],
                  ),
                  duration: Duration(milliseconds: 500),
                  margin: EdgeInsets.all(16),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
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