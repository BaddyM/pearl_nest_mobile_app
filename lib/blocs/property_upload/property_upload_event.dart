import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class PropertyUploadEvent extends Equatable {
  const PropertyUploadEvent();

  @override
  List<Object?> get props => [];
}

class PropertyUploadRequested extends PropertyUploadEvent {
  final String propertyName;
  final String propertyType;
  final String location;
  final double price;
  final double deposit;
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
  final List<File> images;
  final bool isRent;
  final bool isSale;
  final bool parking;
  final String distance;

  const PropertyUploadRequested({
    required this.propertyName,
    required this.distance,
    required this.deposit,
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
    required this.images,
    this.isSale = false,
    this.isRent = false,
    this.parking = false,
  });

  @override
  List<Object?> get props => [
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
        images,
        deposit,
        distance,
        isSale,
        isRent,
        parking,
      ];
}

class PropertyUpdateRequested extends PropertyUploadEvent {
  final String propertyId;
  final String propertyName;
  final String propertyType;
  final String location;
  final double price;
  final double deposit;
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
  final bool availability; // true for "Available Now", false for "Available Later"
  final DateTime? availableFrom; // Only needed when availability is false
  final bool isRent;
  final bool isSale;
  final bool parking;
  final String distance;
  final List<File> images;

  const PropertyUpdateRequested({
    required this.propertyId,
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
    required this.availability,
    required this.deposit,
    required this.distance,
    this.isSale = false,
    this.isRent = false,
    this.parking = false,
    this.availableFrom,
    this.images = const [],
  });

  @override
  List<Object?> get props => [
        propertyId,
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
        availability,
        availableFrom,
        deposit,
        isRent,
        isSale,
        parking,
        distance,
        images,
      ];
}

class PropertyUploadReset extends PropertyUploadEvent {
  const PropertyUploadReset();
}
