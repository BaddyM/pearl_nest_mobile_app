import 'package:flutter/material.dart';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/chat_conversation.dart';
import 'package:pearlnest/screens/chat/individual_chat_screen.dart';
import 'package:pearlnest/screens/tenant/favorites_screen.dart';
import 'package:pearlnest/screens/tenant/notification_screen.dart';
import 'package:pearlnest/screens/tenant/profile_screen.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/search_screen.dart';
import 'package:pearlnest/screens/tenant/booking_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}



class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  List<Property> _properties = [];
  List<Property> _featuredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Airbnb', 'icon': Icons.weekend},
    {'name': 'Hostel', 'icon': Icons.hotel},
    {'name': 'Apartment', 'icon': Icons.apartment},
    {'name': 'Full House', 'icon': Icons.home},
    {'name': 'Land', 'icon': Icons.landscape},
    {'name': 'Incomplete House', 'icon': Icons.construction},
  ];

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

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _scrollController.addListener(() {
      if (_scrollController.offset >= 400) {
        if (!_showBackToTop) {
          setState(() {
            _showBackToTop = true;
          });
        }
      } else {
        if (_showBackToTop) {
          setState(() {
            _showBackToTop = false;
          });
        }
      }
    });
  }

  ChatConversation _createPearlNestConversation() {
    return ChatService.getAdminConversation(
      propertyTitle: 'General Support & Inquiries',
    );
  }

  void _navigateToPearlNestChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualChatScreen(
          conversation: _createPearlNestConversation(),
          currentUser: widget.user,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await PropertyService.getProperties();
      if (result['success'] == true) {
        setState(() {
          _properties = List<Property>.from(result['properties'] ?? []);
          _featuredProperties = _properties.where((p) => p.isFeatured).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load properties.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading properties.';
        _isLoading = false;
      });
    }
  }

  Landlord _createDummyLandlord() {
    return Landlord(
      id: widget.user.id,
      userId: widget.user.id,
      businessName: '${widget.user.name} Properties',
      businessDescription: 'Professional property management services',
      businessAddress: '123 Business St, City',
      businessPhone: widget.user.phone,
      businessEmail: widget.user.email,
      licenseNumber: 'LIC123456789',
      taxId: 'TAX987654321',
      bankAccountNumber: '1234567890',
      bankName: 'Demo Bank',
      rating: 4.5,
      totalProperties: 2,
      totalBookings: 15,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(), businessRegistrationNumber: '', verificationDocuments: [], applicationDate: DateTime.now().subtract(Duration(days: 30)),
    );
  }

  void _toggleFavorite(String propertyId) async {
    try {
      // Show loading state
      final currentIsFavorite = widget.user.favoriteProperties.contains(propertyId);
      
      // Update UI immediately for better UX
      setState(() {
        if (currentIsFavorite) {
          widget.user.favoriteProperties.remove(propertyId);
        } else {
          widget.user.favoriteProperties.add(propertyId);
        }
      });

      // Call API to sync with backend
      final result = await FavoritesService.toggleFavorite(propertyId);
      
      if (result['success'] == true) {
        // API call successful, UI already updated
        final message = currentIsFavorite ? 'Removed from favorites' : 'Added to favorites';
        
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
        // API call failed, revert UI state
        setState(() {
          if (currentIsFavorite) {
            widget.user.favoriteProperties.add(propertyId);
          } else {
            widget.user.favoriteProperties.remove(propertyId);
          }
        });
        
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
      // API call failed, revert UI state
      final currentIsFavorite = widget.user.favoriteProperties.contains(propertyId);
      setState(() {
        if (!currentIsFavorite) {
          widget.user.favoriteProperties.remove(propertyId);
        } else {
          widget.user.favoriteProperties.add(propertyId);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please check your connection and try again.'),
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

  // Helper to get full image URL
  String _getFullImageUrl(String url) {
    // Handle comma-separated URLs and filter out invalid ones
    if (url.contains(',')) {
      final urls = url.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'undefined').toList();
      if (urls.isNotEmpty) {
        url = urls.first;
      }
    }
    
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0 && _showBackToTop
          ? AnimatedOpacity(
              opacity: _showBackToTop ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                margin: EdgeInsets.only(bottom: 100),
                child: FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: AppTheme.primaryblue,
                  // ignore: sort_child_properties_last
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: AppTheme.whiteColor,
                    size: 28,
                  ),
                  mini: true,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        switch (_currentIndex) {
          0 => _buildHomeContent(),
          1 => SearchScreen(
              user: widget.user,
              allProperties: _properties,
            ),
          2 => FavoritesScreen(user: widget.user),
          3 => ProfileScreen(
              user: widget.user,
              landlord: widget.user.userType == UserType.landlord ? _createDummyLandlord() : null,
            ),
          _ => _buildHomeContent(),
        },
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomNavigationBar(),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildCategories(),
            _buildFeaturedSection(),
            _buildRecentProperties(),
            SizedBox(height: 100),
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
                      'Hello, ${widget.user.name.split(' ').first}! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.user.userType == UserType.tenant
                          ? 'Find your perfect home'
                          : 'Manage your properties',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryblue.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(user: widget.user),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.primaryblue,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryblue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryblue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.lightGreyColor,
                  backgroundImage: widget.user.profileImage != null
                      ? NetworkImage(widget.user.profileImage!)
                      : null,
                  child: widget.user.profileImage == null
                      ? Icon(Icons.person, color: AppTheme.primaryblue)
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.search, 
                      color: AppTheme.primaryblue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search properties, locations...',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune, 
                      color: AppTheme.primaryblue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryblue 
                                : AppTheme.getCardColor(context),
                            shape: BoxShape.circle,
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.primaryblue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            category['icon'],
                            color: isSelected 
                                ? AppTheme.whiteColor 
                                : AppTheme.getSecondaryTextColor(context),
                            size: 24,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                            color: isSelected 
                                ? AppTheme.primaryblue 
                                : AppTheme.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ));
                },
              ),
            ),
        ]
        
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_isLoading) {
      // Shimmer loading for featured section
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 280,
              margin: EdgeInsets.only(right: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 14,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    if (_errorMessage != null) {
      return Container(
        height: 200,
        margin: EdgeInsets.only(top: 1),
        child: Center(
          child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 5, top: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 473,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featuredProperties.length,
            itemBuilder: (context, index) {
              final property = _featuredProperties[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 16),
                child: _buildPropertyCard(property),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProperties() {
    final filteredProperties = _selectedCategory == 'All'
        ? _properties
        : _properties.where((p) => p.propertyTypeString == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            _selectedCategory == 'All' ? 'Recent Properties' : '$_selectedCategory Properties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              child: _buildPropertyCard(property),
            );
          },
        ),
        SizedBox(height: 20),
      ],
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getTextColor(context).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryblue.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: Offset(0, 4),
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
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: AppTheme.getCardColor(context),
                  ),
                  child: property.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            _getFullImageUrl(property.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.lightGreyColor,
                                      AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
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
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryblue.withValues(alpha: 0.1),
                                AppTheme.accentGreen.withValues(alpha: 0.1),
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
                
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.getTextColor(context).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryblue,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryblue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              property.propertyTypeString,
                              style: TextStyle(
                                color: AppTheme.whiteColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          if (property.isFeatured)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
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
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(property.id),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.whiteColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.getTextColor(context).withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
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
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: property.availabilityStatus == AvailabilityStatus.availableNow
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.getTextColor(context).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: AppTheme.whiteColor,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? 'Available Now'
                              : 'Available Later',
                          style: TextStyle(
                            color: AppTheme.whiteColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (property.isVerified)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.getTextColor(context).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified,
                        color: AppTheme.primaryblue,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(20),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${property.rating}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryblue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.primaryblue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  if (property.availabilityStatus == AvailabilityStatus.availableLater && property.availableFrom != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Available from ${_formatDate(property.availableFrom!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryblue.withValues(alpha: 0.1),
                          AppTheme.accentGreen.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryblue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
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
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryblue,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  property.priceType,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getSecondaryTextColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${property.reviewCount} reviews',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),
                  
                  // Quick Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              property: property,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryblue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.whiteColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Quick Book',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 30),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: Offset(0, 15),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppTheme.primaryblue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Explore',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Favorites',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.chat_outlined,
                activeIcon: Icons.chat_rounded,
                label: 'Chat',
                index: 4,
                onTap: () => _navigateToPearlNestChat(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 4) return;
    
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: onTap ?? () => _onNavItemTapped(index), // Use custom onTap if provided
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryblue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}