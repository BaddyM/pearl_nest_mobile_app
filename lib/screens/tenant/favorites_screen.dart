import 'package:flutter/material.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:pearlnest/apis/app_config.dart';

class FavoritesScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onNavigateToExplore;

  const FavoritesScreen({
    super.key,
    required this.user,
    this.onNavigateToExplore,
  });

  @override
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

  Map<String, dynamic> _getResponsiveValues(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;

    return {
      'isSmallScreen': isSmallScreen,
      'isVerySmallScreen': isVerySmallScreen,
      'isNarrowScreen': isNarrowScreen,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'horizontalPadding': isNarrowScreen
          ? 12.0
          : isSmallScreen
              ? 16.0
              : 20.0,
      'verticalPadding': isSmallScreen ? 12.0 : 16.0,
      'titleFontSize': isVerySmallScreen
          ? 22.0
          : isSmallScreen
              ? 25.0
              : 28.0,
      'subtitleFontSize': isSmallScreen ? 12.0 : 14.0,
      'cardSpacing': isSmallScreen ? 12.0 : 16.0,
      'borderRadius': isSmallScreen ? 12.0 : 16.0,
    };
  }

  void _loadFavoriteProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    try {
      final favorites = await FavoritesService.fetchFavorites();
      
      if (!mounted) return;
      
      setState(() {
        _favoriteProperties = favorites;
        _filteredProperties = List.from(_favoriteProperties);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

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

  // Helper method to check if current user has favorited this property
  // In FavoritesScreen, all properties are favorited by definition since they come from favorites API
  // We only check if the property still exists in our local favorites list
  bool _isPropertyFavorited(Property property) {
    // Since this is the favorites screen, properties are favorited by default
    // unless they've been removed from our local list
    return _favoriteProperties.any((favProp) => favProp.id == property.id);
  }

  void _toggleFavorite(Property property) async {
    final responsive = _getResponsiveValues(context);

    try {
      final wasLiked = _isPropertyFavorited(property);

      // Since this is favorites screen, properties should always be "liked" initially
      // So tapping the heart should remove from favorites
      if (!wasLiked) {
        // This shouldn't happen in favorites screen, but handle it just in case
        //debugPrint('⚠️ Property not found in favorites list, this is unexpected in FavoritesScreen');
        return;
      }

      // Show loading feedback
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
              Expanded(
                child: Text(
                  'Removing from favorites...',
                  style: TextStyle(
                    color: AppTheme.lightGreyColor,
                    fontSize: responsive['subtitleFontSize'],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryblue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(responsive['horizontalPadding']),
        ),
      );

      // Make API call to sync with server using the working toggle method
      //debugPrint('🤍 Toggling favorite for property: ${property.id}');
      final result = await FavoritesService.toggleFavorite(property.id);

      // Hide loading message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success'] == true) {
        // Success - remove from local lists and update UI
        //debugPrint('✅ Removed from favorites for property: ${property.id}');

        if (!mounted) return;

        setState(() {
          // Remove from favorites list since it was toggled off
          _favoriteProperties.removeWhere((prop) => prop.id == property.id);
        });
        
        // Filter properties after state update
        _filterProperties();

        // Show success feedback with undo option
        if (mounted) {
          final snackBar = SnackBar(
            content: Text(
              'Removed from favorites',
              style: TextStyle(
                color: AppTheme.lightGreyColor,
                fontSize: responsive['subtitleFontSize'],
              ),
            ),
            backgroundColor: AppTheme.primaryblue,
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(responsive['horizontalPadding']),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppTheme.whiteColor,
              onPressed: () async {
                try {
                  // Toggle back to add to favorites
                  final undoResult = await FavoritesService.toggleFavorite(property.id);
                  if (undoResult['success'] == true) {
                    // Reload favorites to restore the item
                    _loadFavoriteProperties();
                  } else {
                    throw Exception('Failed to restore favorite');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to restore favorite: ${e.toString()}',
                        style: TextStyle(color: AppTheme.lightGreyColor),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(responsive['horizontalPadding']),
                    ),
                  );
                }
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        // API call failed, show error
        //debugPrint('❌ Failed to toggle favorite for property: ${property.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update favorites. Please try again.',
                style: TextStyle(color: AppTheme.lightGreyColor),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.all(responsive['horizontalPadding']),
            ),
          );
        }
      }
    } catch (e) {
      //debugPrint('❌ Error toggling favorite: $e');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred. Please try again.',
              style: TextStyle(color: AppTheme.lightGreyColor),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(responsive['horizontalPadding']),
          ),
        );
      }
    }
  }

  void _filterProperties() {
    if (!mounted) return;
    
    setState(() {
      List<Property> filtered = _favoriteProperties;
      if (_selectedCategory != 'All') {
        filtered = filtered.where((property) => property.propertyTypeString == _selectedCategory).toList();
      }

      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((property) => property.title.toLowerCase().contains(_searchQuery.toLowerCase()) || property.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
    final responsive = _getResponsiveValues(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive['horizontalPadding'],
        vertical: responsive['verticalPadding'],
      ),
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
          bottomLeft: Radius.circular(responsive['borderRadius'] + 9),
          bottomRight: Radius.circular(responsive['borderRadius'] + 9),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'My Favorites',
                        style: TextStyle(
                          fontSize: responsive['titleFontSize'],
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_favoriteProperties.length} saved properties',
                      style: TextStyle(
                        fontSize: responsive['subtitleFontSize'],
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive['borderRadius'] - 4),
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
                    size: responsive['isSmallScreen'] ? 20 : 24,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive['verticalPadding']),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final responsive = _getResponsiveValues(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(responsive['borderRadius'] - 1),
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
          fontSize: responsive['isSmallScreen'] ? 14 : 16,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterProperties();
        },
        decoration: InputDecoration(
          hintText: 'Search your favorites...',
          hintStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: responsive['isSmallScreen'] ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryblue,
            size: responsive['isSmallScreen'] ? 20 : 24,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive['horizontalPadding'],
            vertical: responsive['verticalPadding'] - 4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final responsive = _getResponsiveValues(context);

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
              fontSize: responsive['subtitleFontSize'] + 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final responsive = _getResponsiveValues(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(responsive['horizontalPadding'] * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(responsive['isSmallScreen'] ? 20 : 30),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: responsive['isSmallScreen'] ? 60 : 80,
                  color: AppTheme.primaryblue,
                ),
              ),
              SizedBox(height: 24),
              FittedBox(
                child: Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    fontSize: responsive['titleFontSize'],
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Start exploring amazing properties and\nsave the ones you love to see them here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive['subtitleFontSize'] + 2,
                  color: AppTheme.getSecondaryTextColor(context),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Use the callback to navigate to explore tab if available
                  if (widget.onNavigateToExplore != null) {
                    widget.onNavigateToExplore!();
                  } else {
                    // Fallback for when used outside of HomeScreen
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  Icons.explore,
                  size: responsive['isSmallScreen'] ? 18 : 20,
                ),
                label: Text(
                  'Explore Properties',
                  style: TextStyle(
                    fontSize: responsive['subtitleFontSize'] + 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryblue,
                  foregroundColor: AppTheme.whiteColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive['isSmallScreen'] ? 20 : 24,
                    vertical: responsive['isSmallScreen'] ? 10 : 12,
                  ),
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
            child: _filteredProperties.isEmpty ? _buildNoResultsState() : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    final responsive = _getResponsiveValues(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: responsive['verticalPadding']),
      child: SizedBox(
        height: responsive['isSmallScreen'] ? 40 : 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: responsive['horizontalPadding']),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            final count = category == 'All' ? _favoriteProperties.length : _favoriteProperties.where((p) => p.propertyTypeString == category).length;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _filterProperties();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: responsive['isSmallScreen'] ? 8 : 12),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive['isSmallScreen'] ? 12 : 16,
                  vertical: responsive['isSmallScreen'] ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryblue : AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryblue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: responsive['isSmallScreen'] ? 12 : 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive['isSmallScreen'] ? 4 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.whiteColor.withValues(alpha: 0.2) : AppTheme.primaryblue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: responsive['isSmallScreen'] ? 8 : 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.whiteColor : AppTheme.primaryblue,
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
    final responsive = _getResponsiveValues(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list_off,
            size: responsive['isSmallScreen'] ? 50 : 60,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No $_selectedCategory properties',
            style: TextStyle(
              fontSize: responsive['isSmallScreen'] ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Try adjusting your search terms' : 'No $_selectedCategory properties in your favorites yet',
            style: TextStyle(
              fontSize: responsive['subtitleFontSize'],
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    final responsive = _getResponsiveValues(context);

    if (_isGridView) {
      int crossAxisCount = 2;
      double childAspectRatio = 0.69;
      double crossAxisSpacing = 12.0;
      double mainAxisSpacing = 12.0;

      if (MediaQuery.of(context).size.width < 380) {
        crossAxisCount = 1;
        childAspectRatio = 1.2;
      }

      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
          responsive['horizontalPadding'],
          responsive['verticalPadding'],
          responsive['horizontalPadding'],
          100,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
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
              _toggleFavorite(property);
            },
            isFavorite: true,
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        responsive['horizontalPadding'],
        responsive['verticalPadding'],
        responsive['horizontalPadding'],
        100,
      ),
      itemCount: _filteredProperties.length,
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: responsive['cardSpacing']),
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
              _toggleFavorite(property);
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

  static String _getFullImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }

  Map<String, dynamic> _getResponsiveCardValues(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    final isBigScreen = screenWidth > 600;

    return {
      'isSmallScreen': isSmallScreen,
      'isVerySmallScreen': isVerySmallScreen,
      'isNarrowScreen': isNarrowScreen,
      'isBigScreen': isBigScreen,
      'borderRadius': isSmallScreen ? 12.0 : 16.0,
      'padding': isSmallScreen ? 10.0 : 12.0,
      'smallPadding': isSmallScreen ? 8.0 : 10.0,
      'imageHeight': isHorizontal
          ? (isSmallScreen ? 100.0 : 120.0)
          : (isVerySmallScreen
              ? 120.0
              : isSmallScreen
                  ? 140.0
                  : 150.0),
      'imageWidth': isHorizontal ? (isSmallScreen ? 100.0 : 120.0) : double.infinity,
      'titleFontSize': isHorizontal ? (isSmallScreen ? 13.0 : 14.0) : (isSmallScreen ? 13.0 : 14.0),
      'priceFontSize': isHorizontal ? (isSmallScreen ? 11.0 : 12.0) : (isSmallScreen ? 14.0 : 16.0),
      'subtitleFontSize': isSmallScreen ? 10.0 : 11.0,
      'iconSize': isSmallScreen ? 12.0 : 13.0,
      'favIconSize': isSmallScreen ? 18.0 : 20.0,
      'badgeFontSize': isSmallScreen ? 8.0 : 9.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final responsive = _getResponsiveCardValues(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(responsive['borderRadius']),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryblue.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontalLayout() : _buildVerticalLayout(),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Builder(builder: (context) {
      final responsive = _getResponsiveCardValues(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          Container(
            padding: EdgeInsets.all(responsive['padding']),
            child: _buildContentSection(),
          ),
        ],
      );
    });
  }

  Widget _buildHorizontalLayout() {
    return Builder(builder: (context) {
      final responsive = _getResponsiveCardValues(context);

      return IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: responsive['imageWidth'],
              child: _buildImageSection(),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(responsive['smallPadding']),
                child: _buildContentSection(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImageSection() {
    return Builder(builder: (context) {
      final responsive = _getResponsiveCardValues(context);

      return Stack(
        children: [
          Container(
            height: responsive['imageHeight'],
            width: responsive['imageWidth'],
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive['borderRadius']),
                topRight: Radius.circular(responsive['borderRadius']),
                bottomLeft: isHorizontal ? Radius.circular(responsive['borderRadius']) : Radius.zero,
                bottomRight: isHorizontal ? Radius.zero : Radius.zero,
              ),
              color: AppTheme.lightGreyColor,
            ),
            child: property.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(responsive['borderRadius']),
                      topRight: Radius.circular(responsive['borderRadius']),
                      bottomLeft: isHorizontal ? Radius.circular(responsive['borderRadius']) : Radius.zero,
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
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
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
                            size: responsive['isSmallScreen'] ? 30 : 40,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.home,
                    color: AppTheme.greyColor,
                    size: responsive['isSmallScreen'] ? 30 : 40,
                  ),
          ),

          // Favorite button
          Positioned(
            top: responsive['isSmallScreen'] ? 8 : 12,
            right: responsive['isSmallScreen'] ? 8 : 12,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                padding: EdgeInsets.all(responsive['isSmallScreen'] ? 6 : 8),
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
                  size: responsive['favIconSize'],
                ),
              ),
            ),
          ),

          // Featured badge
          if (property.isFeatured)
            Positioned(
              top: responsive['isSmallScreen'] ? 8 : 12,
              left: responsive['isSmallScreen'] ? 8 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive['isSmallScreen'] ? 6 : 8,
                  vertical: responsive['isSmallScreen'] ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue,
                  borderRadius: BorderRadius.circular(responsive['isSmallScreen'] ? 6 : 8),
                ),
                child: Text(
                  'Featured',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: responsive['badgeFontSize'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Verified badge
          if (property.isVerified)
            Positioned(
              bottom: isHorizontal ? (responsive['isSmallScreen'] ? 8 : 12) : -8,
              left: responsive['isSmallScreen'] ? 8 : 12,
              child: Container(
                padding: EdgeInsets.all(responsive['isSmallScreen'] ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  color: AppTheme.whiteColor,
                  size: responsive['isSmallScreen'] ? 12 : 16,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildContentSection() {
    return Builder(builder: (context) {
      final responsive = _getResponsiveCardValues(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title - single line only
          Text(
            property.title,
            style: TextStyle(
              fontSize: responsive['titleFontSize'],
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4),

          // Location - single line only
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: responsive['iconSize'],
                color: AppTheme.getSecondaryTextColor(context),
              ),
              SizedBox(width: 2),
              Expanded(
                child: Text(
                  property.location,
                  style: TextStyle(
                    fontSize: responsive['subtitleFontSize'],
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 6),

          // Price - single line
          Text(
            'UGX ${property.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: responsive['priceFontSize'],
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryblue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Price type - single line
          Text(
            property.priceType,
            style: TextStyle(
              fontSize: responsive['badgeFontSize'],
              color: AppTheme.getSecondaryTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Features - only show if not horizontal and enough space
          if (!isHorizontal) ...[
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactFeature(Icons.bed_outlined, '${property.bedrooms}', context, responsive),
                _buildCompactFeature(Icons.bathroom_outlined, '${property.bathrooms}', context, responsive),
                _buildCompactFeature(Icons.square_foot, '${property.area.toInt()}m²', context, responsive),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCompactFeature(
    IconData icon,
    String text,
    BuildContext context,
    Map<String, dynamic> responsive,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: responsive['iconSize'],
          color: AppTheme.getSecondaryTextColor(context),
        ),
        SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: responsive['subtitleFontSize'],
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}
