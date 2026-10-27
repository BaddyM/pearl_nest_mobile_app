import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class LandlordService {
  static const String _landlordRegistrationEndpoint = '/user/landlordRegistration';

  /// Submit landlord registration application
  static Future<Map<String, dynamic>> submitLandlordApplication({
    required String businessName,
    required String regNo,
    required String district,
    required String parish,
    required List<String> propertySpecialization,
    required String about,
  }) async {
    try {
      if (kDebugMode) {
        //debugPrint('📤 Submitting landlord application for: $businessName');
      }

      final requestBody = {
        'businessName': businessName,
        'regNo': regNo,
        'district': district,
        'parish': parish,
        'propertySpecialization': propertySpecialization.join(', '),
        'about': about,
      };

      final response = await ApiClient.post(_landlordRegistrationEndpoint, requestBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          //debugPrint('✅ Landlord application submitted successfully');
        }

        return {
          'success': true,
          'message': 'Application submitted successfully',
          'data': response.data,
        };
      } else {
        if (kDebugMode) {
          //debugPrint('❌ Landlord application failed with status: ${response.statusCode}');
        }

        return {
          'success': false,
          'message': response.data['message'] ?? 'Application submission failed',
          'error': response.data,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('💥 Landlord application error: $e');
      }

      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Upload document for landlord application
  static Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String title,
    required String registrationId,
  }) async {
    try {
      if (kDebugMode) {
        //debugPrint('📤 Uploading document: $title');
        //debugPrint('📁 File path: $filePath');
      }

      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Validate file size (optional - e.g., max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File size too large. Maximum 10MB allowed.');
      }

      // Create multipart file
      String fileName = filePath.split('/').last;
      MultipartFile multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      // Create form data with correct field names
      FormData formData = FormData.fromMap({
        'document': multipartFile, // Changed from 'file' to 'document'
        'title': title,
      });

      final response = await ApiClient.postMultipart('/property/uploadDocument/$registrationId', formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          //debugPrint('✅ Document uploaded successfully: $title');
        }

        return {
          'success': true,
          'message': 'Document uploaded successfully',
          'data': response.data,
        };
      } else {
        if (kDebugMode) {
          debugPrint('❌ Document upload failed with status: ${response.statusCode}');
          debugPrint('📋 Response data: ${response.data}');
        }

        return {
          'success': false,
          'message': response.data['message'] ?? 'Document upload failed',
          'error': response.data,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Document upload error: $e');
      }

      // Extract more specific error messages
      String errorMessage = 'Failed to upload document. Please try again.';

      final errorString = e.toString().toLowerCase();

      if (errorString.contains('only pdf,doc or docx files are allowed') || errorString.contains('invalid file type') || errorString.contains('file format')) {
        errorMessage = 'Invalid file type. Only PDF, DOC, and DOCX files are allowed.';
      } else if (errorString.contains('file size') || errorString.contains('too large')) {
        errorMessage = 'File size too large. Maximum 10MB allowed.';
      } else if (errorString.contains('receivetimeout') || errorString.contains('receive timeout') || errorString.contains('took longer than')) {
        errorMessage = 'Upload timeout. The file is taking too long to upload. Please check your internet connection and try again.';
      } else if (errorString.contains('connecttimeout') || errorString.contains('connection timeout') || errorString.contains('failed to connect')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (errorString.contains('network error') || errorString.contains('no internet') || errorString.contains('socketexception')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('server error') || errorString.contains('internal server error')) {
        errorMessage = 'Server error. Please try again later.';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  /// Upload multiple documents for landlord application
  static Future<Map<String, dynamic>> uploadMultipleDocuments({
    required Map<String, String> documents,
    Function(String documentType, bool success)? onDocumentUploaded,
    Function(String documentType, int current, int total)? onDocumentStartUpload,
    required String registrationId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('registrationId: ${registrationId}');
        debugPrint('📤 Uploading ${documents.length} documents');
      }

      final List<String> uploadedDocuments = [];
      final List<String> failedDocuments = [];
      final entries = documents.entries.toList();

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final documentType = entry.key;
        final filePath = entry.value;

        // Notify start of upload for this document
        onDocumentStartUpload?.call(documentType, i + 1, entries.length);

        final result = await uploadDocument(
          filePath: filePath,
          title: documentType,
          registrationId: registrationId,
        );

        if (result['success'] == true) {
          uploadedDocuments.add(documentType);
          onDocumentUploaded?.call(documentType, true);
        } else {
          failedDocuments.add(documentType);
          onDocumentUploaded?.call(documentType, false);
        }
      }

      if (failedDocuments.isEmpty) {
        return {
          'success': true,
          'message': 'All documents uploaded successfully',
          'uploadedDocuments': uploadedDocuments,
        };
      } else {
        return {
          'success': false,
          'message': 'Some documents failed to upload',
          'uploadedDocuments': uploadedDocuments,
          'failedDocuments': failedDocuments,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('💥 Multiple documents upload error: $e');
      }

      return {
        'success': false,
        'message': 'Failed to upload documents. Please try again.',
        'error': e.toString(),
      };
    }
  }
}
