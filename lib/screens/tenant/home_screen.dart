import 'package:flutter/material.dart';
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
import 'package:pearlnest/widgets/app_theme.dart';

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
    return ChatConversation(
      id: 'pearlnest_support',
      landlordId: 'pearlnest_support',
      landlordName: 'PearlNest Support',
      landlordProfilePic: '',
      propertyTitle: 'General Support & Inquiries',
      lastMessage: 'Hello! How can we help you today?',
      lastMessageTime: DateTime.now(),
      isOnline: true,
      unreadCount: 0,
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

  void _loadProperties() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _properties = _getDummyProperties();
        _featuredProperties = _properties.where((p) => p.isFeatured).toList();
        _isLoading = false;
      });
    });
  }

  List<Property> _getDummyProperties() {
    return [
      Property(
        id: '1',
        title: 'Modern Apartment in City Center',
        description: 'Beautiful modern apartment with city views',
        type: PropertyType.apartment,
        price: 500000,
        priceType: 'per month',
        location: 'Downtown',
        address: '123 Main St, City Center',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'assets/images/img3.jpg',
          'assets/images/img4.jpg',
          'assets/images/img1.jpg',
          'assets/images/img2.jpg',
          'assets/images/img5.jpg',
          'assets/images/img6.jpg',
          'assets/images/img7.jpg',
          'assets/images/img8.jpg',
        ],
        amenities: ['WiFi', 'Parking', 'Gym', 'Pool'],
        bedrooms: 2,
        bathrooms: 2,
        area: 85.0,
        landlordId: 'landlord1',
        landlordName: 'John Smith',
        landlordPhone: '+1234567890',
        status: PropertyStatus.available,
        rating: 4.5,
        reviewCount: 23,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '2',
        title: 'Cozy Airbnb Studio',
        description: 'Perfect for short stays and travelers',
        type: PropertyType.airbnb,
        price: 100000,
        priceType: 'per night',
        location: 'Tourist District',
        address: '456 Tourist Ave',
        latitude: 40.7589,
        longitude: -73.9851,
        images: [
          'assets/images/img2.jpg',
          'assets/images/img3.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
          'assets/images/img6.jpg',
          'assets/images/img7.jpg',
        ],
        amenities: ['WiFi', 'Kitchen', 'AC', 'Garden', 'Fireplace'],
        bedrooms: 1,
        bathrooms: 1,
        area: 45.0,
        landlordId: 'landlord2',
        landlordName: 'Sarah Johnson',
        landlordPhone: '+1234567891',
        status: PropertyStatus.available,
        rating: 4.8,
        reviewCount: 45,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableLater,
        availableFrom: DateTime.now().add(Duration(days: 45)), landlordEmail: '',
      ),
      Property(
        id: '3',
        title: 'Spacious Family House',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Shared Kitchen'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Mike Wilson',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '4',
        title: 'These Days',
        description: 'Perfect for campus going students with WiFi and Road Access',
        type: PropertyType.hostel,
        price: 900000,
        priceType: 'per month',
        location: 'Kikoni',
        address: 'Nalika Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garage', 'Pool', 'WiFi', 'Fireplace', 'Laundry', 'Road Access'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Jess Glynne',
        landlordPhone: '+256787878090',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '5',
        title: 'Hope Family House',
        description: 'Perfect for Couples with garden and garage',
        type: PropertyType.fullHouse,
        price: 50000000,
        priceType: 'per month',
        location: 'Rock Port City',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img5.jpg',
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'NF',
        landlordPhone: '+256123456987',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '6',
        title: 'Perfection',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.incompleteHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '684 Hunm Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Utilities Available'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Conner Price',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '7',
        title: 'Mansion',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Pool', 'AC'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord4',
        landlordName: 'Conner Price',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '8',
        title: 'Smoky Hostel',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Gym', 'Pool'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Walker Hayes',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '9',
        title: 'Kare Hostel',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Pool', 'Gym', 'Parking'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Emuron Hublot',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '10',
        title: 'Garden Courts',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Parking', 'Pool', 'Gym'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Ketra Caterfall',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '11',
        title: 'Douglous Villa',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Laundry', 'Pool'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Joseph David',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '12',
        title: 'Cilibas Hostel',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Gym', 'Garage', 'WiFi', 'Fireplace', 'Parking'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Trejan Thunder',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '13',
        title: 'Ryan Home',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Shared Kitchen', 'Road Access'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord3',
        landlordName: 'Dead Pool',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '14',
        title: 'Marvel Cinematic Universe',
        description: 'Perfect for newly weded couples',
        type: PropertyType.fullHouse,
        price: 20000000,
        priceType: 'per month',
        location: 'Palm City',
        address: '17 Eden Shores',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace', 'Road Access', 'Utilities Available', 'Parking', 'Gym', 'Pool', 'Laundry', 'Kitchen'],
        bedrooms: 6,
        bathrooms: 4,
        area: 2000.0,
        landlordId: 'aurafarmer',
        landlordName: 'Vawzen Kasule',
        landlordPhone: '+256787018472',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow,
        landlordEmail: 'vawzen@gmail.com',
      ),
      Property(
        id: '15',
        title: 'Ditective Comics',
        description: 'Perfect for families with garden and garage',
        type: PropertyType.apartment,
        price: 20000000,
        priceType: 'per month',
        location: 'Masajja',
        address: 'Masajja Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
          'assets/images/img3.jpg',
          'assets/images/img2.jpg',
          'assets/images/img4.jpg',
          'assets/images/img5.jpg',
        ],
        amenities: ['Garden', 'Gmy', 'Pool', 'Kitchen', 'Parking', 'Laundry', 'WiFi', 'Fireplace'],
        bedrooms: 4,
        bathrooms: 3,
        area: 200.0,
        landlordId: 'landlord15',
        landlordName: 'Timothy Trison',
        landlordPhone: '+1234567892',
        status: PropertyStatus.available,
        rating: 4.2,
        reviewCount: 12,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
    ];
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

  void _toggleFavorite(String propertyId) {
    setState(() {
      if (widget.user.favoriteProperties.contains(propertyId)) {
        widget.user.favoriteProperties.remove(propertyId);
      } else {
        widget.user.favoriteProperties.add(propertyId);
      }
    });
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_isLoading) {
      return Container(
        height: 200,
        margin: EdgeInsets.only(top: 1),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryblue),
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
                          child: Image.asset(
                            property.images.first,
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
                                  'UGX${property.price.toStringAsFixed(0)}',
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