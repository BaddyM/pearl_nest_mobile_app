import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_event.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_state.dart';
import 'package:pearlnest/apis/property_service.dart';

class PropertyUploadBloc extends Bloc<PropertyUploadEvent, PropertyUploadState> {
  PropertyUploadBloc() : super(const PropertyUploadInitial()) {
    on<PropertyUploadRequested>(_onPropertyUploadRequested);
    on<PropertyUploadReset>(_onPropertyUploadReset);
  }

  Future<void> _onPropertyUploadRequested(
    PropertyUploadRequested event,
    Emitter<PropertyUploadState> emit,
  ) async {
    try {
      emit(const PropertyUploadLoading());

      debugPrint('PropertyUploadBloc: Starting property upload...');

      // Validate required fields
      final validationErrors = _validateFields(event);
      if (validationErrors.isNotEmpty) {
        emit(PropertyUploadValidationError(fieldErrors: validationErrors));
        return;
      }

      // Call the property service to upload
      final result = await PropertyService.uploadProperty(
        propertyName: event.propertyName,
        propertyType: event.propertyType,
        location: event.location,
        price: event.price,
        amenities: event.amenities,
        safetyAndSecurity: event.safetyAndSecurity,
        description: event.description,
        nearbyPlaces: event.nearbyPlaces,
        numberOfBeds: event.numberOfBeds,
        numberOfBathrooms: event.numberOfBathrooms,
        areaMeasurement: event.areaMeasurement,
        neighborhood: event.neighborhood,
        fullAddress: event.fullAddress,
        propertyMap: event.propertyMap,
        period: event.period,
        featured: event.featured,
        isVerified: event.isVerified,
        availability: event.availability,
        images: event.images,
      );

      if (result['success'] == true) {
        debugPrint('PropertyUploadBloc: Upload successful');
        emit(PropertyUploadSuccess(
          message: result['message'] ?? 'Property uploaded successfully!',
          propertyData: result['data'],
        ));
      } else {
        debugPrint('PropertyUploadBloc: Upload failed - ${result['message']}');
        emit(PropertyUploadError(
          message: result['message'] ?? 'Failed to upload property',
          errorCode: result['code'],
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('PropertyUploadBloc: Upload error - $e');
      debugPrint('Stack trace: $stackTrace');

      String errorMessage = 'An unexpected error occurred';
      String? errorCode;

      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
        errorCode = 'NETWORK_ERROR';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
        errorCode = 'TIMEOUT_ERROR';
      } else if (e.toString().contains('validation')) {
        errorMessage = 'Invalid data provided. Please check all fields.';
        errorCode = 'VALIDATION_ERROR';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'You are not authorized to perform this action.';
        errorCode = 'UNAUTHORIZED';
      }

      emit(PropertyUploadError(
        message: errorMessage,
        errorCode: errorCode,
      ));
    }
  }

  void _onPropertyUploadReset(
    PropertyUploadReset event,
    Emitter<PropertyUploadState> emit,
  ) {
    emit(const PropertyUploadInitial());
  }

  Map<String, String> _validateFields(PropertyUploadRequested event) {
    final Map<String, String> errors = {};

    if (event.propertyName.trim().isEmpty) {
      errors['propertyName'] = 'Property name is required';
    }

    if (event.propertyType.trim().isEmpty) {
      errors['propertyType'] = 'Property type is required';
    }

    if (event.location.trim().isEmpty) {
      errors['location'] = 'Location is required';
    }

    if (event.price <= 0) {
      errors['price'] = 'Price must be greater than 0';
    }

    if (event.description.trim().isEmpty) {
      errors['description'] = 'Description is required';
    }

    if (event.numberOfBeds < 0) {
      errors['numberOfBeds'] = 'Number of bedrooms cannot be negative';
    }

    if (event.numberOfBathrooms < 0) {
      errors['numberOfBathrooms'] = 'Number of bathrooms cannot be negative';
    }

    if (event.areaMeasurement.trim().isEmpty) {
      errors['areaMeasurement'] = 'Area measurement is required';
    }

    if (event.neighborhood.trim().isEmpty) {
      errors['neighborhood'] = 'Neighborhood is required';
    }

    if (event.fullAddress.trim().isEmpty) {
      errors['fullAddress'] = 'Full address is required';
    }

    if (event.period.trim().isEmpty) {
      errors['period'] = 'Period is required';
    }

    if (event.images.isEmpty) {
      errors['images'] = 'At least one image is required';
    }

    // Validate property map iframe if provided
    if (event.propertyMap.isNotEmpty) {
      if (!event.propertyMap.contains('<iframe') || !event.propertyMap.contains('src=')) {
        errors['propertyMap'] = 'Please provide a valid iframe embed code';
      }
    }

    return errors;
  }
}
