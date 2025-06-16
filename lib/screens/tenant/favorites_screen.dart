import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  final User user;

  const FavoritesScreen({super.key, required this.user});

  @override
  // ignore: library_private_types_in_public_api
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  List<Property> _favoriteProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isGridView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'All',
    'Airbnb',
    'Hostel',
    'Apartment',
    'Full House',
    'Land',
    'Incomplete House',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadFavoriteProperties();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadFavoriteProperties() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _favoriteProperties = _getDummyFavoriteProperties();
        _filteredProperties = List.from(_favoriteProperties);
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  List<Property> _getDummyFavoriteProperties() {
    return [
      Property(
        id: '1',
        title: 'Luxury Downtown Apartment',
        description: 'Beautiful modern apartment with stunning city views and premium amenities',
        type: PropertyType.apartment,
        price: 2500000,
        priceType: 'per month',
        location: 'Downtown',
        address: '123 Main St, City Center',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'assets/images/img5.jpg',
          'assets/images/img3.jpg',
          'assets/images/img4.jpg',
          'assets/images/img1.jpg',
        ],
        amenities: ['WiFi', 'Parking', 'Gym', 'Pool', 'Security'],
        bedrooms: 3,
        bathrooms: 2,
        area: 120.0,
        landlordId: 'landlord1',
        landlordName: 'John Smith',
        landlordPhone: '+1234567890',
        status: PropertyStatus.available,
        rating: 4.8,
        reviewCount: 45,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow,
        landlordEmail: '',
      ),
      Property(
        id: '2',
        title: 'Cozy Family House',
        description: 'Spacious family home in quiet neighborhood with garden',
        type: PropertyType.fullHouse,
        price: 3500000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '456 Oak Avenue, Residential Area',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'assets/images/img8.jpg',
          'assets/images/img4.jpg',
          'assets/images/img1.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['WiFi', 'Parking', 'Garden', 'Security'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord2',
        landlordName: 'Jane Doe',
        landlordPhone: '+1234567891',
        status: PropertyStatus.available,
        rating: 4.6,
        reviewCount: 32,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow,
        landlordEmail: '',
      ),
      Property(
        id: '3',
        title: 'Modern Airbnb Studio',
        description: 'Perfect for short stays with all modern amenities',
        type: PropertyType.airbnb,
        price: 150000,
        priceType: 'per night',
        location: 'Tourist District',
        address: '789 Beach Road, Tourist Area',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'assets/images/img2.jpg',
          'assets/images/img1.jpg',
          'assets/images/img3.jpg',
        ],
        amenities: ['WiFi', 'Kitchen', 'AC', 'TV'],
        bedrooms: 1,
        bathrooms: 1,
        area: 45.0,
        landlordId: 'landlord3',
        landlordName: 'Mike Johnson',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.9,
        reviewCount: 78,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow,
        landlordEmail: '',
      ),
    ];
  }

  void _toggleFavorite(String propertyId) {
    setState(() {
      if (widget.user.favoriteProperties.contains(propertyId)) {
        widget.user.favoriteProperties.remove(propertyId);
        _favoriteProperties.removeWhere((property) => property.id == propertyId);
        _filterProperties();
      }
    });

    final scaffold = ScaffoldMessenger.of(context);
    final snackBar = SnackBar(
      content: Text(
        'Removed from favorites',
        style: TextStyle(color: AppTheme.lightGreyColor),
      ),
      backgroundColor: AppTheme.primaryblue,
      duration: Duration(milliseconds: 500),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: AppTheme.whiteColor,
        onPressed: () {
        },
      ),
    );

    scaffold.showSnackBar(snackBar);

    Future.delayed(Duration(milliseconds: 500), () {
      scaffold.hideCurrentSnackBar();
    });
  }

  void _filterProperties() {
    setState(() {
      List<Property> filtered = _favoriteProperties;

      if (_selectedCategory != 'All') {
        filtered = filtered
            .where((property) => property.propertyTypeString == _selectedCategory)
            .toList();
      }
      
      if (_searchQuery.isNotEmpty) {
        filtered = filtered
            .where((property) =>
                property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                property.location.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      
      _filteredProperties = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGreyColor.withValues(alpha: 0.5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _favoriteProperties.isEmpty
                      ? _buildEmptyState()
                      : _buildFavoritesContent(),
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
                      'My Favorites',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_favoriteProperties.length} saved properties',
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
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: AppTheme.primaryblue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.greyColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(
          color: AppTheme.blackColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterProperties();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search your favorites...',
          hintStyle: TextStyle(color: AppTheme.greyColor),
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryblue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
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
            'Loading your favorites...',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: 80,
                  color: AppTheme.primaryblue,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No Favorites Yet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Start exploring amazing properties and\nsave the ones you love to see them here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.greyColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.explore),
                label: Text('Explore Properties'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryblue,
                  foregroundColor: AppTheme.whiteColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildCategoriesRow(),
          Expanded(
            child: _filteredProperties.isEmpty
                ? _buildNoResultsState()
                : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            final count = category == 'All' 
                ? _favoriteProperties.length 
                : _favoriteProperties.where((p) => p.propertyTypeString == category).length;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _filterProperties();
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryblue
                      : AppTheme.whiteColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryblue
                        : AppTheme.greyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryblue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.whiteColor
                            : AppTheme.greyColor,
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.whiteColor.withValues(alpha: 0.2)
                              : AppTheme.primaryblue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? AppTheme.whiteColor
                                : AppTheme.primaryblue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list_off,
            size: 60,
            color: AppTheme.greyColor,
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No results found'
                : 'No $_selectedCategory properties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No $_selectedCategory properties in your favorites yet',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredProperties.length,
        itemBuilder: (context, index) {
          final property = _filteredProperties[index];
          return PropertyCard(
            property: property,
            isHorizontal: false,
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
            onFavorite: () {
              _toggleFavorite(property.id);
            },
            isFavorite: true,
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _filteredProperties.length,
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 16),
          child: PropertyCard(
            property: property,
            isHorizontal: true,
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
            onFavorite: () {
              _toggleFavorite(property.id);
            },
            isFavorite: true,
          ),
        );
      },
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final bool isHorizontal;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.greyColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontalLayout() : _buildVerticalLayout(),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: _buildImageSection(),
        ),
        Expanded(
          child: Container(
            height: 120,
            padding: EdgeInsets.all(12),
            child: _buildContentSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          height: isHorizontal ? double.infinity : 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isHorizontal ? Radius.circular(16) : Radius.zero,
              bottomRight: isHorizontal ? Radius.zero : Radius.zero,
            ),
            color: AppTheme.lightGreyColor,
          ),
          child: property.images.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: isHorizontal ? Radius.circular(16) : Radius.zero,
                    bottomRight: isHorizontal ? Radius.zero : Radius.zero,
                  ),
                  child: Image.asset(
                    property.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.lightGreyColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.greyColor,
                          size: 40,
                        ),
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.home,
                  color: AppTheme.greyColor,
                  size: 40,
                ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.greyColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_outline,
                color: isFavorite ? Colors.red : AppTheme.greyColor,
                size: 20,
              ),
            ),
          ),
        ),
        if (property.isFeatured)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue,
                borderRadius: BorderRadius.circular(8),
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
          ),
        if (property.isVerified)
          Positioned(
            bottom: isHorizontal ? 12 : -8,
            left: 12,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: AppTheme.whiteColor,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(isHorizontal ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isHorizontal ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property.title,
                style: TextStyle(
                  fontSize: isHorizontal ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
                maxLines: isHorizontal ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppTheme.greyColor,
                  ),
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
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.propertyTypeString,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isHorizontal ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UGX ${property.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isHorizontal ? 14 : 18,
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
            ],
          ),
          if (!isHorizontal) ...[
            SizedBox(height: 8),
            Row(
              children: [
                _buildPropertyFeature(Icons.bed_outlined, '${property.bedrooms}'),
                SizedBox(width: 16),
                _buildPropertyFeature(Icons.bathroom_outlined, '${property.bathrooms}'),
                SizedBox(width: 16),
                _buildPropertyFeature(Icons.square_foot, '${property.area.toInt()}m²'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.greyColor,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }
}