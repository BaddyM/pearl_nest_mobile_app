// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/screens/tenant/property_details_screen.dart';
import 'package:pearlnest/screens/tenant/filters_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final User user;
  final List<Property>? allProperties;

  const SearchScreen({
    super.key,
    required this.user,
    this.allProperties,
  });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class SearchFilters {
  String propertyType;
  RangeValues priceRange;
  int? bedrooms;
  List<String> selectedAmenities;

  SearchFilters({
    this.propertyType = 'All',
    this.priceRange = const RangeValues(0, 5000),
    this.bedrooms,
    this.selectedAmenities = const [],
  });

  SearchFilters copyWith({
    String? propertyType,
    RangeValues? priceRange,
    int? bedrooms,
    List<String>? selectedAmenities,
  }) {
    return SearchFilters(
      propertyType: propertyType ?? this.propertyType,
      priceRange: priceRange ?? this.priceRange,
      bedrooms: bedrooms ?? this.bedrooms,
      selectedAmenities: selectedAmenities ?? List.from(this.selectedAmenities),
    );
  }

  bool get hasActiveFilters {
    return propertyType != 'All' ||
        priceRange.start != 0 ||
        priceRange.end != 5000 ||
        bedrooms != null ||
        selectedAmenities.isNotEmpty;
  }

  void clear() {
    propertyType = 'All';
    priceRange = RangeValues(0, 5000);
    bedrooms = null;
    selectedAmenities.clear();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilters _filters = SearchFilters();
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String _sortBy = 'Recent';

  final List<String> _sortOptions = [
    'Recent',
    'Price Low to High',
    'Price High to Low',
    'Rating',
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _allProperties = _getDummyProperties();
        _filteredProperties = _allProperties;
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
        price: 2000000,
        priceType: 'per month',
        location: 'Downtown',
        address: '123 Main St, City Center',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'assets/images/img3.jpg',
          'assets/images/img4.jpg',
          'assets/images/img1.jpg',
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
        ],
        amenities: ['WiFi', 'Kitchen', 'AC'],
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
        price: 2000000,
        priceType: 'per month',
        location: 'Suburbs',
        address: '789 Family Lane',
        latitude: 40.6892,
        longitude: -74.0445,
        images: [
          'assets/images/img1.jpg',
          'assets/images/img8.jpg',
        ],
        amenities: ['Garden', 'Garage', 'WiFi', 'Fireplace'],
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
        title: 'Budget Hostel Room',
        description: 'Affordable accommodation for backpackers',
        type: PropertyType.hostel,
        price: 250000,
        priceType: 'per night',
        location: 'University Area',
        address: '321 Student St',
        latitude: 40.7500,
        longitude: -73.9800,
        images: ['assets/images/img4.jpg'],
        amenities: ['WiFi', 'Shared Kitchen', 'Laundry'],
        bedrooms: 1,
        bathrooms: 1,
        area: 20.0,
        landlordId: 'landlord4',
        landlordName: 'Alex Brown',
        landlordPhone: '+1234567893',
        status: PropertyStatus.available,
        rating: 3.8,
        reviewCount: 67,
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isVerified: true,
        availabilityStatus: AvailabilityStatus.availableNow, landlordEmail: '',
      ),
      Property(
        id: '5',
        title: 'Prime Land for Development',
        description: 'Excellent location for commercial development',
        type: PropertyType.land,
        price: 2000000,
        priceType: 'per month',
        location: 'Business District',
        address: '555 Commerce Blvd',
        latitude: 40.7200,
        longitude: -74.0100,
        images: ['assets/images/img5.jpg'],
        amenities: ['Road Access', 'Utilities Available'],
        bedrooms: 0,
        bathrooms: 0,
        area: 5000.0,
        landlordId: 'landlord5',
        landlordName: 'Emma Davis',
        landlordPhone: '+1234567894',
        status: PropertyStatus.available,
        rating: 4.0,
        reviewCount: 8,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
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

  void _performSearch() {
    setState(() {
      _filteredProperties = _allProperties.where((property) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            property.title.toLowerCase().contains(searchQuery) ||
            property.location.toLowerCase().contains(searchQuery) ||
            property.address.toLowerCase().contains(searchQuery) ||
            property.description.toLowerCase().contains(searchQuery);

        final matchesType = _filters.propertyType == 'All' ||
            property.propertyTypeString == _filters.propertyType;

        final matchesPrice = property.price >= _filters.priceRange.start &&
            property.price <= _filters.priceRange.end;

        final matchesBedrooms = _filters.bedrooms == null ||
            property.bedrooms == _filters.bedrooms;

        final matchesAmenities = _filters.selectedAmenities.isEmpty ||
            _filters.selectedAmenities.every((amenity) =>
                property.amenities.contains(amenity));

        return matchesSearch && matchesType && matchesPrice && matchesBedrooms && matchesAmenities;
      }).toList();

      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Price Low to High':
        _filteredProperties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High to Low':
        _filteredProperties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        _filteredProperties.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Recent':
      default:
        _filteredProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _filters.clear();
      _sortBy = 'Recent';
      _performSearch();
    });
  }

  void _openFilters() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiltersScreen(
          currentFilters: _filters,
          allProperties: _allProperties,
        ),
      ),
    );

    if (result != null && result is SearchFilters) {
      setState(() {
        _filters = result;
      });
      _performSearch();
    }
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
              child: _isLoading ? _buildLoadingState() : _buildSearchResults(),
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
                      'Search Properties',
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
                  onPressed: _clearFilters,
                  icon: Icon(
                    Icons.clear_all,
                    color: AppTheme.primaryblue,
                  ),
                  tooltip: 'Clear Filters',
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSearchBar(),
          SizedBox(height: 16),
          _buildFilterAndSort(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.getTextColor(context),),
        decoration: InputDecoration(
          hintText: 'Search by location, property name...',
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.search, color: AppTheme.primaryblue, size: 22),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.getSecondaryTextColor(context)),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _openFilters,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _filters.hasActiveFilters 
                    ? AppTheme.primaryblue 
                    : AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filters.hasActiveFilters 
                      ? AppTheme.primaryblue 
                      : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: _filters.hasActiveFilters 
                        ? AppTheme.whiteColor 
                        : AppTheme.getSecondaryTextColor(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _filters.hasActiveFilters ? 'Filters Applied' : 'Filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: _filters.hasActiveFilters 
                          ? AppTheme.whiteColor 
                          : AppTheme.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_filters.hasActiveFilters) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextColor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_getActiveFiltersCount()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryblue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        GestureDetector(
          onTap: _showSortOptions,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryblue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 18,
                  color: AppTheme.primaryblue,
                ),
                SizedBox(width: 8),
                Text(
                  _sortBy,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_filters.propertyType != 'All') count++;
    if (_filters.priceRange.start != 0 || _filters.priceRange.end != 5000) count++;
    if (_filters.bedrooms != null) count++;
    if (_filters.selectedAmenities.isNotEmpty) count++;
    return count;
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        '${_filteredProperties.length} properties found',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.getSecondaryTextColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              ...(_sortOptions.map((option) {
                final isSelected = _sortBy == option;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryblue : AppTheme.getTextColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryblue,
                          size: 20,
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    _performSearch();
                    Navigator.pop(context);
                  },
                );
              }).toList()),
              SizedBox(height: 16),
            ],
          ),
        );
      },
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
            'Loading properties...',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        _buildResultsCount(),
        Expanded(
          child: _filteredProperties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 100,),
                  itemCount: _filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = _filteredProperties[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: _buildPropertyCard(property),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria\nor filters to find more properties',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryblue,
              foregroundColor: AppTheme.whiteColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getTextColor(context).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
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
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: AppTheme.lightGreyColor,
                  ),
                  child: property.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.asset(
                            property.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.lightGreyColor,
                                      AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
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
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryblue.withOpacity(0.1),
                                AppTheme.accentGreen.withOpacity(0.1),
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

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryblue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.propertyTypeString,
                              style: TextStyle(
                                color: AppTheme.whiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (property.isFeatured) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
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
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(property.id),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.whiteColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.getTextColor(context).withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
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
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: property.availabilityStatus == AvailabilityStatus.availableNow
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: AppTheme.whiteColor,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          property.availabilityStatus == AvailabilityStatus.availableNow
                              ? 'Available Now'
                              : 'Available Later',
                          style: TextStyle(
                            color: AppTheme.whiteColor,
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
              padding: EdgeInsets.all(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '${property.rating}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.primaryblue,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getSecondaryTextColor(context),
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
                      if (property.bedrooms > 0) ...[
                        Icon(
                          Icons.bed,
                          size: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${property.bedrooms}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      if (property.bathrooms > 0) ...[
                        Icon(
                          Icons.bathroom,
                          size: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${property.bathrooms}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.square_foot,
                        size: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${property.area.toInt()} sqft',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${property.reviewCount} reviews',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryblue,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                property.priceType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getSecondaryTextColor(context),
                                ),
                              ),
                            ],
                          ),
                          if (property.availabilityStatus == AvailabilityStatus.availableLater &&
                               property.availableFrom != null)
                            Text(
                              'Available from ${_formatDate(property.availableFrom!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
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
}
