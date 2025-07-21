import 'package:flutter/material.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/landlord/landlord_property_management_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_booking_requests_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_property_upload_screen.dart';
import 'package:pearlnest/screens/chat/chat_screen.dart';
import 'package:pearlnest/screens/tenant/profile_screen.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/booking_service.dart';

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
  _LandlordDashboardScreenState createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  int _totalProperties = 0;
  int _totalBookings = 0;
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
      debugPrint('🏠 Dashboard - Properties result type: ${properties.runtimeType}');
      debugPrint('🏠 Dashboard - Properties content: $properties');
      
      int propertyCount = 0;
      if (properties is Map<String, dynamic>) {
        // The getPropertiesByLandlord method returns {properties: [...]} not {data: [...]}
        final propertiesList = properties['properties'];
        debugPrint('🏠 Dashboard - Properties list type: ${propertiesList.runtimeType}');
        debugPrint('🏠 Dashboard - Properties list: $propertiesList');
        
        if (propertiesList is List) {
          propertyCount = propertiesList.length;
          debugPrint('🏠 Dashboard - Property count: $propertyCount');
        }
      }

      debugPrint('🏠 Dashboard - Bookings result type: ${bookings.runtimeType}');
      debugPrint('🏠 Dashboard - Bookings count: ${bookings is List ? bookings.length : 0}');

      if (mounted) {
        setState(() {
          _totalProperties = propertyCount;
          _totalBookings = bookings is List ? bookings.length : 0;
          _isLoading = false;
        });
        
        debugPrint('🏠 Dashboard - Final property count set to: $_totalProperties');
        debugPrint('🏠 Dashboard - Final booking count set to: $_totalBookings');
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
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryblue,
        unselectedItemColor: AppTheme.getSecondaryTextColor(context),
        backgroundColor: AppTheme.getCardColor(context),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return LandlordPropertyManagementScreen(
          user: widget.user,
          landlord: widget.landlord,
          properties: [],
        );
      case 2:
        return LandlordBookingRequestsScreen(
          user: widget.user,
        );
      case 3:
        return ChatScreen(user: widget.user);
      case 4:
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildStatsCards(),
              _buildQuickActions(),
              SizedBox(height: 20), // Add some bottom padding
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
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
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
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
                  child: widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            ImageHelper.getFullImageUrl(widget.user.profileImage!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.business, color: AppTheme.primaryblue, size: 30);
                            },
                          ),
                        )
                      : Icon(Icons.business, color: AppTheme.primaryblue, size: 30),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
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
            child: Row(
              children: [
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
                if (widget.landlord.isVerified)
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.primaryblue, size: 16),
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
                  ? _buildLoadingStatCard('Properties', Icons.home_work, AppTheme.primaryblue)
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
                  ? _buildLoadingStatCard('Bookings', Icons.calendar_today, Colors.blue)
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
        
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
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
              color: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2),
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
                  'View Bookings',
                  Icons.calendar_view_day,
                  Colors.blue,
                  () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
    return ProfileScreen(user: user, landlord: landlord);
  }
}