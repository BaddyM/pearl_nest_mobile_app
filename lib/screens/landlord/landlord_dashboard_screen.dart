import 'package:flutter/material.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/landlord/landlord_property_management_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_booking_requests_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_property_upload_screen.dart';
import 'package:pearlnest/screens/chat/new_chat_list.dart';
import 'package:pearlnest/screens/tenant/profile_screen.dart';
import 'package:pearlnest/screens/tenant/search_screen.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/screens/landlord/landlord_refunds_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_wallet_screen.dart';

class LandlordDashboardScreen extends StatefulWidget {
  final User user;
  final Landlord landlord;

  const LandlordDashboardScreen({
    super.key,
    required this.user,
    required this.landlord,
  });

  @override
  // ignore: library_private_types_in_public_api
  _LandlordDashboardScreenState createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  int _totalProperties = 0;
  int _pendingProperties = 0;
  int _totalBookings = 0;
  int _totalViews = 0;
  int _totalComments = 0;
  int _totalInteractions = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Fetch properties and bookings concurrently
      final results = await Future.wait([
        PropertyService.getPropertiesByLandlord(widget.user.id),
        BookingService.fetchLandlordBookings(),
      ]);

      final properties = results[0];
      final bookings = results[1];

      // Debug logging
      //debugPrint('🏠 Dashboard - Properties result type: ${properties.runtimeType}');
      //debugPrint('🏠 Dashboard - Properties content: $properties');

      int propertyCount = 0;
      int pendingPropertyCount = 0;
      int totalViews = 0;
      int totalComments = 0;
      int totalInteractions = 0;
      if (properties is Map<String, dynamic>) {
        // The getPropertiesByLandlord method returns {properties: [...]} not {data: [...]}
        final propertiesList = properties['properties'];
        //debugPrint('🏠 Dashboard - Properties list type: ${propertiesList.runtimeType}');
        //debugPrint('🏠 Dashboard - Properties list: $propertiesList');

        if (propertiesList is List) {
          propertyCount = propertiesList.length;
          for (final property in propertiesList.whereType<dynamic>()) {
            if (property is! Property) continue;
            if (property.status == PropertyStatus.pending) {
              pendingPropertyCount++;
            }
            totalViews += property.views.length;
            totalComments += property.reviews.length;
            totalInteractions += property.views.length +
                property.shares.length +
                property.favourites.length +
                property.reviews.length;
          }
          //debugPrint('🏠 Dashboard - Property count: $propertyCount');
        }
      }

      //debugPrint('🏠 Dashboard - Bookings result type: ${bookings.runtimeType}');
      //debugPrint('🏠 Dashboard - Bookings count: ${bookings is List ? bookings.length : 0}');

      if (mounted) {
        setState(() {
          _totalProperties = propertyCount;
          _pendingProperties = pendingPropertyCount;
          _totalBookings = bookings is List ? bookings.length : 0;
          _totalViews = totalViews;
          _totalComments = totalComments;
          _totalInteractions = totalInteractions;
          _isLoading = false;
        });

        //debugPrint('🏠 Dashboard - Final property count set to: $_totalProperties');
        //debugPrint('🏠 Dashboard - Final booking count set to: $_totalBookings');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: _buildFloatingNavigationBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    const destinations = [
      (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
      (Icons.explore_outlined, Icons.explore, 'Explore'),
      (Icons.home_work_outlined, Icons.home_work, 'Listings'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'Bookings'),
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final isSelected = _currentIndex == index;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: destination.$3,
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryblue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isSelected ? destination.$2 : destination.$1,
                          color: isSelected
                              ? AppTheme.primaryblue
                              : AppTheme.getSecondaryTextColor(context),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryblue
                              : AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return SearchScreen(user: widget.user);
      case 2:
        return LandlordPropertyManagementScreen(
          user: widget.user,
          landlord: widget.landlord,
          properties: [],
        );
      case 3:
        return LandlordBookingRequestsScreen(
          user: widget.user,
        );
      case 4:
        return NewChatList(user: widget.user, showBackButton: false);
      case 5:
        return LandlordProfileScreen(
          user: widget.user,
          landlord: widget.landlord,
        );
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildStatsCards(),
              _buildQuickActions(),
              SizedBox(height: 20),
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
            color:
                AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANDLORD OVERVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.user.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.landlord.businessName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent,
                  child: widget.user.profileImage != null &&
                          widget.user.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            ImageHelper.getFullImageUrl(
                                widget.user.profileImage!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryblue),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.business,
                                  color: AppTheme.primaryblue, size: 30);
                            },
                          ),
                        )
                      : Icon(Icons.business,
                          color: AppTheme.primaryblue, size: 30),
                ),
              ),
            ],
          ),
          if (!_isLoading && _pendingProperties > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_top,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_pendingProperties ${_pendingProperties == 1 ? 'property' : 'properties'} under review',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.landlord.rating > 0) ...[
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${widget.landlord.rating} Rating',
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                ],
                if (widget.landlord.isVerified)
                  Row(
                    children: [
                      Icon(Icons.verified,
                          color: AppTheme.primaryblue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppTheme.primaryblue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'A snapshot of your rental activity',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 16),

          // Show error if any
          if (_error.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboardData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: _isLoading
                    ? _buildLoadingStatCard(
                        'Properties', Icons.home_work, AppTheme.primaryblue)
                    : _buildStatCard(
                        'Properties',
                        '$_totalProperties',
                        Icons.home_work,
                        AppTheme.primaryblue,
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _isLoading
                    ? _buildLoadingStatCard(
                        'Bookings', Icons.calendar_today, Colors.blue)
                    : _buildStatCard(
                        'Bookings',
                        '$_totalBookings',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _isLoading
                    ? _buildLoadingStatCard(
                        'Property views', Icons.visibility, Colors.teal)
                    : _buildStatCard('Property views', '$_totalViews',
                        Icons.visibility, Colors.teal),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _isLoading
                    ? _buildLoadingStatCard(
                        'Comments', Icons.comment_outlined, Colors.deepPurple)
                    : _buildStatCard('Comments', '$_totalComments',
                        Icons.comment_outlined, Colors.deepPurple),
              ),
            ],
          ),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_totalInteractions total interactions across your listings',
                style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard(String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Add Property',
                  Icons.add_home,
                  AppTheme.primaryblue,
                  () async {
                    // Navigate to property upload screen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LandlordPropertyUploadScreen(
                          user: widget.user,
                          landlord: widget.landlord,
                        ),
                      ),
                    );

                    // Refresh dashboard data if property was added
                    if (result == true) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Explore Listings',
                  Icons.explore_outlined,
                  Colors.teal,
                  () => setState(() => _currentIndex = 1),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'View Bookings',
                  Icons.calendar_view_day,
                  Colors.blue,
                  () {
                    setState(() {
                      _currentIndex = 3;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Manage Listings',
                  Icons.home_work_outlined,
                  AppTheme.primaryblue,
                  () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Wallet & Earnings',
                  Icons.account_balance_wallet_outlined,
                  AppTheme.primaryblue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LandlordWalletScreen()),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Refund Requests',
                  Icons.currency_exchange,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LandlordRefundsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LandlordProfileScreen extends StatelessWidget {
  final User user;
  final Landlord landlord;

  const LandlordProfileScreen({
    super.key,
    required this.user,
    required this.landlord,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      user: user,
      landlord: landlord,
      showBackButton: false,
    );
  }
}
