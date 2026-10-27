import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import 'package:pearlnest/apis/app_config.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/favorites_service.dart';
import 'package:pearlnest/apis/payment_service.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_event.dart';
import 'package:pearlnest/blocs/booking/booking_state.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/booking.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/chat/new_chat_list.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/tenant/bookings_list_screen.dart';
import 'package:pearlnest/screens/tenant/favorites_screen.dart';
import 'package:pearlnest/screens/tenant/notification_screen.dart';
import 'package:pearlnest/screens/tenant/profile_screen.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/search_screen.dart';
import 'package:pearlnest/screens/tenant/payment_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressTime;
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
  final ScrollController _categoryScrollController = ScrollController();
  bool _showBackToTop = false;
  int _unreadNotificationCount = 0; // Count of unread notifications
  Timer? _notificationTimer; // Timer for periodic notification refresh
  Timer? _categoryAutoScrollTimer;
  Timer? _categoryRefreshTimer;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProperties = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  bool _isLoadingMore = false;
  final int _pageLimit = 20;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'key': 'All', 'icon': Icons.apps},
    {'name': 'Airbnb', 'key': 'air_bnb', 'icon': Icons.weekend},
    {'name': 'Hostel', 'key': 'hostel', 'icon': Icons.hotel},
    {'name': 'Apartment', 'key': 'apartment', 'icon': Icons.apartment},
    {'name': 'Full House', 'key': 'full_house', 'icon': Icons.home},
    {'name': 'Land', 'key': 'land', 'icon': Icons.landscape},
    {'name': 'Rental', 'key': 'rentals', 'icon': Icons.construction},
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
    // //debugPrint('🏠 HomeScreen: initState() called for user: ${widget.user.name}');
    _loadProperties();
    _loadPropertyCategories();
    _startCategoryAutoScroll();
    _categoryRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _loadPropertyCategories(),
    );
    // _loadNotificationCount(); // Load notification count on startup
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

      // Infinite scroll logic for pagination. Only paginate the unfiltered
      // "All" list — category views are populated from a separate search call,
      // so appending general-list pages to them would mix in wrong results.
      if (_selectedCategory == 'All' &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
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
        builder: (context) => NewChatList(
          user: widget.user,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _notificationTimer?.cancel(); // Cancel notification timer
    _categoryAutoScrollTimer?.cancel();
    _categoryRefreshTimer?.cancel();
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
      // //debugPrint('🤍 Toggling favorite for property: ${property.id}');
      final result = await FavoritesService.toggleFavorite(property.id);

      if (result['success'] == true) {
        // Success - UI is already updated optimistically
        final message = wasLiked ? 'Removed from favorites' : 'Added to favorites';
        // //debugPrint('✅ $message for property: ${property.id}');

        // Show success feedback
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(message),
          //     backgroundColor: AppTheme.primaryblue,
          //     behavior: SnackBarBehavior.floating,
          //     duration: Duration(seconds: 2),
          //     margin: EdgeInsets.all(16),
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          //   ),
          // );
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

        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Failed to update favorites. Please try again.'),
          //     backgroundColor: Colors.red,
          //     behavior: SnackBarBehavior.floating,
          //     duration: Duration(seconds: 3),
          //     margin: EdgeInsets.all(16),
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          //   ),
          // );
        }
      }
    } catch (e) {
      //debugPrint('❌ Error toggling favorite: $e');

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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('An error occurred. Please try again.'),
        //     backgroundColor: Colors.red,
        //     behavior: SnackBarBehavior.floating,
        //     duration: Duration(seconds: 3),
        //     margin: EdgeInsets.all(16),
        //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        //   ),
        // );
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
      // Page to fetch: next page when loading more, otherwise the first page.
      final page = loadMore ? _currentPage + 1 : 1;

      final List<Property> propertiesResult = await PropertyService.getProperties(
        page: page,
        limit: _pageLimit,
      );

      // A full page implies there may be more results to fetch. A short/empty
      // page means we've reached the end (the list API returns no pagination
      // metadata, so we infer it from the returned count).
      final bool hasMore = propertiesResult.length >= _pageLimit;

      if (loadMore) {
        // Append-only path: don't refetch featured properties or bookings.
        final newProperties = List<Property>.from(propertiesResult)..shuffle();

        if (mounted) {
          setState(() {
            // De-duplicate by id so unstable server ordering can't append the
            // same property twice (which previously looked like a runaway loop).
            final existingIds = _properties.map((p) => p.id).toSet();
            final uniqueNew = newProperties.where((p) => existingIds.add(p.id)).toList();

            _properties.addAll(uniqueNew);
            _categoryProperties.addAll(uniqueNew);

            _currentPage = page; // Advance only after a successful fetch.
            _hasNextPage = hasMore && uniqueNew.isNotEmpty;
            _totalProperties = _properties.length;
            _totalPages = _currentPage + (_hasNextPage ? 1 : 0);
            _isLoadingMore = false;
          });
        }
        return;
      }

      // Initial / refresh load: also fetch featured properties and bookings.
      final featuredResult = await PropertyService.getFeaturedProperties(
        page: 1,
        limit: _pageLimit,
      );

      //Get pending bookings
      List<Booking> _emptybookings = [];
      final pendingBookings = widget.user.id != "" ? await BookingService.fetchBookings() : _emptybookings;

      if (propertiesResult.isNotEmpty) {
        final newProperties = List<Property>.from(propertiesResult)..shuffle();
        _pendingBookings = pendingBookings.where((b) => b.status == BookingStatus.pending).toList();

        List<Property> featuredProperties = [];
        if (featuredResult['success'] == true) {
          // Use dedicated featured properties if available
          final filterFeaturedProperties = List<Property>.from(featuredResult['properties'] ?? []);
          featuredProperties = filterFeaturedProperties.toList();
          featuredProperties.shuffle();
        } else {
          // Fallback to filtering general properties if featured API fails
          featuredProperties = newProperties.where((p) => p.isFeatured && p.availabilityStatus == true).toList();
          // //debugPrint('🏠 Using ${featuredProperties.length} featured properties from general properties (fallback)');
        }

        await _preloadFeaturedImages(featuredProperties);
        if (mounted) {
          setState(() {
            _properties = newProperties;
            _featuredProperties = featuredProperties;
            _categoryProperties = List.from(newProperties); // Initialize with all properties

            // Reset pagination metadata for a fresh list.
            _currentPage = 1;
            _hasNextPage = hasMore;
            _totalProperties = newProperties.length;
            _totalPages = _currentPage + (_hasNextPage ? 1 : 0);
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            // _errorMessage = 'There are no properties to show.';
            _categoryProperties = []; // Initialize empty category properties
            _pendingBookings = []; // Initialize empty pending bookings
            _pendingProperties = []; // Initialize empty pending properties
            _hasNextPage = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading properties: $e');

      // A failed "load more" should not destroy the session — just stop the
      // spinner so the user can retry by scrolling again.
      if (loadMore) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
        return;
      }

      if (mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
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
  // Future<void> _loadNotificationCount() async {
  //   try {
  //     final result = await NotificationApiService.getNotificationCount();
  //     if (result['success'] == true && mounted) {
  //       setState(() {
  //         _unreadNotificationCount = result['unreadCount'] ?? 0;
  //       });
  //       //debugPrint('🔔 Notification count loaded: $_unreadNotificationCount unread');
  //     }
  //   } catch (e) {
  //     //debugPrint('❌ Error loading notification count: $e');
  //     // Silently fail - not critical for app functionality
  //   }
  // }

  /// Setup periodic refresh for notification count
  void _setupNotificationRefresh() {
    // Refresh notification count every 2 minutes
    _notificationTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (mounted) {
        // _loadNotificationCount();
      }
    });
  }

  Landlord _createDummyLandlord() {
    return Landlord(
      id: widget.user.id,
      userId: widget.user.id,
      businessName: widget.user.name,
      businessDescription: '',
      businessAddress: '',
      businessPhone: widget.user.phone,
      businessEmail: widget.user.email,
      licenseNumber: '',
      taxId: '',
      bankAccountNumber: '',
      bankName: '',
      rating: 0,
      totalProperties: 0,
      totalBookings: 0,
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      businessRegistrationNumber: '',
      verificationDocuments: [],
      applicationDate: DateTime.now(),
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

  Future<void> _preloadFeaturedImages(List<Property> properties) async {
    final urls = properties
        .where((property) => property.images.isNotEmpty)
        .map((property) => _getFullImageUrl(property.images.first))
        .toSet();
    final cacheManager = DefaultCacheManager();
    await Future.wait(urls.map((url) async {
      try {
        await cacheManager
            .downloadFile(url)
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('Could not cache featured property image: $error');
      }
    }));
  }

  // Handle category selection and load properties for that category
  IconData _categoryIcon(String key, String label) {
    final identity = '$key $label'.toLowerCase();
    if (identity.contains('air_bnb') || identity.contains('airbnb') || identity.contains('stay')) {
      return Icons.weekend;
    }
    if (identity.contains('hostel') || identity.contains('hotel')) {
      return Icons.hotel;
    }
    if (identity.contains('land') || identity.contains('plot')) {
      return Icons.landscape;
    }
    if (identity.contains('rental') ||
        identity.contains('house') ||
        identity.contains('home') ||
        identity.contains('villa')) {
      return Icons.home;
    }
    if (identity.contains('apartment') ||
        identity.contains('condo') ||
        identity.contains('office') ||
        identity.contains('warehouse') ||
        identity.contains('building')) {
      return Icons.apartment;
    }
    return Icons.apartment;
  }

  Future<void> _loadPropertyCategories() async {
    try {
      final types = await PropertyService.getPropertyTypeConfigs();
      if (!mounted) return;

      final configuredCategories = types.map<Map<String, dynamic>>((type) {
        final key = type['key'] as String;
        final label = type['label'] as String;
        return {
          'name': label,
          'key': key,
          'icon': _categoryIcon(key, label),
        };
      }).toList();

      setState(() {
        _categories
          ..clear()
          ..add({'name': 'All', 'key': 'All', 'icon': Icons.apps})
          ..addAll(configuredCategories);
        if (!_categories.any((category) => category['name'] == _selectedCategory)) {
          _selectedCategory = 'All';
          _categoryProperties = List.from(_properties);
        }
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Could not load property categories: $error');
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Property categories could not be refreshed.')),
      );
    }
  }

  void _startCategoryAutoScroll() {
    _categoryAutoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_categoryScrollController.hasClients) return;
      final position = _categoryScrollController.position;
      if (position.maxScrollExtent <= 0 || position.isScrollingNotifier.value) return;

      final nextOffset = position.pixels + MediaQuery.of(context).size.width * 0.7;
      _categoryScrollController.animateTo(
        nextOffset >= position.maxScrollExtent ? 0 : nextOffset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _onCategorySelected(String categoryName, [String? categoryKey]) async {
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
        final searchResult = await PropertyService.searchPropertiesByType(categoryKey ?? categoryName.toLowerCase(), 1, 100);

        if (searchResult['success'] == true) {
          final categoryProps = List<Property>.from(searchResult['properties'] ?? []);
          if (mounted) {
            setState(() {
              _categoryProperties = categoryProps;
              _isCategoryLoading = false;
            });
          }
          // //debugPrint('✅ Found ${categoryProps.length} properties for category: $categoryName');
        } else {
          if (mounted) {
            setState(() {
              _categoryProperties = [];
              _isCategoryLoading = false;
            });
          }
          // //debugPrint('❌ No properties found for category: $categoryName');
        }
      }
    } catch (e) {
      // //debugPrint('❌ Error loading properties for category $categoryName: $e');
      if (mounted) {
        setState(() {
          _categoryProperties = [];
          _isCategoryLoading = false;
        });
      }

      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to load $categoryName properties'),
        //     backgroundColor: Colors.red,
        //     behavior: SnackBarBehavior.floating,
        //     duration: Duration(seconds: 3),
        //     margin: EdgeInsets.all(16),
        //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        //   ),
        // );
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

    // //debugPrint('🏆 Prioritized properties: ${propertiesWithPendingBookings.length} with pending bookings first, ${propertiesWithoutPendingBookings.length} others');

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // //debugPrint('🏠 HomeScreen: build() called for user: ${widget.user.name}');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final lastPress = _lastBackPressTime;
        if (lastPress != null && now.difference(lastPress) <= Duration(seconds: 2)) {
          _lastBackPressTime = null;
          SystemNavigator.pop();
          return;
        }
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        switch (_currentIndex) {
          0 => _buildHomeContent(),
          1 => SearchScreen(
              user: widget.user,
              allProperties: _properties.where((property) => property.availabilityStatus == true).toList(),
            ),
          2 => FavoritesScreen(
              user: widget.user,
              onNavigateToExplore: () {
                setState(() {
                  _currentIndex = 0; // Navigate to home/explore tab
                });
              },
            ),
          // 3 => BookingsListScreen(user: widget.user),
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
    // //debugPrint('🔄 HomeScreen: Refreshing data...');

    try {
      await Future.wait([
        _loadProperties(),
      ]);

      // //debugPrint('✅ HomeScreen: Refresh completed');
    } catch (e) {
      // //debugPrint('❌ HomeScreen: Refresh failed - $e');
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to refresh data'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
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
              _buildFeaturedSection(),
              _buildPendingBookingsSection(),
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
                      'Find your perfect home',
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
                        // _loadNotificationCount();
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
                onTap: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
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
                    child: widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _getFullImageUrl(widget.user.profileImage!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: AppTheme.primaryblue,
                                size: 30,
                              ),
                              cacheManager: DefaultCacheManager(),
                              fadeInDuration: Duration(milliseconds: 200),
                              fadeOutDuration: Duration(milliseconds: 200),
                            ),
                          )
                        : Icon(Icons.person, color: AppTheme.primaryblue),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            controller: _categoryScrollController,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['name'];

              return GestureDetector(
                  onTap: () => _onCategorySelected(
                    category['name'] as String,
                    category['key'] as String,
                  ),
                  child: Container(
                    width: 70,
                    margin: EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryblue : AppTheme.getCardColor(context),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryblue.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            category['icon'],
                            color: isSelected ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                            size: 24,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context),
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
      ]),
    );
  }

  Widget _buildFeaturedSection() {
    // Hide featured properties when a specific category is selected
    if (_selectedCategory != 'All') {
      return SizedBox.shrink(); // Return empty widget
    }

    if (_isLoading) {
      // Shimmer loading for featured section
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              SizedBox(
                width: 100,
              ),
              // TextButton(
              //   onPressed: () {
              //     setState(() {
              //       _currentIndex = 1;
              //     });
              //   },
              //   child: Text(
              //     'See All',
              //     style: TextStyle(
              //       color: AppTheme.primaryblue,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
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
      ]);
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
                SizedBox(
                  width: 100,
                ),
                // TextButton(
                //   onPressed: () {
                //     setState(() {
                //       _currentIndex = 1;
                //     });
                //   },
                //   child: Text(
                //     'See All',
                //     style: TextStyle(
                //       color: AppTheme.primaryblue,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
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
              SizedBox(width: 100),
            ],
          ),
        ),
        SizedBox(
          height: 444,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featuredProperties.length,
            itemBuilder: (context, index) {
              final property = _featuredProperties[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 16),
                child: _buildPropertyCard(property, widget.user, featured: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProperties() {
    // Use category properties if a specific category is selected and loaded
    List<Property> baseProperties = _selectedCategory == 'All' ? _properties : _categoryProperties;

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
                    ? widget.user.userType != UserType.landlord
                        ? 'Recent Properties'
                        : 'Uploaded properties'
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
          filteredProperties.isNotEmpty
              ? ListView.builder(
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
                      child: _buildPropertyCard(property, widget.user),
                    );
                  },
                )
              : Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/empty.png",
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No properties available at the moment",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildPropertyCard(Property property, User user, {bool featured = false}) {
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
                          child: CachedNetworkImage(
                            imageUrl: _getFullImageUrl(property.images.first),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
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
                              property.type,
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
                            _isPropertyFavorited(property) ? Icons.favorite : Icons.favorite_outline,
                            color: _isPropertyFavorited(property) ? Colors.red : AppTheme.getSecondaryTextColor(context),
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
                      color: property.availabilityStatus == true ? Colors.green : Colors.orange,
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
                          property.availabilityStatus == true ? Icons.check_circle : Icons.schedule,
                          color: AppTheme.whiteColor,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          property.availabilityStatus == true ? 'Available Now' : 'Available Later',
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

                  if (property.availabilityStatus == false && property.availableFrom != null)
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
                    width: double.maxFinite,
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
                            !featured
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: featured ? MediaQuery.of(context).size.width * 0.45 : MediaQuery.of(context).size.width * 0.54,
                                        child: Text(
                                          ProfileService().currencyConverter(price: property.price.toInt()),
                                          style: TextStyle(
                                            fontSize: featured ? 18 : 20,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryblue,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        property.priceType != "undefined" ? property.priceType : "",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.getSecondaryTextColor(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: featured ? MediaQuery.of(context).size.width * 0.45 : MediaQuery.of(context).size.width * 0.55,
                                        child: Text(
                                          ProfileService().currencyConverter(price: property.price.toInt()),
                                          style: TextStyle(
                                            fontSize: featured ? 18 : 20,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryblue,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        property.priceType != "undefined" ? property.priceType : "",
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
            itemCount: _pendingBookings.length,
            itemBuilder: (context, index) {
              if (_pendingBookings.isNotEmpty) {
                final property = _pendingBookings[index].property;
                final booking = _getPendingBookingForProperty(property!.id);
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(right: 16),
                  child: _buildPendingPropertyCard(property, booking),
                );
              }
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingsListScreen(
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
                          child: CachedNetworkImage(
                            imageUrl: _getFullImageUrl(property.images.first),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
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
                        '${ProfileService().currencyConverter(price: property.price.toInt())}',
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

      // Validate user ID before making payment request
      if (widget.user.id.isEmpty) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // //debugPrint('❌ User ID is empty - attempting to get from AuthService');

        // Try to get user ID from AuthService as fallback
        final currentUserId = await AuthService.getUserId();
        // //debugPrint('🔍 AuthService.getUserId() returned: "$currentUserId"');

        if (currentUserId == null || currentUserId.isEmpty) {
          _showPaymentError('User session invalid. Please logout and login again.');
          return;
        }

        // //debugPrint('✅ Using fallback user ID: $currentUserId');

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
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Payment completed successfully!'),
                //     backgroundColor: Colors.green,
                //     behavior: SnackBarBehavior.floating,
                //     duration: Duration(seconds: 3),
                //     margin: EdgeInsets.all(16),
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                //   ),
                // );
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
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Payment completed successfully!'),
              //     backgroundColor: Colors.green,
              //     behavior: SnackBarBehavior.floating,
              //     duration: Duration(seconds: 3),
              //     margin: EdgeInsets.all(16),
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //   ),
              // );
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

      // //debugPrint('❌ Payment initiation error: $e');
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
    final formattedPropertyPrice = ProfileService().currencyConverter(price: property.price.toInt());
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
                  'Full Price: $formattedPropertyPrice',
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
                      return 'Amount cannot exceed $formattedPropertyPrice';
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
                activeIcon: Icons.mail,
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
      // //debugPrint('🏠 HomeScreen: Home icon tapped while on home - triggering refresh');

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
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
              // //debugPrint('✅ Booking cancellation successful, refreshing all data...');
              // Add slight delay to ensure server has processed the update
              Future.delayed(Duration(milliseconds: 1000), () {
                if (mounted) {
                  _onRefresh(); // Use full refresh instead of just pending bookings
                }
              });
            } else if (state is BookingFailure) {
              Navigator.of(context).pop(); // Close dialog
              // //debugPrint('❌ Booking cancellation failed: ${state.error}');
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
                    onPressed: isLoading
                        ? null
                        : () {
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
                              // //debugPrint('❌ Error adding booking event: $e');
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

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(message),
    //     backgroundColor: Colors.green,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(8),
    //     ),
    //     margin: EdgeInsets.all(16),
    //   ),
    // );
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
