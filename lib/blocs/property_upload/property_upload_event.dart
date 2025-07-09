import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class PropertyUploadEvent extends Equatable {
  const PropertyUploadEvent();

  @override
  List<Object?> get props => [];
}

class PropertyUploadRequested extends PropertyUploadEvent {
  final String userId;
  final String propertyName;
  final String propertyType;
  final String location;
  final double price;
  final String amenities;
  final String safetyAndSecurity;
  final String description;
  final String nearbyPlaces;
  final int numberOfBeds;
  final int numberOfBathrooms;
  final String areaMeasurement;
  final String neighborhood;
  final String fullAddress;
  final String propertyMap;
  final String period;
  final bool featured;
  final bool isVerified;
  final bool availability;
  final List<File> images;

  const PropertyUploadRequested({
    required this.userId,
    required this.propertyName,
    required this.propertyType,
    required this.location,
    required this.price,
    required this.amenities,
    required this.safetyAndSecurity,
    required this.description,
    required this.nearbyPlaces,
    required this.numberOfBeds,
    required this.numberOfBathrooms,
    required this.areaMeasurement,
    required this.neighborhood,
    required this.fullAddress,
    required this.propertyMap,
    required this.period,
    required this.featured,
    required this.isVerified,
    required this.availability,
    required this.images,
  });

  @override
  List<Object?> get props => [
        userId,
        propertyName,
        propertyType,
        location,
        price,
        amenities,
        safetyAndSecurity,
        description,
        nearbyPlaces,
        numberOfBeds,
        numberOfBathrooms,
        areaMeasurement,
        neighborhood,
        fullAddress,
        propertyMap,
        period,
        featured,
        isVerified,
        availability,
        images,
      ];
}

class PropertyUploadReset extends PropertyUploadEvent {
  const PropertyUploadReset();
}
