import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:pearlnest/apis/app_config.dart';

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

  void _loadFavoriteProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await FavoritesService.fetchFavorites();
      setState(() {
        _favoriteProperties = favorites;
        _filteredProperties = List.from(_favoriteProperties);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load favorites: ${e.toString()}',
              style: TextStyle(color: AppTheme.lightGreyColor),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _toggleFavorite(String propertyId) async {
    try {
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Removing from favorites...',
                style: TextStyle(color: AppTheme.lightGreyColor),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryblue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );

      await FavoritesService.removeFromFavorites(propertyId);
      
      // Remove from local state
      setState(() {
        _favoriteProperties.removeWhere((property) => property.id == propertyId);
        _filterProperties();
      });

      // Hide loading snackbar and show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      final snackBar = SnackBar(
        content: Text(
          'Removed from favorites',
          style: TextStyle(color: AppTheme.lightGreyColor),
        ),
        backgroundColor: AppTheme.primaryblue,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.whiteColor,
          onPressed: () async {
            try {
              await FavoritesService.addToFavorites(propertyId);
              // Reload favorites to get the updated list
              _loadFavoriteProperties();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to restore favorite: ${e.toString()}',
                    style: TextStyle(color: AppTheme.lightGreyColor),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      // Hide loading snackbar and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove from favorites: ${e.toString()}',
            style: TextStyle(color: AppTheme.lightGreyColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
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
      backgroundColor: AppTheme.getBackgroundColor(context),
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
                      'My Favorites',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_favoriteProperties.length} saved properties',
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
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(
          color: AppTheme.getTextColor(context),
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
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
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
              color: AppTheme.getSecondaryTextColor(context),
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
                  color: AppTheme.getTextColor(context),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Start exploring amazing properties and\nsave the ones you love to see them here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getSecondaryTextColor(context),
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
                      : AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryblue
                        : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
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
                            : AppTheme.getSecondaryTextColor(context),
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
            color: AppTheme.getSecondaryTextColor(context),
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No results found'
                : 'No $_selectedCategory properties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No $_selectedCategory properties in your favorites yet',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
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

  // Helper to get full image URL
  static String _getFullImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryblue.withValues(alpha: 0.2),
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
            child: SingleChildScrollView(
              child: _buildContentSection(),
            ),
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
                  child: Image.network(
                    _getFullImageUrl(property.images.first),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.lightGreyColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryblue,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.lightGreyColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.getSecondaryTextColor(context),
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
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(isHorizontal ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isHorizontal ? MainAxisAlignment.start : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: TextStyle(
                      fontSize: isHorizontal ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
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
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
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
                  if (!isHorizontal) ...[
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
                ],
              ),
              SizedBox(height: isHorizontal ? 4 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UGX ${property.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isHorizontal ? 12 : 18,
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
                ],
              ),
              if (!isHorizontal) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildPropertyFeature(Icons.bed_outlined, '${property.bedrooms}', context),
                    SizedBox(width: 16),
                    _buildPropertyFeature(Icons.bathroom_outlined, '${property.bathrooms}', context),
                    SizedBox(width: 16),
                    _buildPropertyFeature(Icons.square_foot, '${property.area.toInt()}m²', context),
                  ],
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.getSecondaryTextColor(context),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}