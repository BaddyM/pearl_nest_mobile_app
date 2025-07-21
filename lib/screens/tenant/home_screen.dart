import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/apis/notification_api_service.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/admin_list_screen.dart';
import 'package:pearlnest/screens/tenant/favorites_screen.dart';
import 'package:pearlnest/screens/tenant/notification_screen.dart';
import 'package:pearlnest/screens/tenant/profile_screen.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/search_screen.dart';
import 'package:pearlnest/screens/tenant/booking_screen.dart';
import 'package:pearlnest/screens/tenant/payment_screen.dart';
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
  List<Property> _categoryProperties = []; // Properties filtered by category
  List<Booking> _pendingBookings = []; // Pending bookings for current user
  List<Property> _pendingProperties = []; // Properties with pending bookings
  bool _isLoading = true;
  bool _isCategoryLoading = false; // Loading state for category filtering
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  int _unreadNotificationCount = 0; // Count of unread notifications
  Timer? _notificationTimer; // Timer for periodic notification refresh
  
  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProperties = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  bool _isLoadingMore = false;
  final int _pageLimit = 20;

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
  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen: initState() called for user: ${widget.user.name}');
    _loadProperties();
    _loadNotificationCount(); // Load notification count on startup
    _setupNotificationRefresh(); // Setup periodic refresh for notifications
    _scrollController.addListener(() {
      // Back to top button logic
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
      
      // Infinite scroll logic for pagination
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        if (_hasNextPage && !_isLoadingMore) {
          _loadProperties(loadMore: true);
        }
      }
    });
  }

  void _navigateToPearlNestChat() async {
    // Navigate to admin list screen instead of direct chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminListScreen(
          user: widget.user,
          propertyTitle: 'General Support & Inquiries',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationTimer?.cancel(); // Cancel notification timer
    super.dispose();
  }

  // Helper method to check if current user has favorited this property
  bool _isPropertyFavorited(Property property) {
    return property.favourites.any((favourite) => favourite['userId'] == widget.user.id);
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
      debugPrint('🤍 Toggling favorite for property: ${property.id}');
      final result = await FavoritesService.toggleFavorite(property.id);
      
      if (result['success'] == true) {
        // Success - UI is already updated optimistically
        final message = wasLiked ? 'Removed from favorites' : 'Added to favorites';
        debugPrint('✅ $message for property: ${property.id}');
        
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
        if (mounted) {
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
        }
        
        debugPrint('❌ Failed to toggle favorite for property: ${property.id}');
        
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
      debugPrint('❌ Error toggling favorite: $e');
      
      // Revert the optimistic update on error
      final wasLiked = _isPropertyFavorited(property);
      if (mounted) {
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
      }
      
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

  Future<void> _loadProperties({bool loadMore = false}) async {
    if (!mounted) return;
    
    if (loadMore) {
      if (!_hasNextPage || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }
    
    try {
      final page = loadMore ? _currentPage + 1 : 1;
      
      // Load general properties, featured properties, and pending bookings in parallel
      final [propertiesResult, featuredResult] = await Future.wait([
        PropertyService.getProperties(page: page, limit: _pageLimit),
        PropertyService.getFeaturedProperties(page: 1, limit: _pageLimit), // Featured always from page 1
      ]);
      
      if (propertiesResult['success'] == true) {
        final newProperties = List<Property>.from(propertiesResult['properties'] ?? []);
        
        // Update pagination metadata
        _currentPage = propertiesResult['page'] ?? page;
        _totalPages = propertiesResult['totalPages'] ?? 1;
        _totalProperties = propertiesResult['total'] ?? newProperties.length;
        _hasNextPage = propertiesResult['hasNextPage'] ?? false;
        _hasPrevPage = propertiesResult['hasPrevPage'] ?? false;
        
        List<Property> featuredProperties = [];
        if (featuredResult['success'] == true) {
          // Use dedicated featured properties if available
          featuredProperties = List<Property>.from(featuredResult['properties'] ?? []);
          debugPrint('🏠 Loaded ${featuredProperties.length} featured properties from dedicated API');
        } else {
          // Fallback to filtering general properties if featured API fails
          featuredProperties = newProperties.where((p) => p.isFeatured).toList();
          debugPrint('🏠 Using ${featuredProperties.length} featured properties from general properties (fallback)');
        }
        
        if (mounted) {
          setState(() {
            if (loadMore) {
              _properties.addAll(newProperties);
              _categoryProperties.addAll(newProperties);
            } else {
              _properties = newProperties;
              _featuredProperties = featuredProperties;
              _categoryProperties = List.from(newProperties); // Initialize with all properties
            }
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
        
        debugPrint('🏠 Properties loaded - General: ${_properties.length}, Featured: ${featuredProperties.length}, Page: $_currentPage/$_totalPages');
        
        // Load pending bookings after properties are loaded
        await _loadPendingBookings();
        
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = propertiesResult['message'] ?? 'Failed to load properties.';
            _categoryProperties = []; // Initialize empty category properties
            _pendingBookings = []; // Initialize empty pending bookings
            _pendingProperties = []; // Initialize empty pending properties
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading properties: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading properties.';
          _categoryProperties = []; // Initialize empty category properties
          _pendingBookings = []; // Initialize empty pending bookings
          _pendingProperties = []; // Initialize empty pending properties
          _isLoading = false;
        });
      }
    }
  }

  /// Load notification count to show badge on notification bell
  Future<void> _loadNotificationCount() async {
    try {
      final result = await NotificationApiService.getNotificationCount();
      if (result['success'] == true && mounted) {
        setState(() {
          _unreadNotificationCount = result['unreadCount'] ?? 0;
        });
        debugPrint('🔔 Notification count loaded: $_unreadNotificationCount unread');
      }
    } catch (e) {
      debugPrint('❌ Error loading notification count: $e');
      // Silently fail - not critical for app functionality
    }
  }

  /// Setup periodic refresh for notification count
  void _setupNotificationRefresh() {
    // Refresh notification count every 2 minutes
    _notificationTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadNotificationCount();
      }
    });
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

  // Handle category selection and load properties for that category
  Future<void> _onCategorySelected(String categoryName) async {
    if (_selectedCategory == categoryName) return; // Already selected
    
    setState(() {
      _selectedCategory = categoryName;
      _isCategoryLoading = true;
    });

    try {
      if (categoryName == 'All') {
        // Reset to show all properties
        if (mounted) {
          setState(() {
            _categoryProperties = List.from(_properties);
            _isCategoryLoading = false;
          });
        }
      } else {
        // Search for properties of the selected category
        debugPrint('🔍 Searching for properties of type: $categoryName');
        final searchResult = await PropertyService.searchPropertiesByType(categoryName);
        
        if (searchResult['success'] == true) {
          final categoryProps = List<Property>.from(searchResult['properties'] ?? []);
          if (mounted) {
            setState(() {
              _categoryProperties = categoryProps;
              _isCategoryLoading = false;
            });
          }
          debugPrint('✅ Found ${categoryProps.length} properties for category: $categoryName');
        } else {
          if (mounted) {
            setState(() {
              _categoryProperties = [];
              _isCategoryLoading = false;
            });
          }
          debugPrint('❌ No properties found for category: $categoryName');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading properties for category $categoryName: $e');
      if (mounted) {
        setState(() {
          _categoryProperties = [];
          _isCategoryLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load $categoryName properties'),
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

  // Load pending bookings and extract their properties
  Future<void> _loadPendingBookings() async {
    try {
      debugPrint('📚 Loading pending bookings...');
      final pendingBookings = await BookingService.fetchPendingBookings();
      
      debugPrint('📚 API returned ${pendingBookings.length} pending bookings');
      
      // Log each booking for debugging
      for (var booking in pendingBookings) {
        debugPrint('📚 Booking ID: ${booking.id}, Status: ${booking.status}, Property: ${booking.propertyId}');
      }
      
      // Extract properties from pending bookings
      final pendingPropertyIds = pendingBookings.map((b) => b.propertyId).toSet();
      final pendingProps = _properties.where(
        (property) => pendingPropertyIds.contains(property.id)
      ).toList();
      
      if (mounted) {
        setState(() {
          _pendingBookings = pendingBookings;
          _pendingProperties = pendingProps;
        });
      }
      
      debugPrint('📚 Extracted ${pendingProps.length} properties with pending bookings');
      
    } catch (e) {
      debugPrint('❌ Error loading pending bookings: $e');
      // Don't show error to user, just continue without pending bookings
      if (mounted) {
        setState(() {
          _pendingBookings = [];
          _pendingProperties = [];
        });
      }
    }
  }

  // Prioritize properties with pending bookings in the list
  List<Property> _prioritizePropertiesWithPendingBookings(List<Property> properties) {
    if (_pendingProperties.isEmpty) {
      // No pending bookings, return original list
      return properties;
    }

    // Get property IDs that have pending bookings
    final pendingPropertyIds = _pendingProperties.map((p) => p.id).toSet();
    
    // Separate properties into those with and without pending bookings
    final propertiesWithPendingBookings = <Property>[];
    final propertiesWithoutPendingBookings = <Property>[];
    
    for (final property in properties) {
      if (pendingPropertyIds.contains(property.id)) {
        propertiesWithPendingBookings.add(property);
      } else {
        propertiesWithoutPendingBookings.add(property);
      }
    }
    
    // Return prioritized list: pending bookings first, then others
    final result = [
      ...propertiesWithPendingBookings,
      ...propertiesWithoutPendingBookings,
    ];
    
    debugPrint('🏆 Prioritized properties: ${propertiesWithPendingBookings.length} with pending bookings first, ${propertiesWithoutPendingBookings.length} others');
    
    return result;
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HomeScreen: build() called for user: ${widget.user.name}');
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
          2 => FavoritesScreen(
              user: widget.user,
              onNavigateToExplore: () {
                setState(() {
                  _currentIndex = 0; // Navigate to home/explore tab
                });
              },
            ),
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

  Future<void> _onRefresh() async {
    debugPrint('🔄 HomeScreen: Refreshing data...');
    
    try {
      await Future.wait([
        _loadProperties(),
        _loadPendingBookings(),
      ]);
      
      debugPrint('✅ HomeScreen: Refresh completed');
    } catch (e) {
      debugPrint('❌ HomeScreen: Refresh failed - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryblue,
        backgroundColor: AppTheme.getBackgroundColor(context),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildCategories(),
              _buildPendingBookingsSection(),
              _buildFeaturedSection(),
              _buildRecentProperties(),
              SizedBox(height: 100),
            ],
          ),
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
                      onPressed: () async {
                        // Navigate to notification screen and refresh count when returning
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(user: widget.user),
                          ),
                        );
                        // Refresh notification count when returning from notification screen
                        _loadNotificationCount();
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.primaryblue,
                        size: 24,
                      ),
                    ),
                    // Only show red dot if there are unread notifications
                    if (_unreadNotificationCount > 0)
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
              GestureDetector(
                onTap: () { setState(() {
                _currentIndex = 3;
              });},
                child: Container(
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
                        ? NetworkImage(_getFullImageUrl(widget.user.profileImage!))
                        : null,
                    child: widget.user.profileImage == null
                        ? Icon(Icons.person, color: AppTheme.primaryblue)
                        : null,
                  ),
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
                  onTap: () => _onCategorySelected(category['name']),
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
    // Hide featured properties when a specific category is selected
    if (_selectedCategory != 'All') {
      return SizedBox.shrink(); // Return empty widget
    }
    
    if (_isLoading) {
      // Shimmer loading for featured section
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
          ),
        ]
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

    // Handle empty featured properties case
    if (_featuredProperties.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 8, top: 8),
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
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_outline,
                      size: 40,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Featured Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for amazing featured properties!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Explore All Properties',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
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
              // Only show "See All" when there are featured properties
              if (_featuredProperties.isNotEmpty)
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
          height: 480, // Reduced from 473 to prevent overflow
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
    // Use category properties if a specific category is selected and loaded
    List<Property> baseProperties = _selectedCategory == 'All'
        ? _properties
        : _categoryProperties;

    // Prioritize properties with pending bookings
    final filteredProperties = _prioritizePropertiesWithPendingBookings(baseProperties);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory == 'All' 
                    ? 'Recent Properties' 
                    : '$_selectedCategory Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              if (_isCategoryLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                  ),
                ),
            ],
          ),
        ),
        
        if (_isCategoryLoading)
          // Show loading shimmer for category properties
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          )
        else if (filteredProperties.isEmpty && _selectedCategory != 'All')
          // Show empty state for category with no properties
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 40,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No $_selectedCategory Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try searching for a different property type.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          // Show properties list
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: filteredProperties.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end when loading more
              if (index == filteredProperties.length) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading more properties...',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final property = filteredProperties[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: _buildPropertyCard(property),
              );
            },
          ),
        
        // Pagination info
        if (filteredProperties.isNotEmpty && _totalPages > 1) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${filteredProperties.length} of $_totalProperties properties',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
        
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
                        onTap: () => _toggleFavorite(property),
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
                            _isPropertyFavorited(property)
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: _isPropertyFavorited(property)
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
              padding: EdgeInsets.all(16), // Reduced from 20 to prevent overflow
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
                  
                  SizedBox(height: 10), // Reduced from 12
                  
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
                  
                  SizedBox(height: 12), // Reduced from 16
                  
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

                  SizedBox(height: 10), // Reduced from 12
                  
                  // Conditional booking/payment button
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(property),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBookingsSection() {
    // Only show pending bookings section if there are pending bookings
    if (_pendingBookings.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      '${_pendingBookings.length} ${_pendingBookings.length == 1 ? 'property' : 'properties'} waiting for payment',
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
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _pendingProperties.length,
            itemBuilder: (context, index) {
              final property = _pendingProperties[index];
              final booking = _getPendingBookingForProperty(property.id);
              
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 16),
                child: _buildPendingPropertyCard(property, booking),
              );
            },
          ),
        ),
      ],
    );
  }

  // Get pending booking for a specific property
  Booking? _getPendingBookingForProperty(String propertyId) {
    try {
      return _pendingBookings.firstWhere(
        (booking) => booking.propertyId == propertyId,
      );
    } catch (e) {
      return null; // No pending booking found
    }
  }

  Widget _buildPendingPropertyCard(Property property, Booking? booking) {
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
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with pending indicator
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    color: AppTheme.getCardColor(context),
                  ),
                  child: property.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: Image.network(
                            _getFullImageUrl(property.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.getSecondaryTextColor(context),
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
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
                              size: 40,
                            ),
                          ),
                        ),
                ),
                
                // Pending payment indicator
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PENDING PAYMENT',
                          style: TextStyle(
                            color: Colors.white,
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
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UGX $formattedPrice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      if (booking != null)
                        GestureDetector(
                          onTap: () => _showCancelBookingDialog(booking),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  // Build action button based on property booking status
  Widget _buildActionButton(Property property) {
    final pendingBooking = _getPendingBookingForProperty(property.id);
    
    if (pendingBooking != null) {
      // Property has pending booking - show payment button
      return ElevatedButton(
        onPressed: () => _initiatePayment(property, pendingBooking),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
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
              Icons.payment,
              color: AppTheme.whiteColor,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Complete Payment',
              style: TextStyle(
                color: AppTheme.whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      // Property has no pending booking - show quick book button
      return ElevatedButton(
        onPressed: () async {
          final bool? bookingCreated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(
                property: property,
                user: widget.user,
              ),
            ),
          );
          
          // If booking was created successfully, refresh the data
          if (bookingCreated == true) {
            _loadProperties(); // This will also trigger _loadPendingBookings()
          }
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
      );
    }
  }

  // Initiate payment for a pending booking
  Future<void> _initiatePayment(Property property, Booking booking) async {
    // First show dialog to get payment amount
    final double? paymentAmount = await _showPaymentAmountDialog(property);
    
    if (paymentAmount == null) {
      // User cancelled the dialog
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                ),
                SizedBox(height: 16),
                Text(
                  'Preparing Payment...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we set up your payment',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      debugPrint('💳 Initiating payment for booking: ${booking.id} with amount: UGX ${NumberFormat('#,##0').format(paymentAmount)}');
      
      // Debug user ID to identify the issue
      debugPrint('🔍 User ID validation:');
      debugPrint('   - widget.user.id: "${widget.user.id}"');
      debugPrint('   - widget.user.id.isEmpty: ${widget.user.id.isEmpty}');
      debugPrint('   - widget.user.id.length: ${widget.user.id.length}');
      debugPrint('   - widget.user.name: "${widget.user.name}"');
      debugPrint('   - widget.user.email: "${widget.user.email}"');
      
      // Validate user ID before making payment request
      if (widget.user.id.isEmpty) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        debugPrint('❌ User ID is empty - attempting to get from AuthService');
        
        // Try to get user ID from AuthService as fallback
        final currentUserId = await AuthService.getUserId();
        debugPrint('🔍 AuthService.getUserId() returned: "$currentUserId"');
        
        if (currentUserId == null || currentUserId.isEmpty) {
          _showPaymentError('User session invalid. Please logout and login again.');
          return;
        }
        
        debugPrint('✅ Using fallback user ID: $currentUserId');
        
        // Show loading dialog again
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Preparing Payment...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we set up your payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        
        // Create payment with the fallback user ID
        final paymentResult = await PaymentService.createPayment(
          userId: currentUserId,
          bookingId: booking.id,
          propertyId: property.id,
          amount: paymentAmount,
        );
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        if (paymentResult['success'] == true) {
          final String? redirectUrl = paymentResult['redirectUrl'];
          final String? orderTrackingId = paymentResult['orderTrackingId'];
          final String? merchantReference = paymentResult['merchantReference'];

          if (redirectUrl != null && orderTrackingId != null && merchantReference != null) {
            // Navigate to payment screen
            final bool? paymentSuccess = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  redirectUrl: redirectUrl,
                  orderTrackingId: orderTrackingId,
                  merchantReference: merchantReference,
                  amount: paymentAmount,
                  propertyTitle: property.title,
                  user: widget.user,
                ),
              ),
            );

            if (paymentSuccess == true) {
              // Payment successful - refresh data
              _loadProperties();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment completed successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                    margin: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          } else {
            _showPaymentError('Payment setup incomplete. Please try again.');
          }
        } else {
          _showPaymentError(paymentResult['message'] ?? 'Failed to create payment. Please try again.');
        }
        
        return; // Return early since we handled the payment with fallback ID
      }
      
      // Create payment with the user-specified amount
      final paymentResult = await PaymentService.createPayment(
        userId: widget.user.id,
        bookingId: booking.id,
        propertyId: property.id,
        amount: paymentAmount, // Use the user-specified amount instead of property.price
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (paymentResult['success'] == true) {
        final String? redirectUrl = paymentResult['redirectUrl'];
        final String? orderTrackingId = paymentResult['orderTrackingId'];
        final String? merchantReference = paymentResult['merchantReference'];

        if (redirectUrl != null && orderTrackingId != null && merchantReference != null) {
          // Navigate to payment screen
          final bool? paymentSuccess = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                redirectUrl: redirectUrl,
                orderTrackingId: orderTrackingId,
                merchantReference: merchantReference,
                amount: paymentAmount, // Use the user-specified amount
                propertyTitle: property.title,
                user: widget.user,
              ),
            ),
          );

          if (paymentSuccess == true) {
            // Payment successful - refresh data
            _loadProperties();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment completed successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        } else {
          _showPaymentError('Payment setup incomplete. Please try again.');
        }
      } else {
        _showPaymentError(paymentResult['message'] ?? 'Failed to create payment. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      debugPrint('❌ Payment initiation error: $e');
      _showPaymentError('An error occurred while setting up payment. Please try again.');
    }
  }

  // Show payment error dialog
  void _showPaymentError(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Payment Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to get payment amount from user
  Future<double?> _showPaymentAmountDialog(Property property) async {
    final TextEditingController amountController = TextEditingController();
    final formattedPropertyPrice = NumberFormat('#,##0').format(property.price);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    return await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment,
                  color: AppTheme.primaryblue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property: ${property.title}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Full Price: UGX $formattedPropertyPrice',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Enter the amount you want to pay to secure this booking:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    hintText: 'Enter amount (UGX)',
                    prefixText: 'UGX ',
                    prefixStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryblue,
                    ),
                    filled: true,
                    fillColor: AppTheme.getBackgroundColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    
                    final double? amount = double.tryParse(value.trim().replaceAll(',', ''));
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    
                    if (amount > property.price) {
                      return 'Amount cannot exceed UGX $formattedPropertyPrice';
                    }
                    
                    return null;
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryblue,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can pay any amount up to the full property price to secure your booking.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryblue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final String value = amountController.text.trim().replaceAll(',', '');
                        final double amount = double.parse(value);
                        Navigator.of(context).pop(amount);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
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
  
  if (index == 0 && _currentIndex == 0) {
    debugPrint('🏠 HomeScreen: Home icon tapped while on home - triggering refresh');
    
    HapticFeedback.lightImpact();
    
    _onRefresh();
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    return;
  }
  
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
      onTap: onTap ?? () => _onNavItemTapped(index),
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
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for canceling a booking
  void _showCancelBookingDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<BookingBloc>(),
        child: BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (!mounted) return; // Safety check
            
            if (state is BookingSuccess) {
              Navigator.of(context).pop(); // Close dialog
              _showSuccessSnackBar('Booking cancelled successfully');
              debugPrint('✅ Booking cancellation successful, refreshing all data...');
              // Add slight delay to ensure server has processed the update
              Future.delayed(Duration(milliseconds: 1000), () {
                if (mounted) {
                  _onRefresh(); // Use full refresh instead of just pending bookings
                }
              });
            } else if (state is BookingFailure) {
              Navigator.of(context).pop(); // Close dialog
              debugPrint('❌ Booking cancellation failed: ${state.error}');
              _showErrorSnackBar(state.error);
            }
          },
          child: AlertDialog(
            backgroundColor: AppTheme.getCardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel this booking?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID: ${booking.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Check-in: ${booking.checkInDate != null ? DateFormat('MMM dd, yyyy').format(booking.checkInDate!) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      Text(
                        'Check-out: ${booking.checkOutDate != null ? DateFormat('MMM dd, yyyy').format(booking.checkOutDate!) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Keep Booking',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, state) {
                  final isLoading = state is BookingLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : () {
                      try {
                        if (mounted) {
                          context.read<BookingBloc>().add(
                            BookingStatusUpdateRequested(
                              bookingId: booking.id,
                              status: 'REJECTED',
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Error adding booking event: $e');
                        Navigator.of(context).pop(); // Close dialog
                        _showErrorSnackBar('Unable to cancel booking. Please try again.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Cancel Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for showing feedback
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}