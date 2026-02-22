enum PropertyType {
  airbnb,
  hostel,
  apartment,
  fullHouse,
  land,
  incompleteHouse,
  house,
  studio,
  condo,
  townhouse,
  room,
}

enum PropertyStatus {
  available,
  booked,
  pending,
  unavailable,
}

class Property {
  final String id;
  final String title;
  final String description;
  final PropertyType type;
  final double price;
  final double deposit;
  final String priceType;
  final String location;
  final String address;
  final String? neighborhood; // Optional neighborhood field
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String landlordId;
  final String landlordName;
  final String landlordPhone;
  final String landlordEmail;
  final PropertyStatus status;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFeatured;
  final bool isVerified;
  final bool parking;
  final bool isSale;
  final bool isRent;
  final bool availabilityStatus;
  final DateTime? availableFrom;
  final List<Map<String, dynamic>> views;
  final List<Map<String, dynamic>> shares;
  final List<Map<String, dynamic>> favourites;
  final Map<String, dynamic>? user; // Landlord information
  final String? propertyMap; // Iframe HTML for embedded map
  final String? safetyAndSecurity; // Optional safety features
  final String? nearbyPlaces; // Optional nearby places
  final String? profilePicture;

  Property({
    this.profilePicture,
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.priceType,
    required this.location,
    required this.address,
    this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.landlordId,
    required this.landlordName,
    required this.landlordPhone,
    required this.landlordEmail,
    required this.status,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.isFeatured = false,
    this.isVerified = false,
    this.isRent = false,
    this.isSale = false,
    required this.deposit,
    this.parking = false,
    required this.availabilityStatus,
    this.availableFrom,
    this.views = const [],
    this.shares = const [],
    this.favourites = const [],
    this.user,
    this.propertyMap,
    this.safetyAndSecurity,
    this.nearbyPlaces,
  });

