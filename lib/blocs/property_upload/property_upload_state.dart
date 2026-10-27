import 'package:equatable/equatable.dart';

abstract class PropertyUploadState extends Equatable {
  const PropertyUploadState();

  @override
  List<Object?> get props => [];
}

class PropertyUploadInitial extends PropertyUploadState {
  const PropertyUploadInitial();
}

class PropertyUploadLoading extends PropertyUploadState {
  const PropertyUploadLoading();
}

class PropertyUploadSuccess extends PropertyUploadState {
  final String message;
  final Map<String, dynamic>? propertyData;

  const PropertyUploadSuccess({
    required this.message,
    this.propertyData,
  });

  @override
  List<Object?> get props => [message, propertyData];
}

class PropertyUploadError extends PropertyUploadState {
  final String message;
  final String? errorCode;

  const PropertyUploadError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class PropertyUploadValidationError extends PropertyUploadState {
  final Map<String, String> fieldErrors;

  const PropertyUploadValidationError({
    required this.fieldErrors,
  });

  @override
  List<Object?> get props => [fieldErrors];
}
