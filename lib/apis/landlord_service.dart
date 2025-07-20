import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class LandlordService {
  static const String _landlordRegistrationEndpoint = '/user/landlordRegistration';
  static const String _uploadDocumentEndpoint = '/property/uploadDocument';

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
        debugPrint('📤 Submitting landlord application for: $businessName');
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
          debugPrint('✅ Landlord application submitted successfully');
        }
        
        return {
          'success': true,
          'message': 'Application submitted successfully',
          'data': response.data,
        };
      } else {
        if (kDebugMode) {
          debugPrint('❌ Landlord application failed with status: ${response.statusCode}');
        }
        
        return {
          'success': false,
          'message': response.data['message'] ?? 'Application submission failed',
          'error': response.data,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Landlord application error: $e');
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
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Uploading document: $title');
        debugPrint('📁 File path: $filePath');
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
        'document': multipartFile,  // Changed from 'file' to 'document'
        'title': title,
      });

      final response = await ApiClient.postMultipart(_uploadDocumentEndpoint, formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Document uploaded successfully: $title');
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
      
      if (e.toString().contains('Only pdf,doc or docx files are allowed')) {
        errorMessage = 'Invalid file type. Only PDF, DOC, and DOCX files are allowed.';
      } else if (e.toString().contains('File size')) {
        errorMessage = 'File size too large. Maximum 10MB allowed.';
      } else if (e.toString().contains('Connection timeout')) {
        errorMessage = 'Upload timeout. Please check your connection and try again.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your internet connection.';
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
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Uploading ${documents.length} documents');
      }

      final List<String> uploadedDocuments = [];
      final List<String> failedDocuments = [];

      for (final entry in documents.entries) {
        final documentType = entry.key;
        final filePath = entry.value;

        final result = await uploadDocument(
          filePath: filePath,
          title: documentType,
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
        debugPrint('💥 Multiple documents upload error: $e');
      }
      
      return {
        'success': false,
        'message': 'Failed to upload documents. Please try again.',
        'error': e.toString(),
      };
    }
  }
}
