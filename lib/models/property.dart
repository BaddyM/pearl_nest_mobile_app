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

enum AvailabilityStatus { availableNow, availableLater }

class Property {
  final String id;
  final String title;
  final String description;
  final PropertyType type;
  final double price;
  final String priceType;
  final String location;
  final String address;
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
  final AvailabilityStatus availabilityStatus;
  final DateTime? availableFrom;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.priceType,
    required this.location,
    required this.address,
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
    required this.availabilityStatus,
    this.availableFrom,
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
    AvailabilityStatus? availabilityStatus,
    DateTime? availableFrom,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      location: location ?? this.location,
      address: address ?? this.address,
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
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      availableFrom: availableFrom ?? this.availableFrom,
    );
  }

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
}
