// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  double _priceSliderMax = 5000;
  String? _priceRangeError;

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
      _minPriceController.text = '0';
      _maxPriceController.clear();
      _priceRangeError = null;
    });
  }

  void _applyFilters() {
    final minimum = _parsedPrice(_minPriceController.text) ?? 0;
    final maximumIsUnlimited = _maxPriceController.text.trim().isEmpty;
    final maximum = maximumIsUnlimited
        ? (_priceSliderMax > minimum ? _priceSliderMax : minimum)
        : _parsedPrice(_maxPriceController.text);
    if (maximum == null || (!maximumIsUnlimited && minimum > maximum)) {
      setState(() {
        _priceRangeError =
            'Enter a maximum price greater than or equal to the minimum.';
      });
      return;
    }

    _filters.priceRange = RangeValues(minimum, maximum);
    _filters.maxPriceUnlimited = maximumIsUnlimited;
    Navigator.pop(context, _filters);
  }

  Future<Map<String, dynamic>> fetchFilterSummary() async {
    Response response = await ApiClient.get("/property/filter/summary");
    final data = Map<String, dynamic>.from(response.data as Map);
    final maximum = data['maxPrice'];
    if (maximum is num && maximum > 0) {
      _priceSliderMax = maximum.toDouble();
    }
    return data;
  }

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      propertyType: widget.currentFilters.propertyType,
      priceRange: widget.currentFilters.priceRange,
      maxPriceUnlimited: widget.currentFilters.maxPriceUnlimited,
      bedrooms: widget.currentFilters.bedrooms,
      selectedAmenities: List.from(widget.currentFilters.selectedAmenities),
    );
    _minPriceController.text = _filters.priceRange.start.round().toString();
    if (!_filters.maxPriceUnlimited) {
      _maxPriceController.text = _filters.priceRange.end.round().toString();
    }

    summary = fetchFilterSummary();
    _loadPropertyTypes();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  double? _parsedPrice(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed);
  }

  void _updatePriceRangeFromFields(double sliderMax) {
    final minimum = _parsedPrice(_minPriceController.text);
    final maximumIsUnlimited = _maxPriceController.text.trim().isEmpty;
    final maximum =
        maximumIsUnlimited
            ? (minimum != null && minimum > sliderMax ? minimum : sliderMax)
            : _parsedPrice(_maxPriceController.text);

    setState(() {
      if (minimum == null ||
          maximum == null ||
          (!maximumIsUnlimited && minimum > maximum)) {
        _priceRangeError =
            'Enter a maximum price greater than or equal to the minimum.';
        return;
      }

      _filters.priceRange = RangeValues(minimum, maximum);
      _filters.maxPriceUnlimited = maximumIsUnlimited;
      _priceRangeError = null;
    });
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
                          final maxPrice = snapshot.data?['maxPrice'];
                          return _buildPriceRangeFilter(
                            maxPrice: maxPrice is num && maxPrice > 0
                                ? maxPrice.toDouble()
                                : _priceSliderMax,
                          );
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

  Widget _buildPriceRangeFilter({required double maxPrice}) {
    final sliderMax = [
      maxPrice,
      _priceSliderMax,
      _filters.priceRange.end,
      1.0,
    ].reduce((left, right) => left > right ? left : right);
    final sliderStart = _filters.priceRange.start.clamp(0, sliderMax).toDouble();
    final sliderEnd = _filters.maxPriceUnlimited
        ? sliderMax
        : _filters.priceRange.end.clamp(sliderStart, sliderMax).toDouble();

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
                children: [
                  Expanded(
                    child: Text(
                      ProfileService().currencyConverter(
                        price: _filters.priceRange.start.round(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _filters.maxPriceUnlimited
                          ? 'No maximum'
                          : ProfileService().currencyConverter(
                              price: _filters.priceRange.end.round(),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryblue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceInput(
                      controller: _minPriceController,
                      label: 'Min price',
                      onChanged: (_) => _updatePriceRangeFromFields(sliderMax),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildPriceInput(
                      controller: _maxPriceController,
                      label: 'Max price',
                      onChanged: (_) => _updatePriceRangeFromFields(sliderMax),
                    ),
                  ),
                ],
              ),
              if (_priceRangeError != null) ...[
                SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _priceRangeError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(sliderStart, sliderEnd),
                min: 0,
                max: sliderMax,
                divisions: 5000,
                activeColor: AppTheme.primaryblue,
                inactiveColor: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                onChanged: (RangeValues values) {
                  setState(() {
                    _filters.priceRange = values;
                    _filters.maxPriceUnlimited = false;
                    _minPriceController.text = values.start.round().toString();
                    _maxPriceController.text = values.end.round().toString();
                    _priceRangeError = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    final borderRadius = BorderRadius.circular(10);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        labelStyle: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppTheme.primaryblue),
        ),
      ),
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

      final matchesPrice = property.price >= _filters.priceRange.start &&
          (_filters.maxPriceUnlimited ||
              property.price <= _filters.priceRange.end);

      final matchesBedrooms = _filters.bedrooms == null || (_filters.bedrooms == 6 ? property.bedrooms >= 5 : property.bedrooms == _filters.bedrooms);

      final matchesAmenities = _filters.selectedAmenities.isEmpty || _filters.selectedAmenities.every((amenity) => property.amenities.contains(amenity));

      return matchesType && matchesPrice && matchesBedrooms && matchesAmenities;
    }).length;
  }
}