  Property copyWith({
    String? id,
    String? title,
    String? description,
    PropertyType? type,
    double? price,
    String? priceType,
    String? location,
    String? address,
    String? neighborhood,
    double? latitude,
    double? longitude,
    List<String>? images,
    List<String>? amenities,
    int? bedrooms,
    int? bathrooms,
    double? area,
    String? landlordId,
    String? landlordName,
    String? landlordPhone,
    String? landlordEmail,
    PropertyStatus? status,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFeatured,
    bool? isVerified,
    bool? availabilityStatus,
    DateTime? availableFrom,
    List<Map<String, dynamic>>? views,
    List<Map<String, dynamic>>? shares,
    List<Map<String, dynamic>>? favourites,
    Map<String, dynamic>? user,
    String? propertyMap,
    String? safetyAndSecurity,
    String? nearbyPlaces,
    String? profilePicture,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      deposit: deposit,
      isSale: isSale,
      isRent: isRent,
      parking: parking,
      priceType: priceType ?? this.priceType,
      location: location ?? this.location,
      address: address ?? this.address,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      landlordId: landlordId ?? this.landlordId,
      landlordName: landlordName ?? this.landlordName,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      landlordEmail: landlordEmail ?? this.landlordEmail,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      availabilityStatus: this.availabilityStatus,
      availableFrom: availableFrom ?? this.availableFrom,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      favourites: favourites ?? this.favourites,
      user: user ?? this.user,
      propertyMap: propertyMap ?? this.propertyMap,
      safetyAndSecurity: safetyAndSecurity ?? this.safetyAndSecurity,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  // Getter to convert PropertyType enum to string for UI display
  String get propertyTypeString {
    switch (type) {
      case PropertyType.airbnb:
        return 'Airbnb';
      case PropertyType.hostel:
        return 'Hostel';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.fullHouse:
        return 'Full House';
      case PropertyType.land:
        return 'Land';
      case PropertyType.incompleteHouse:
        return 'Incomplete House';
      case PropertyType.house:
        return 'House';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.room:
        return 'Room';
    }
  }

  // Factory constructor for creating Property from JSON
  factory Property.fromJson(Map<String, dynamic> json) {
    List<String> parseStringOrList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    // Support both 'images' and 'media' keys for images
    final images = json['images'] ?? json['media'];
    final user = json['user'] as Map<String, dynamic>?;

    return Property(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? json['propertyName'] ?? '',
      description: json['description'] ?? '',
      type: _parsePropertyType(json['type'] ?? json['propertyType'] ?? 'apartment'),
      price: (json['price'] ?? 0).toDouble(),
      deposit: (json['deposit'] ?? 0).toDouble(),
      priceType: json['priceType'] ?? json['period'] ?? 'monthly',
      location: json['location'] ?? '',
      address: json['address'] ?? json['fullAddress'] ?? '',
      neighborhood: json['neighborhood'] as String?,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      images: parseStringOrList(images),
      amenities: parseStringOrList(json['amenities']),
      bedrooms: json['bedrooms'] ?? json['numberOfBeds'] ?? 0,
      bathrooms: json['bathrooms'] ?? json['numberOfBathrooms'] ?? 0,
      area: double.tryParse((json['area'] ?? json['areaMeasurement'] ?? '0').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
      landlordId: json['landlordId'] ?? json['ownerId'] ?? json['userId'] ?? '',
      landlordName: json['landlordName'] ?? json['ownerName'] ?? user?['name'] ?? '',
      landlordPhone: json['landlordPhone'] ?? json['ownerPhone'] ?? user?['contact'] ?? '',
      landlordEmail: json['landlordEmail'] ?? json['ownerEmail'] ?? user?['email'] ?? '',
      profilePicture: json['profilePicture'] ?? user?['profilePicture'] ?? '',
      status: json['status'] != null
          ? _parsePropertyStatus(json['status'])
          : json['availability'] == false
              ? PropertyStatus.unavailable
              : PropertyStatus.available,
      isRent: json['isRent'],
      parking: json['parking'],
      isSale: json['isSale'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      isFeatured: json['featured'] ?? false,
      isVerified: json['isVerified'] ?? false,
      availabilityStatus: json['availability'],
      availableFrom: json['availableFrom'] != null ? DateTime.parse(json['availableFrom']) : null,
      views: (json['views'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      shares: (json['shares'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      favourites: (json['favourites'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      user: user,
      propertyMap: json['propertyMap'] as String?,
      safetyAndSecurity: json['safetyAndSecurity'] as String?,
      nearbyPlaces: json['nearbyPlaces'] as String?,
    );
  }

  // Helper method to parse PropertyType from string
  static PropertyType _parsePropertyType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'airbnb':
        return PropertyType.airbnb;
      case 'hostel':
        return PropertyType.hostel;
      case 'apartment':
        return PropertyType.apartment;
      case 'fullhouse':
      case 'full_house':
        return PropertyType.fullHouse;
      case 'land':
        return PropertyType.land;
      case 'incompletehouse':
      case 'incomplete_house':
        return PropertyType.incompleteHouse;
      case 'house':
        return PropertyType.house;
      case 'studio':
        return PropertyType.studio;
      case 'condo':
        return PropertyType.condo;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'room':
        return PropertyType.room;
      default:
        return PropertyType.apartment;
    }
  }

  // Helper method to parse PropertyStatus from string
  static PropertyStatus _parsePropertyStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'available':
        return PropertyStatus.available;
      case 'booked':
        return PropertyStatus.booked;
      case 'pending':
        return PropertyStatus.pending;
      case 'unavailable':
        return PropertyStatus.unavailable;
      default:
        return PropertyStatus.available;
    }
  }

  // Convert Property to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyName': title,
      'description': description,
      'propertyType': propertyTypeString,
      'price': price,
      'period': priceType,
      'location': location,
      'fullAddress': address,
      'neighborhood': neighborhood,
      'latitude': latitude,
      'longitude': longitude,
      'media': images.join(','),
      'amenities': amenities.join(', '),
      'numberOfBeds': bedrooms,
      'numberOfBathrooms': bathrooms,
      'areaMeasurement': '$area sq meters',
      'userId': landlordId,
      'status': status.toString().split('.').last,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'featured': isFeatured,
      'isVerified': isVerified,
      'availability': availabilityStatus,
      'availableFrom': availableFrom?.toIso8601String(),
      'views': views,
      'shares': shares,
      'favourites': favourites,
      'user': user,
      'propertyMap': propertyMap,
      'safetyAndSecurity': safetyAndSecurity,
      'nearbyPlaces': nearbyPlaces,
    };
  }
}
