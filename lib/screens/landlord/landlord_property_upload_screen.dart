// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_bloc.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_event.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_state.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/apis/app_config.dart';

class LandlordPropertyUploadScreen extends StatefulWidget {
  final User user;
  final Landlord landlord;
  final Property? property;

  const LandlordPropertyUploadScreen({
    super.key,
    required this.user,
    required this.landlord,
    this.property,
  });

  @override
  State<LandlordPropertyUploadScreen> createState() => _LandlordPropertyUploadScreenState();
}

class _LandlordPropertyUploadScreenState extends State<LandlordPropertyUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _safetySecurityController = TextEditingController();
  final _nearbyPlacesController = TextEditingController();
  final _propertyMapController = TextEditingController();
  
  PropertyType _selectedType = PropertyType.apartment;
  String _selectedPriceType = 'per month';
  AvailabilityStatus _availabilityStatus = AvailabilityStatus.availableNow;
  DateTime? _availableFrom;
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = []; // For storing existing property images

  final List<String> _priceTypes = [
    'per month',
    'per night',
    'per week',
    'per year',
    'one time',
  ];

  final List<String> _availableAmenities = [
    'WiFi',
    'Parking',
    'Gym',
    'Pool',
    'Kitchen',
    'AC',
    'Heating',
    'Laundry',
    'Garden',
    'Garage',
    'Fireplace',
    'Balcony',
    'Elevator',
    'Security',
    'Pet Friendly',
  ];

  final ImagePicker _picker = ImagePicker();

  final List<PropertyType> _availablePropertyTypes = [
    PropertyType.apartment,
    PropertyType.house,
    PropertyType.studio,
    PropertyType.condo,
    PropertyType.townhouse,
    PropertyType.room,
    PropertyType.airbnb,
    PropertyType.hostel,
    PropertyType.fullHouse,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _neighborhoodController.dispose();
    _safetySecurityController.dispose();
    _nearbyPlacesController.dispose();
    _propertyMapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // If editing an existing property, fetch and populate the form fields
    if (widget.property != null) {
      _loadPropertyForEditing();
    }
  }

  Future<void> _loadPropertyForEditing() async {
    try {
      debugPrint('🔄 Loading property for editing: ${widget.property?.id}');
      
      // Get auth token
      final token = await AuthService.getCurrentToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No auth token available');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication required. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('✅ Auth token available, fetching property details...');
      
      // Fetch property details from API
      final result = await PropertyService.getPropertyForEdit(widget.property!.id, token: token);
      
      debugPrint('📋 API Result keys: ${result.keys}');
      debugPrint('📋 API Result success: ${result['success']}');
      debugPrint('📋 API Result property type: ${result['property']?.runtimeType}');
      debugPrint('📋 API Result property is null: ${result['property'] == null}');
      
      if (result['success'] == true && result['property'] != null) {
        debugPrint('✅ API call successful, populating form with API data...');
        _populateFormWithApiData(result['property']);
      } else {
        debugPrint('⚠️ API call failed or no data, falling back to existing property data...');
        debugPrint('⚠️ Success: ${result['success']}, Property: ${result['property']}');
        // Fallback to existing property data
        _populateFormForEditing();
      }
    } catch (e) {
      debugPrint('❌ Error loading property for editing: $e');
      // Fallback to existing property data
      _populateFormForEditing();
    }
  }

  PropertyType _getPropertyTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'house':
        return PropertyType.house;
      case 'fullhouse':
      case 'full house':
        return PropertyType.fullHouse;
      case 'studio':
        return PropertyType.studio;
      case 'condo':
        return PropertyType.condo;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'land':
        return PropertyType.land;
      case 'room':
        return PropertyType.room;
      case 'airbnb':
        return PropertyType.airbnb;
      case 'hostel':
        return PropertyType.hostel;
      case 'incomplete house':
      case 'incompletehouse':
        return PropertyType.incompleteHouse;
      case 'apartment':
      default:
        return PropertyType.apartment;
    }
  }

  void _populateFormWithApiData(Map<String, dynamic> propertyData) {
    debugPrint('🏠 Populating form with API data: ${propertyData.keys}');
    
    setState(() {
      _titleController.text = propertyData['propertyName'] ?? '';
      _descriptionController.text = propertyData['description'] ?? '';
      _priceController.text = propertyData['price']?.toString() ?? '';
      _locationController.text = propertyData['location'] ?? '';
      _addressController.text = propertyData['fullAddress'] ?? '';
      _neighborhoodController.text = propertyData['neighborhood'] ?? '';
      _areaController.text = propertyData['areaMeasurement']?.toString().replaceAll(' sq meters', '') ?? '';
      _bedroomsController.text = propertyData['numberOfBeds']?.toString() ?? '';
      _bathroomsController.text = propertyData['numberOfBathrooms']?.toString() ?? '';
      _safetySecurityController.text = propertyData['safetyAndSecurity'] ?? '';
      _nearbyPlacesController.text = propertyData['nearbyPlaces'] ?? '';
      _propertyMapController.text = propertyData['propertyMap'] ?? '';
      debugPrint('🔍 API period: "${propertyData['period']}"');
      _selectedPriceType = _priceTypes.contains(propertyData['period']) 
          ? propertyData['period'] 
          : 'per month';
      debugPrint('🔍 Selected priceType from API: "$_selectedPriceType"');
      
      debugPrint('📝 Populated propertyMap: ${_propertyMapController.text}');
      debugPrint('📝 Populated safetyAndSecurity: ${_safetySecurityController.text}');
      debugPrint('📝 Populated nearbyPlaces: ${_nearbyPlacesController.text}');
      
      // Parse amenities string to list
      if (propertyData['amenities'] != null && propertyData['amenities'].toString().isNotEmpty) {
        _selectedAmenities.clear();
        _selectedAmenities.addAll(propertyData['amenities'].toString().split(', '));
      }
      
      // Set property type
      String propertyTypeString = propertyData['propertyType'] ?? 'Apartment';
      _selectedType = _getPropertyTypeFromString(propertyTypeString);
      
      // Handle existing images - store URLs for display and deletion
      if (propertyData['media'] != null && propertyData['media'].toString().isNotEmpty) {
        _existingImageUrls.clear();
        // Split the media string by comma and clean up each path
        List<String> imagePaths = propertyData['media'].toString()
            .split(',')
            .map((path) => path.trim())
            .where((path) => path.isNotEmpty && path != 'uploads/property/undefined')
            .map((path) {
              // Convert relative paths to full URLs using AppConfig
              if (path.startsWith('./')) {
                return '${AppConfig.baseUrl}/${path.substring(2)}';
              } else if (!path.startsWith('http')) {
                return '${AppConfig.baseUrl}/$path';
              }
              return path;
            })
            .toList();
        _existingImageUrls.addAll(imagePaths);
        debugPrint('📸 Loaded ${imagePaths.length} existing images: $imagePaths');
      }
    });
  }

  void _populateFormForEditing() {
    final property = widget.property!;
    
    setState(() {
      // Basic property information
      _titleController.text = property.title;
      _descriptionController.text = property.description;
      _priceController.text = property.price.toString();
      _locationController.text = property.location;
      _addressController.text = property.address;
      _areaController.text = property.area.toString();
      _bedroomsController.text = property.bedrooms.toString();
      _bathroomsController.text = property.bathrooms.toString();
      
      // Use the new fields from the Property model
      _neighborhoodController.text = property.neighborhood ?? property.address; // Fallback to address if neighborhood is null
      _safetySecurityController.text = property.safetyAndSecurity ?? ''; // Use the field from model
      _nearbyPlacesController.text = property.nearbyPlaces ?? ''; // Use the field from model
      _propertyMapController.text = property.propertyMap ?? ''; // Use existing map if available
      
      // Property settings
      debugPrint('🔍 API priceType: "${property.priceType}"');
      debugPrint('🔍 Available priceTypes: $_priceTypes');
      _selectedPriceType = _priceTypes.contains(property.priceType) 
          ? property.priceType 
          : 'per month';
      debugPrint('🔍 Selected priceType: "$_selectedPriceType"');
      _selectedType = property.type;
      
      // Set availability status based on property status and availability data
      debugPrint('🔍 Property status: ${property.status}');
      debugPrint('🔍 API availabilityStatus: ${property.availabilityStatus}');
      
      if (property.status == PropertyStatus.unavailable) {
        // If property is unavailable, default to "Available Later"
        _availabilityStatus = AvailabilityStatus.availableLater;
        debugPrint('🔍 Property is unavailable, setting to Available Later');
      } else {
        // Use the availability status from API
        _availabilityStatus = property.availabilityStatus;
        debugPrint('🔍 Using API availability status: $_availabilityStatus');
      }
      
      _availableFrom = property.availableFrom;
      
      // Parse amenities list
      _selectedAmenities.clear();
      if (property.amenities.isNotEmpty) {
        _selectedAmenities.addAll(property.amenities);
      }
      
      // Handle existing images - store URLs for display and deletion
      _existingImageUrls.clear();
      if (property.images.isNotEmpty) {
        _existingImageUrls.addAll(property.images);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertyUploadBloc, PropertyUploadState>(
      listener: (context, state) {
        if (state is PropertyUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              duration: Duration(milliseconds: 1500),
              backgroundColor: AppTheme.primaryblue,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is PropertyUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: Duration(milliseconds: 2000),
              margin: EdgeInsets.all(16),
            ),
          );
        } else if (state is PropertyUploadValidationError) {
          // Show validation errors
          final firstError = state.fieldErrors.values.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                firstError,
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: Duration(milliseconds: 2000),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
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
                      widget.property != null ? 'Edit Property' : 'Add New Property',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.property != null ? 'Update the details below' : 'Fill in the details below',
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
                    _resetForm();
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.primaryblue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int completedSections = 0;
    int totalSections = 10; // Updated to include new sections
    
    if (_titleController.text.isNotEmpty) completedSections++;
    if (_priceController.text.isNotEmpty) completedSections++;
    if (_locationController.text.isNotEmpty) completedSections++;
    if (_bedroomsController.text.isNotEmpty) completedSections++;
    if (_selectedAmenities.isNotEmpty) completedSections++;
    if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty) completedSections++;
    if (_descriptionController.text.isNotEmpty) completedSections++;
    if (_neighborhoodController.text.isNotEmpty) completedSections++;
    if (_safetySecurityController.text.isNotEmpty) completedSections++;
    if (_propertyMapController.text.isNotEmpty) completedSections++;
    
    double progress = completedSections / totalSections;
    
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryblue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upload Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryblue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Basic Information',
              Icons.info_outline,
              _buildBasicInfoSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Property Details',
              Icons.home_outlined,
              _buildPropertyDetailsSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Location',
              Icons.location_on_outlined,
              _buildLocationSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Property Map',
              Icons.map_outlined,
              _buildPropertyMapSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Safety & Security',
              Icons.security_outlined,
              _buildSafetySecuritySection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Nearby Places',
              Icons.place_outlined,
              _buildNearbyPlacesSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Pricing',
              Icons.attach_money_outlined,
              _buildPricingSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Availability',
              Icons.calendar_today_outlined,
              _buildAvailabilitySection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Amenities',
              Icons.star_outline,
              _buildAmenitiesSection(),
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              'Photos',
              Icons.photo_camera_outlined,
              _buildPhotosSection(),
            ),
            SizedBox(height: 30),
            _buildSubmitButton(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryblue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryblue, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _priceController.clear();
      _locationController.clear();
      _bedroomsController.clear();
      _descriptionController.clear();
      _neighborhoodController.clear();
      _safetySecurityController.clear();
      _nearbyPlacesController.clear();
      _propertyMapController.clear();
      _selectedAmenities.clear();
      _selectedImages.clear();
    });
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: 'Property Title',
          hint: 'Enter a catchy title for your property',
          icon: Icons.title,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a property title';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Describe your property in detail',
          icon: Icons.description,
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        _buildPropertyTypeDropdown(),
      ],
    );
  }

  Widget _buildPropertyDetailsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _bedroomsController,
                label: 'Bedrooms',
                hint: '0',
                icon: Icons.bed,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _bathroomsController,
                label: 'Bathrooms',
                hint: '0',
                icon: Icons.bathtub,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _areaController,
          label: 'Area (sq meters)',
          hint: 'Enter property area',
          icon: Icons.square_foot,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the area';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _locationController,
          label: 'Location/Area',
          hint: 'e.g., Downtown, University District',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the location';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _neighborhoodController,
          label: 'Neighborhood',
          hint: 'Specific neighborhood name',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the neighborhood';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: 'Full Address',
          hint: 'Enter complete address',
          icon: Icons.home,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller: _priceController,
            label: 'Price',
            hint: '0',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            prefixText: 'UGX',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the price';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildPriceTypeDropdown(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withValues(alpha: -3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildRadioTile(
                'Available Now',
                AvailabilityStatus.availableNow,
                Icons.check_circle_outline,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildRadioTile(
                'Available Later',
                AvailabilityStatus.availableLater,
                Icons.schedule,
              ),
            ],
          ),
        ),
        if (_availabilityStatus == AvailabilityStatus.availableLater) ...[
          SizedBox(height: 16),
          GestureDetector(
            onTap: _selectAvailableDate,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryblue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryblue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _availableFrom != null
                          ? 'Available from: ${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}'
                          : 'Select available date',
                      style: TextStyle(
                        color: _availableFrom != null
                            ? AppTheme.getTextColor(context)
                            : AppTheme.getSecondaryTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioTile(String title, AvailabilityStatus value, IconData icon) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: AppTheme.blackColor,
      ),
      child: RadioListTile<AvailabilityStatus>(
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryblue, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        value: value,
        groupValue: _availabilityStatus,
        onChanged: (newValue) {
          setState(() {
            _availabilityStatus = newValue!;
            if (newValue == AvailabilityStatus.availableNow) {
              _availableFrom = null;
            }
          });
        },
        activeColor: AppTheme.primaryblue,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select amenities available in your property:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return _buildAmenityChip(amenity, isSelected);
          }).toList(),
        ),
        if (_selectedAmenities.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedAmenities.length} amenities selected',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryblue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmenityChip(String amenity, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAmenities.remove(amenity);
          } else {
            _selectedAmenities.add(amenity);
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primaryblue, AppTheme.primaryblue.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryblue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryblue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            if (isSelected) SizedBox(width: 4),
            Text(
              amenity,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.getSecondaryTextColor(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add photos to showcase your property (max 10):',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddPhotoCard(),
              ..._existingImageUrls.map((imageUrl) => _buildExistingImageCard(imageUrl)),
              ..._selectedImages.map((image) => _buildPhotoCard(image)),
            ],
          ),
        ),
        if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: AppTheme.primaryblue, size: 16),
                SizedBox(width: 8),
                Text(
                  '${_selectedImages.length + _existingImageUrls.length} photo(s) selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.getTextColor(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: icon != null
            ? Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryblue, size: 20),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryblue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppTheme.getCardColor(context),
        contentPadding: EdgeInsets.symmetric(
          horizontal: icon != null ? 60 : 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPropertyTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: DropdownButtonFormField<PropertyType>(
        value: _selectedType,
        style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: 'Property Type',
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_work, color: AppTheme.primaryblue, size: 20),
          ),
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        ),
        items: _availablePropertyTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(
              _getPropertyTypeDisplayName(type),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
        dropdownColor: AppTheme.getCardColor(context),
        icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryblue),
      ),
    );
  }

  Widget _buildPriceTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPriceType,
        style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: 'Period',
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: _priceTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPriceType = value!;
          });
        },
        dropdownColor: AppTheme.getCardColor(context),
        icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryblue),
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _showImageSelectionDialog,
      child: Container(
        width: 100,
        height: 100,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryblue.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryblue,
                size: 28,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppTheme.primaryblue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImageCard(String imageUrl) {
    debugPrint('🖼️ Building image card for URL: $imageUrl');
    return Container(
      width: 120,
      height: 120,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Image load error for $imageUrl: $error');
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  debugPrint('✅ Image loaded successfully: $imageUrl');
                  return child;
                }
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deleteExistingImage(imageUrl),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          // Badge to indicate this is an existing image
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Existing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteExistingImage(String imageUrl) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Image'),
        content: Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.property != null) {
      try {
        // Get auth token
        final token = await AuthService.getCurrentToken();
        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication required. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Deleting image...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );

        // Extract image string from URL
        String imageString = imageUrl.split('/').last.split('?').first;
        
        // Call delete API
        final result = await PropertyService.deletePropertyImage(
          widget.property!.id,
          imageString,
          token: token,
        );

        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success'] == true) {
          setState(() {
            _existingImageUrls.remove(imageUrl);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete image: ${result['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        debugPrint('Error deleting image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPhotoCard(File image) {
    return Container(
      width: 120,
      height: 120,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.remove(image);
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<PropertyUploadBloc, PropertyUploadState>(
      builder: (context, state) {
        final isLoading = state is PropertyUploadLoading;
        
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryblue, AppTheme.primaryblue.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryblue.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitProperty,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.property != null ? Icons.save : Icons.upload,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        widget.property != null ? 'Update Property' : 'Upload Property',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showImageSelectionDialog() {
    int totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 photos allowed', style: TextStyle(color: AppTheme.lightGreyColor),),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 500),
          backgroundColor: AppTheme.primaryblue,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryblue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryblue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryblue,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryblue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      int totalImages = _selectedImages.length + _existingImageUrls.length;
      if (totalImages >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum 10 photos allowed', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(milliseconds: 1500),
            margin: EdgeInsets.all(16),
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Image picker error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e', style: TextStyle(color: AppTheme.lightGreyColor),),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 500),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _selectAvailableDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryblue,
              onPrimary: Colors.white,
              surface: AppTheme.getCardColor(context),
              onSurface: AppTheme.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _availableFrom = picked;
      });
    }
  }

  String _getPropertyTypeDisplayName(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.room:
        return 'Room';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.airbnb:
        return 'Airbnb';
      case PropertyType.hostel:
        return 'Hostel';
      case PropertyType.fullHouse:
        return 'Full House';
      case PropertyType.land:
        return 'Land';
      case PropertyType.incompleteHouse:
        return 'Incomplete House';
    }
  }

  void _submitProperty() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 1500),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one photo', style: TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 1500),
          backgroundColor: AppTheme.primaryblue,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    int totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 photos allowed. Please remove ${totalImages - 10} photo(s)', style: TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(milliseconds: 2000),
          backgroundColor: Colors.red,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_availabilityStatus == AvailabilityStatus.availableLater && _availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an available date', style: TextStyle(color: Colors.white)),
          duration: Duration(milliseconds: 1500),
          backgroundColor: AppTheme.primaryblue,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Convert PropertyType enum to string
    String propertyTypeString = _getPropertyTypeDisplayName(_selectedType);

    // Convert amenities array to comma-separated string
    String amenitiesString = _selectedAmenities.join(', ');

    // Convert area to string
    String areaMeasurementString = '${_areaController.text} sq meters';

    // Debug availability information
    bool availabilityBoolean = _availabilityStatus == AvailabilityStatus.availableNow;
    debugPrint('🏠 Availability Status: $_availabilityStatus');
    debugPrint('🏠 Availability Boolean: $availabilityBoolean');
    debugPrint('🏠 Available From: $_availableFrom');

    // Dispatch the appropriate event to the BLoC based on whether we're editing or creating
    if (widget.property != null) {
      // Editing existing property
      context.read<PropertyUploadBloc>().add(
        PropertyUpdateRequested(
          propertyId: widget.property!.id,
          propertyName: _titleController.text.trim(),
          propertyType: propertyTypeString,
          location: _locationController.text.trim(),
          price: double.parse(_priceController.text),
          amenities: amenitiesString,
          safetyAndSecurity: _safetySecurityController.text.trim(),
          description: _descriptionController.text.trim(),
          nearbyPlaces: _nearbyPlacesController.text.trim(),
          numberOfBeds: int.parse(_bedroomsController.text),
          numberOfBathrooms: int.parse(_bathroomsController.text),
          areaMeasurement: areaMeasurementString,
          neighborhood: _neighborhoodController.text.trim(),
          fullAddress: _addressController.text.trim(),
          propertyMap: _propertyMapController.text.trim(),
          period: _selectedPriceType,
          availability: _availabilityStatus == AvailabilityStatus.availableNow,
          availableFrom: _availabilityStatus == AvailabilityStatus.availableLater ? _availableFrom : null,
        ),
      );
    } else {
      // Creating new property
      context.read<PropertyUploadBloc>().add(
        PropertyUploadRequested(
          propertyName: _titleController.text.trim(),
          propertyType: propertyTypeString,
          location: _locationController.text.trim(),
          price: double.parse(_priceController.text),
          amenities: amenitiesString,
          safetyAndSecurity: _safetySecurityController.text.trim(),
          description: _descriptionController.text.trim(),
          nearbyPlaces: _nearbyPlacesController.text.trim(),
          numberOfBeds: int.parse(_bedroomsController.text),
          numberOfBathrooms: int.parse(_bathroomsController.text),
          areaMeasurement: areaMeasurementString,
          neighborhood: _neighborhoodController.text.trim(),
          fullAddress: _addressController.text.trim(),
          propertyMap: _propertyMapController.text.trim(),
          period: _selectedPriceType,
          availability: _availabilityStatus == AvailabilityStatus.availableNow,
          availableFrom: _availabilityStatus == AvailabilityStatus.availableLater ? _availableFrom : null,
          images: _selectedImages,
        ),
      );
    }
  }

  Widget _buildPropertyMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add a Google Maps embed link to help tenants locate your property:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Steps to get iframe:\n1. Open Google Maps\n2. Search for your property address\n3. Click "Share" → "Embed a map"\n4. Choose size (Medium recommended)\n5. Copy the iframe code and paste below',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _propertyMapController,
          label: 'Property Map (iframe)',
          hint: '<iframe src="https://www.google.com/maps/embed?..." width="600" height="450"...></iframe>',
          icon: Icons.map,
          maxLines: 4,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!value.contains('<iframe') || !value.contains('src=')) {
                return 'Please enter a valid iframe embed code';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSafetySecuritySection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Describe safety and security features of your property:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _safetySecurityController,
          label: 'Safety & Security Features',
          hint: 'e.g., 24/7 Security, CCTV, Gated compound, Security lights, etc.',
          icon: Icons.security,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildNearbyPlacesSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryblue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'List nearby places and amenities that tenants might find useful:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _nearbyPlacesController,
          label: 'Nearby Places',
          hint: 'e.g., Schools, Hospitals, Shopping centers, Banks, Restaurants, Public transport, etc.',
          icon: Icons.place,
          maxLines: 3,
        ),
      ],
    );
  }
}