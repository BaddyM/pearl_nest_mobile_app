import 'package:flutter_test/flutter_test.dart';
import 'package:pearlnest/models/property.dart';

void main() {
  Property property({
    String type = 'apartment',
    String priceType = '',
    bool isRent = false,
    bool isSale = false,
  }) {
    final now = DateTime(2026);
    return Property(
      id: 'property-id',
      title: 'Property',
      description: '',
      type: type,
      price: 100,
      priceType: priceType,
      location: '',
      address: '',
      latitude: 0,
      longitude: 0,
      images: const [],
      amenities: const [],
      bedrooms: 0,
      bathrooms: 0,
      area: 0,
      landlordId: '',
      landlordName: '',
      landlordPhone: '',
      landlordEmail: '',
      status: PropertyStatus.approved,
      rating: 0,
      reviewCount: 0,
      createdAt: now,
      updatedAt: now,
      deposit: 0,
      availabilityStatus: true,
      isRent: isRent,
      isSale: isSale,
    );
  }

  test('normalizes known pricing periods', () {
    expect(property(priceType: 'per_night').pricePeriodLabel, '/ night');
    expect(property(priceType: '/month').pricePeriodLabel, '/ month');
    expect(property(priceType: 'year').pricePeriodLabel, '/ year');
    expect(property(priceType: 'for_sale').pricePeriodLabel, 'For sale');
  });

  test('uses listing type defaults when the pricing period is missing', () {
    expect(property(type: 'land_/ plot').pricePeriodLabel, 'total');
    expect(property(isRent: true).pricePeriodLabel, '/ month');
    expect(property().pricePeriodLabel, '');
    expect(property(isSale: true).pricePeriodLabel, 'For sale');
  });

  test('preserves unrecognized pricing periods', () {
    expect(property(priceType: 'Per quarter').pricePeriodLabel, 'Per quarter');
  });
}
