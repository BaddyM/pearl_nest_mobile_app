// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/apis/property_service.dart';
import 'package:pearlnest/models/property.dart';
import 'package:pearlnest/screens/tenant/search_screen.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class FiltersScreen extends StatefulWidget {
  final SearchFilters currentFilters;
  final List<Property> allProperties;

  const FiltersScreen({
    super.key,
    required this.currentFilters,
    required this.allProperties,
  });

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late SearchFilters _filters;
  late Future<Map<String, dynamic>> summary;

  List<String> _propertyTypes = ['All'];
  Map<String, String> _propertyTypeLabels = {'All': 'All'};

  final List<String> _availableAmenities = [
    'WiFi',
    'Parking',
    'Gym',
    'Pool',
    'Kitchen',
    'AC',
    'Garden',
    'Garage',
    'Fireplace',
    'Shared Kitchen',
    'Laundry',
    'Road Access',
    'Utilities Available',
  ];

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
    });
  }

  void _applyFilters() {
    Navigator.pop(context, _filters);
  }

  Future<Map<String, dynamic>> fetchFilterSummary() async {
    Response response = await ApiClient.get("/property/filter/summary");
    return response.data;
  }

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      propertyType: widget.currentFilters.propertyType,
      priceRange: widget.currentFilters.priceRange,
      bedrooms: widget.currentFilters.bedrooms,
      selectedAmenities: List.from(widget.currentFilters.selectedAmenities),
    );

    summary = fetchFilterSummary();
    _loadPropertyTypes();
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final types = await PropertyService.getPropertyTypeConfigs();
      if (!mounted) return;

      final typeKeys = types.map((type) => type['key'] as String).toList();
      final labels = <String, String>{
        'All': 'All',
        for (final type in types)
          type['key'] as String: type['label'] as String,
      };
      final currentType = _filters.propertyType;
      final matchingType = types.firstWhere((type) {
        final key = type['key'] as String;
        final label = type['label'] as String;
        return key.toLowerCase() == currentType.toLowerCase() ||
            label.toLowerCase() == currentType.toLowerCase();
      }, orElse: () => <String, dynamic>{});

      setState(() {
        _propertyTypes = ['All', ...typeKeys];
        _propertyTypeLabels = labels;
        if (matchingType.isNotEmpty) {
          _filters.propertyType = matchingType['key'] as String;
        } else if (currentType != 'All' && currentType.isNotEmpty) {
          _propertyTypes.add(currentType);
          _propertyTypeLabels[currentType] = currentType;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Filters',
          style: TextStyle(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.whiteColor),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyTypeFilter(),
                  SizedBox(height: 24),
                  FutureBuilder(
                      future: summary,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentGreen,
                            ),
                          );
                        }
                        if (snapshot.hasData) {
                          int? minPrice = snapshot.data?["minPrice"];
                          int? maxPrice = snapshot.data?["maxPrice"];
                          return _buildPriceRangeFilter(minPrice: 0, maxPrice: maxPrice ?? 0);
                        } else {
                          return Text(
                            "Sorry, failed to get price range",
                            style: TextStyle(color: Colors.red),
                          );
                        }
                      }),
                  SizedBox(height: 24),
                  _buildBedroomsFilter(),
                  SizedBox(height: 24),
                  _buildAmenitiesFilter(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _propertyTypes.map((type) {
            final isSelected = _filters.propertyType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _filters.propertyType = type;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryblue : AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _propertyTypeLabels[type] ?? ProfileService().stringCapitalize(type),
                  style: TextStyle(
                    color: isSelected ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter({required int minPrice, required int maxPrice}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ProfileService().currencyConverter(price: _filters.priceRange.start.round())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                  Text(
                    'to',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  Text(
                    '${ProfileService().currencyConverter(price: _filters.priceRange.end.round())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              RangeSlider(
                values: _filters.priceRange,
                min: 0,
                max: maxPrice.toDouble(),
                divisions: 5000,
                activeColor: AppTheme.primaryblue,
                inactiveColor: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                onChanged: (RangeValues values) {
                  setState(() {
                    _filters.priceRange = values;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBedroomsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bedrooms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBedroomOption('Any', null),
            ...List.generate(5, (index) => _buildBedroomOption('${index + 1}', index + 1)),
            _buildBedroomOption('5+', 6),
          ],
        ),
      ],
    );
  }

  Widget _buildBedroomOption(String label, int? value) {
    final isSelected = _filters.bedrooms == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters.bedrooms = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryblue : AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            if (_filters.selectedAmenities.isNotEmpty)
              Text(
                '${_filters.selectedAmenities.length} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryblue,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
          ),
          child: Column(
            children: _availableAmenities.map((amenity) {
              final isSelected = _filters.selectedAmenities.contains(amenity);
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _filters.selectedAmenities.remove(amenity);
                      } else {
                        _filters.selectedAmenities.add(amenity);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryblue.withOpacity(0.1) : AppTheme.getCardColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryblue : AppTheme.whiteColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryblue : AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppTheme.getCardColor(context),
                                )
                              : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            amenity,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? AppTheme.primaryblue : AppTheme.getTextColor(context),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryblue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final matchingProperties = _getMatchingPropertiesCount();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (matchingProperties >= 0)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '$matchingProperties properties match your filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _clearAllFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryblue,
                      side: BorderSide(color: AppTheme.primaryblue),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      foregroundColor: AppTheme.whiteColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getMatchingPropertiesCount() {
    return widget.allProperties.where((property) {
      final matchesType = _filters.propertyType == 'All' || property.type == _filters.propertyType;

      final matchesPrice = property.price >= _filters.priceRange.start && property.price <= _filters.priceRange.end;

      final matchesBedrooms = _filters.bedrooms == null || (_filters.bedrooms == 6 ? property.bedrooms >= 5 : property.bedrooms == _filters.bedrooms);

      final matchesAmenities = _filters.selectedAmenities.isEmpty || _filters.selectedAmenities.every((amenity) => property.amenities.contains(amenity));

      return matchesType && matchesPrice && matchesBedrooms && matchesAmenities;
    }).length;
  }
}
