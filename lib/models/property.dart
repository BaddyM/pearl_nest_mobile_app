enum PropertyStatus {
  available,
  booked,
  pending,
  unavailable,
  approved,
  rejected,
}

class Property {
  final String id;
  final String title;
  final String description;
  final String type;
  final double price;
  final double deposit;
  final int? advanceRentMonths;
  final int? securityDepositMonths;
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
  final bool isAdminUploaded;
  final bool parking;
  final bool isSale;
  final bool isRent;
  final bool availabilityStatus;
  final int totalUnits;
  final int availableUnits;
  final DateTime? availableFrom;
  final List<Map<String, dynamic>> views;
  final List<Map<String, dynamic>> shares;
  final List<Map<String, dynamic>> favourites;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic>? user; // Landlord information
  final String? propertyMap; // Iframe HTML for embedded map
  final String? safetyAndSecurity; // Optional safety features
  final String? nearbyPlaces; // Optional nearby places
  final String? profilePicture;
  final String? promotionDiscountType;
  final int? promotionDiscountValue;
  final DateTime? promotionStartsAt;
  final DateTime? promotionEndsAt;
  final int? promotionUsageLimit;
  final int promotionUsageCount;
  final String? promotionProposalStatus;

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
    this.isAdminUploaded = false,
    this.isRent = false,
    this.isSale = false,
    required this.deposit,
    this.advanceRentMonths,
    this.securityDepositMonths,
    this.parking = false,
    required this.availabilityStatus,
    this.totalUnits = 1,
    this.availableUnits = 1,
    this.availableFrom,
    this.views = const [],
    this.shares = const [],
    this.favourites = const [],
    this.reviews = const [],
    this.user,
    this.propertyMap,
    this.safetyAndSecurity,
    this.nearbyPlaces,
    this.promotionDiscountType,
    this.promotionDiscountValue,
    this.promotionStartsAt,
    this.promotionEndsAt,
    this.promotionUsageLimit,
    this.promotionUsageCount = 0,
    this.promotionProposalStatus,
  });

  bool get hasActivePromotion {
    final now = DateTime.now();
    return promotionDiscountType != null &&
        promotionDiscountValue != null &&
        promotionStartsAt != null &&
        promotionEndsAt != null &&
        !promotionStartsAt!.isAfter(now) &&
        promotionEndsAt!.isAfter(now) &&
        (promotionUsageLimit == null || promotionUsageCount < promotionUsageLimit!);
  }

  int get currentPromotionDiscount {
    if (!hasActivePromotion) return 0;
    final basePrice = price.toInt();
    if (promotionDiscountType == 'PERCENTAGE') {
      return (basePrice * promotionDiscountValue! / 100)
          .ceil()
          .clamp(0, basePrice)
          .toInt();
    }
    if (promotionDiscountType == 'FIXED') {
      return promotionDiscountValue!.clamp(0, basePrice).toInt();
    }
    return 0;
  }

  int get promotionalPrice =>
      (price.toInt() - currentPromotionDiscount).clamp(0, price.toInt()).toInt();

  int get promotionPercentOff =>
      price <= 0 ? 0 : (currentPromotionDiscount * 100 / price).round();

  Property copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    double? price,
    int? advanceRentMonths,
    int? securityDepositMonths,
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
    bool? isAdminUploaded,
    bool? availabilityStatus,
    int? totalUnits,
    int? availableUnits,
    DateTime? availableFrom,
    List<Map<String, dynamic>>? views,
    List<Map<String, dynamic>>? shares,
    List<Map<String, dynamic>>? favourites,
    List<Map<String, dynamic>>? reviews,
    Map<String, dynamic>? user,
    String? propertyMap,
    String? safetyAndSecurity,
    String? nearbyPlaces,
    String? profilePicture,
    String? promotionDiscountType,
    int? promotionDiscountValue,
    DateTime? promotionStartsAt,
    DateTime? promotionEndsAt,
    int? promotionUsageLimit,
    int? promotionUsageCount,
    String? promotionProposalStatus,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      deposit: deposit,
      advanceRentMonths: advanceRentMonths ?? this.advanceRentMonths,
      securityDepositMonths: securityDepositMonths ?? this.securityDepositMonths,
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
      isAdminUploaded: isAdminUploaded ?? this.isAdminUploaded,
      availabilityStatus: this.availabilityStatus,
      totalUnits: totalUnits ?? this.totalUnits,
      availableUnits: availableUnits ?? this.availableUnits,
      availableFrom: availableFrom ?? this.availableFrom,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      favourites: favourites ?? this.favourites,
      reviews: reviews ?? this.reviews,
      user: user ?? this.user,
      propertyMap: propertyMap ?? this.propertyMap,
      safetyAndSecurity: safetyAndSecurity ?? this.safetyAndSecurity,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      profilePicture: profilePicture ?? this.profilePicture,
      promotionDiscountType: promotionDiscountType ?? this.promotionDiscountType,
      promotionDiscountValue: promotionDiscountValue ?? this.promotionDiscountValue,
      promotionStartsAt: promotionStartsAt ?? this.promotionStartsAt,
      promotionEndsAt: promotionEndsAt ?? this.promotionEndsAt,
      promotionUsageLimit: promotionUsageLimit ?? this.promotionUsageLimit,
      promotionUsageCount: promotionUsageCount ?? this.promotionUsageCount,
      promotionProposalStatus: promotionProposalStatus ?? this.promotionProposalStatus,
    );
  }

  // Getter to convert PropertyType enum to string for UI display
  // String get propertyTypeString {
  //   switch (type) {
  //     case PropertyType.airbnb:
  //       return 'Airbnb';
  //     case PropertyType.hostel:
  //       return 'Hostel';
  //     case PropertyType.apartment:
  //       return 'Apartment';
  //     case PropertyType.fullHouse:
  //       return 'Full House';
  //     case PropertyType.land:
  //       return 'Land';
  //     case PropertyType.incompleteHouse:
  //       return 'Incomplete House';
  //     case PropertyType.house:
  //       return 'House';
  //     case PropertyType.studio:
  //       return 'Studio';
  //     case PropertyType.condo:
  //       return 'Condo';
  //     case PropertyType.townhouse:
  //       return 'Townhouse';
  //     case PropertyType.room:
  //       return 'Room';
  //   }
  // }

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

    double calculateRating(double sumOfItems, int numberOfItems) {
      double result = (sumOfItems / numberOfItems.toDouble());
      return result;
    }

    return Property(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? json['propertyName'] ?? '',
      description: json['description'] ?? '',
      type: json['propertyType'],
      price: (json['price'] ?? 0).toDouble(),
      deposit: (json['deposit'] ?? 0).toDouble(),
      advanceRentMonths: (json['advanceRentMonths'] as num?)?.toInt(),
      securityDepositMonths: (json['securityDepositMonths'] as num?)?.toInt(),
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
      status: _parsePropertyStatus(json['status']),
      isRent: json['isRent'],
      parking: json['parking'],
      isSale: json['isSale'],
      rating: json['reviews'] != null ? calculateRating(List<Map<String, dynamic>>.from(json['reviews']).fold<double>(0, (value, element) => value + element["stars"]), List<Map<String, dynamic>>.from(json['reviews']).length != 0 ? List<Map<String, dynamic>>.from(json['reviews']).length : 1) : 0,
      reviewCount: (json['reviews'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList().length ?? [].length,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      isFeatured: json['featured'] ?? false,
      isVerified: json['isVerified'] ?? false,
      isAdminUploaded: json['isAdminUploaded'] ?? false,
      availabilityStatus: json['availability'],
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 1,
      availableUnits: (json['availableUnits'] as num?)?.toInt() ?? 1,
      availableFrom: json['availableFrom'] != null ? DateTime.parse(json['availableFrom']) : null,
      views: (json['views'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      shares: (json['shares'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      favourites: (json['favourites'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      reviews: (json['reviews'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().toList() ?? [],
      user: user,
      propertyMap: json['propertyMap'] as String?,
      safetyAndSecurity: json['safetyAndSecurity'] as String?,
      nearbyPlaces: json['nearbyPlaces'] as String?,
      promotionDiscountType: json['promotionDiscountType'] as String?,
      promotionDiscountValue: (json['promotionDiscountValue'] as num?)?.toInt(),
      promotionStartsAt: json['promotionStartsAt'] == null
          ? null
          : DateTime.tryParse(json['promotionStartsAt'].toString()),
      promotionEndsAt: json['promotionEndsAt'] == null
          ? null
          : DateTime.tryParse(json['promotionEndsAt'].toString()),
      promotionUsageLimit: (json['promotionUsageLimit'] as num?)?.toInt(),
      promotionUsageCount: (json['promotionUsageCount'] as num?)?.toInt() ?? 0,
      promotionProposalStatus: json['promotionProposalStatus'] as String?,
    );
  }

  // Helper method to parse PropertyType from string
  // static PropertyType _parsePropertyType(String typeString) {
  //   switch (typeString.toLowerCase()) {
  //     case 'airbnb':
  //       return PropertyType.airbnb;
  //     case 'hostel':
  //       return PropertyType.hostel;
  //     case 'apartment':
  //       return PropertyType.apartment;
  //     case 'fullhouse':
  //     case 'full_house':
  //       return PropertyType.fullHouse;
  //     case 'land':
  //       return PropertyType.land;
  //     case 'incompletehouse':
  //     case 'incomplete_house':
  //       return PropertyType.incompleteHouse;
  //     case 'house':
  //       return PropertyType.house;
  //     case 'studio':
  //       return PropertyType.studio;
  //     case 'condo':
  //       return PropertyType.condo;
  //     case 'townhouse':
  //       return PropertyType.townhouse;
  //     case 'room':
  //       return PropertyType.room;
  //     default:
  //       return PropertyType.apartment;
  //   }
  // }

  // Helper method to parse PropertyStatus from string
  static PropertyStatus _parsePropertyStatus(String status) {
    switch (status.toUpperCase()) {
      case "BOOKED":
        return PropertyStatus.booked;
      case 'APPROVED':
        return PropertyStatus.approved;
      case 'REJECTED':
        return PropertyStatus.rejected;
      case 'PENDING':
        return PropertyStatus.pending;
      default:
        return PropertyStatus.pending;
    }
  }

  // Convert Property to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyName': title,
      'description': description,
      'propertyType': type,
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
      'isAdminUploaded': isAdminUploaded,
      'availability': availabilityStatus,
      'totalUnits': totalUnits,
      'availableUnits': availableUnits,
      'availableFrom': availableFrom?.toIso8601String(),
      'views': views,
      'shares': shares,
      'favourites': favourites,
      'user': user,
      'propertyMap': propertyMap,
      'safetyAndSecurity': safetyAndSecurity,
      'nearbyPlaces': nearbyPlaces,
      'promotionDiscountType': promotionDiscountType,
      'promotionDiscountValue': promotionDiscountValue,
      'promotionStartsAt': promotionStartsAt?.toIso8601String(),
      'promotionEndsAt': promotionEndsAt?.toIso8601String(),
      'promotionUsageLimit': promotionUsageLimit,
      'promotionUsageCount': promotionUsageCount,
      'promotionProposalStatus': promotionProposalStatus,
    };
  }
}
