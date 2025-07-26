// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/apis/landlord_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class LandlordApplicationScreen extends StatefulWidget {
  final User user;
  const LandlordApplicationScreen({super.key, required this.user});

  @override
  _LandlordApplicationScreenState createState() => _LandlordApplicationScreenState();
}

class _LandlordApplicationScreenState extends State<LandlordApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _physicalAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zoneController = TextEditingController();
  final _villageController = TextEditingController();
  
  final List<String> _selectedSpecializations = [];
  final Map<String, String?> _uploadedDocuments = {
    'Business Registration Certificate': null,
    'Valid ID/Passport': null,
    'Proof of Address': null,
    'Tax Registration': null,
  };
  final Map<String, String?> _documentFilePaths = {
    'Business Registration Certificate': null,
    'Valid ID/Passport': null,
    'Proof of Address': null,
    'Tax Registration': null,
  };

  bool _isSubmittingApplication = false;

  String? _selectedDistrict;
  String? _selectedParish;

  final List<String> _districts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Mbarara',
    'Gulu',
    'Lira',
    'Masaka',
  ];

  final Map<String, List<String>> _parishes = {
    'Kampala': ['Central Division', 'Kawempe Division', 'Makindye Division', 'Nakawa Division', 'Rubaga Division'],
    'Wakiso': ['Busukuma', 'Katabi', 'Wakiso', 'Ssisa', 'Gombe'],
    'Mukono': ['Mukono TC', 'Ntenjeru', 'Kyampisi', 'Nama', 'Ntunda'],
    'Jinja': ['Jinja 1', 'Jinja 2', 'Jinja 3', 'Jinja 4', 'Jinja 5'],
    'Mbarara': ['Mbarara 1', 'Mbarara 2', 'Mbarara 3', 'Mbarara 4', 'Mbarara 5'],
    'Gulu': ['Gulu 1', 'Gulu 2', 'Gulu 3', 'Gulu 4', 'Gulu 5'],
    'Lira': ['Lira 1', 'Lira 2', 'Lira 3', 'Lira 4', 'Lira 5'],
    'Masaka': ['Masaka 1', 'Masaka 2', 'Masaka 3', 'Masaka 4', 'Masaka 5'],
  };

  final List<String> _specializationOptions = [
    'Apartments',
    'Hostels',
    'Airbnb',
    'Full Houses',
    'Land',
    'Commercial Properties',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryblue,
                      AppTheme.primaryblue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryblue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        "assets/icon.png",
                        height: 48,
                        width: 48,
                      )
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Join PearlNest as a Landlord',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fill out this application to start listing your properties and grow your business with us',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.whiteColor.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        title: 'Business Information',
                        icon: Icons.business_center,
                        children: [
                          _buildTextField(
                            controller: _businessNameController,
                            label: 'Business Name',
                            icon: Icons.business,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your business name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _registrationNumberController,
                            label: 'Business Registration Number',
                            icon: Icons.numbers,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your registration number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Business Address',
                        icon: Icons.location_on,
                        children: [
                          Column(
                            children: [
                              _buildDropdownField(
                                value: _selectedDistrict,
                                label: 'District',
                                icon: Icons.map,
                                items: _districts,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDistrict = value;
                                    _selectedParish = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                value: _selectedParish,
                                label: 'Parish',
                                icon: Icons.location_city,
                                items: _selectedDistrict != null
                                    ? _parishes[_selectedDistrict!] ?? []
                                    : [],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedParish = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _zoneController,
                                  label: 'Zone',
                                  icon: Icons.place,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _villageController,
                                  label: 'Village',
                                  icon: Icons.home_work,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _physicalAddressController,
                            label: 'Physical Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                            hint: 'Enter detailed physical address (building, street, landmarks)',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your physical address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Property Specializations',
                        icon: Icons.apartment,
                        children: [
                          _buildSpecializationsSelector(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'About Your Business',
                        icon: Icons.description,
                        children: [
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Business Description',
                            icon: Icons.edit_note,
                            maxLines: 4,
                            hint: 'Tell us about your business, experience, and what makes you unique...',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Verification Documents',
                        icon: Icons.verified_user,
                        children: [
                          _buildDocumentUploadSection(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryblue, AppTheme.primaryblue.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryblue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmittingApplication ? null : _handleSubmitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmittingApplication
                              ? const CircularProgressIndicator(color: AppTheme.whiteColor)
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.whiteColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryblue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryblue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: AppTheme.getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryblue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryblue, width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      style: TextStyle(color: AppTheme.getTextColor(context)),
      dropdownColor: AppTheme.getCardColor(context),
    );
  }

  Widget _buildSpecializationsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your property specializations:',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _specializationOptions.map((specialization) {
            final isSelected = _selectedSpecializations.contains(specialization);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSpecializations.remove(specialization);
                  } else {
                    _selectedSpecializations.add(specialization);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryblue
                      : AppTheme.getBackgroundColor(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryblue
                        : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryblue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.whiteColor,
                        size: 18,
                      ),
                    if (isSelected) const SizedBox(width: 8),
                    Text(
                      specialization,
                      style: TextStyle(
                        color: isSelected ? AppTheme.whiteColor : AppTheme.getTextColor(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryblue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryblue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryblue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload each document separately for faster verification',
                      style: TextStyle(
                        color: AppTheme.primaryblue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accepted formats: PDF, DOC, DOCX • Maximum size: 10MB',
                      style: TextStyle(
                        color: AppTheme.primaryblue.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._uploadedDocuments.entries.map((entry) {
          final documentType = entry.key;
          final fileName = entry.value;
          final isUploaded = fileName != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppTheme.primaryblue.withOpacity(0.05)
                  : AppTheme.getBackgroundColor(context).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUploaded
                    ? AppTheme.primaryblue.withOpacity(0.3)
                    : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppTheme.primaryblue
                        : AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle : Icons.upload_file,
                    color: isUploaded ? AppTheme.whiteColor : AppTheme.getSecondaryTextColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentType,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUploaded) ...[
                        const SizedBox(height: 4),
                        Text(
                          fileName,
                          style:TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isUploaded)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _uploadedDocuments[documentType] = null;
                        _documentFilePaths[documentType] = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _handleDocumentUpload(documentType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      foregroundColor: AppTheme.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Upload'),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _handleDocumentUpload(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'], // Only allow supported formats
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Double-check file extension (extra validation)
        if (!['pdf', 'doc', 'docx'].contains(fileExtension)) {
          _showErrorSnackBar('Invalid file type. Please select a PDF, DOC, or DOCX file.');
          return;
        }
        
        // Check file size (10MB limit)
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);
        if (fileSize > 10 * 1024 * 1024) {
          _showErrorSnackBar('File too large. Maximum size is 10MB. Your file is ${fileSizeMB.toStringAsFixed(1)}MB.');
          return;
        }
        
        // Store the file path for later upload
        setState(() {
          _uploadedDocuments[documentType] = fileName;
          _documentFilePaths[documentType] = file.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.whiteColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$documentType selected successfully (${fileSizeMB.toStringAsFixed(1)}MB)',
                    style: const TextStyle(color: AppTheme.whiteColor),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 2000),
            backgroundColor: AppTheme.primaryblue,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to select file';
      
      // Handle specific file picker errors
      if (e.toString().contains('User canceled')) {
        return; // Don't show error for user cancellation
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Please allow file access.';
      } else if (e.toString().contains('No application found')) {
        errorMessage = 'No file manager app found. Please install one.';
      }
      
      _showErrorSnackBar('$errorMessage: ${e.toString()}');
    }
  }

  void _handleSubmitApplication() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDistrict == null) {
        _showErrorSnackBar('Please select a district');
        return;
      }
      if (_selectedSpecializations.isEmpty) {
        _showErrorSnackBar('Please select at least one specialization');
        return;
      }
      final uploadedCount = _uploadedDocuments.values.where((v) => v != null).length;
      if (uploadedCount < 2) {
        _showErrorSnackBar('Please upload at least 2 required documents.\n\nRequired documents:\n• Business Registration Certificate\n• Valid ID/Passport\n• Proof of Address\n• Tax Registration\n\nSupported formats: PDF, DOC, DOCX (max 10MB each)');
        return;
      }

      setState(() {
        _isSubmittingApplication = true;
      });

      try {
        // Step 1: Upload documents first
        final documentsToUpload = <String, String>{};
        _documentFilePaths.forEach((key, value) {
          if (value != null) {
            documentsToUpload[key] = value;
          }
        });

        if (documentsToUpload.isEmpty) {
          setState(() {
            _isSubmittingApplication = false;
          });
          _showErrorSnackBar('No documents selected for upload');
          return;
        }

        // print('📁 Documents to upload: ${documentsToUpload.keys.toList()}');
        for (var entry in documentsToUpload.entries) {
          // print('📄 ${entry.key}: ${entry.value}');
        }

        _showProgressSnackBar('Starting document upload...');
        
        final documentUploadResult = await LandlordService.uploadMultipleDocuments(
          documents: documentsToUpload,
          onDocumentStartUpload: (documentType, current, total) {
            final shortName = _shortenDocumentName(documentType);
            _showProgressSnackBar('Uploading $current/$total: $shortName...');
          },
          onDocumentUploaded: (documentType, success) {
            final shortName = _shortenDocumentName(documentType);
            if (success) {
              // print('✅ $documentType uploaded successfully');
              // Don't show individual success snackbars to avoid spam - show final summary instead
            } else {
              // print('❌ $documentType upload failed');
              _showWarningSnackBar('❌ Failed to upload: $shortName');
            }
          },
        );

        // Show final upload summary
        final uploadedCount = documentUploadResult['uploadedDocuments']?.length ?? 0;
        final totalCount = documentsToUpload.length;
        
        if (uploadedCount == totalCount) {
          _showSuccessSnackBar('🎉 All $totalCount documents uploaded successfully!');
        } else if (uploadedCount > 0) {
          _showWarningSnackBar('⚠️ Upload complete: $uploadedCount/$totalCount documents successful');
        } else {
          _showErrorSnackBar('❌ All document uploads failed');
        }

        if (!documentUploadResult['success']) {
          setState(() {
            _isSubmittingApplication = false;
          });
          
          // Show specific error message with retry information
          String errorMessage = documentUploadResult['message'] ?? 'Document upload failed';
          
          // If there are failed documents, show which ones failed with more specific guidance
          if (documentUploadResult['failedDocuments'] != null) {
            final failedDocs = documentUploadResult['failedDocuments'] as List<String>;
            final uploadedDocs = documentUploadResult['uploadedDocuments'] as List<String>? ?? [];
            
            if (uploadedDocs.isNotEmpty) {
              errorMessage = '✅ Successfully uploaded: ${uploadedDocs.join(', ')}\n\n❌ Failed to upload: ${failedDocs.join(', ')}\n\nYou can continue with the uploaded documents or retry uploading the failed ones. The most common causes are:\n• Network connection issues\n• File format (must be PDF, DOC, or DOCX)\n• File size (maximum 10MB)';
              
              // Allow user to proceed with partial uploads if at least 2 documents were uploaded
              if (uploadedDocs.length >= 2) {
                _showPartialUploadDialog(uploadedDocs, failedDocs);
                return;
              }
            } else {
              errorMessage = 'Failed to upload: ${failedDocs.join(', ')}\n\nPlease check:\n• Internet connection\n• File format (PDF, DOC, or DOCX only)\n• File size (maximum 10MB)\n• Try uploading smaller files or retry';
            }
          }
          
          _showErrorSnackBar(errorMessage);
          return;
        }

        // Step 2: Submit landlord application
        _proceedWithApplication();

      } catch (e) {
        setState(() {
          _isSubmittingApplication = false;
        });
        _showErrorSnackBar('An error occurred. Please try again.');
        // print('Application submission error: $e');
      }
    }
  }

  void _showPartialUploadDialog(List<String> uploadedDocs, List<String> failedDocs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Partial Upload Complete',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Successfully uploaded (${uploadedDocs.length}):',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...uploadedDocs.map((doc) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $doc',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 14,
                ),
              ),
            )),
            const SizedBox(height: 16),
            Text(
              '❌ Failed to upload (${failedDocs.length}):',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...failedDocs.map((doc) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $doc',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 14,
                ),
              ),
            )),
            const SizedBox(height: 16),
            Text(
              'You have uploaded ${uploadedDocs.length} documents successfully. You can proceed with your application or retry uploading the failed documents.',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Allow user to retry uploading failed documents
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryblue,
                    side: const BorderSide(color: AppTheme.primaryblue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Retry Failed'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Proceed with application submission
                    _proceedWithApplication();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryblue,
                    foregroundColor: AppTheme.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Proceed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _proceedWithApplication() async {
    setState(() {
      _isSubmittingApplication = true;
    });

    try {
      _showProgressSnackBar('Submitting application...');
      
      final fullAddress = '${_selectedDistrict ?? ''}, ${_selectedParish ?? ''}';
      
      final applicationResult = await LandlordService.submitLandlordApplication(
        businessName: _businessNameController.text.trim(),
        regNo: _registrationNumberController.text.trim(),
        district: fullAddress,
        parish: _selectedParish ?? '',
        propertySpecialization: _selectedSpecializations,
        about: _descriptionController.text.trim(),
      );

      setState(() {
        _isSubmittingApplication = false;
      });

      if (applicationResult['success']) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(applicationResult['message'] ?? 'Application submission failed');
      }

    } catch (e) {
      setState(() {
        _isSubmittingApplication = false;
      });
      _showErrorSnackBar('An error occurred. Please try again.');
      // print('Application submission error: $e');
    }
  }

  // Helper method to shorten document names for snackbar display
  String _shortenDocumentName(String documentType) {
    switch (documentType) {
      case 'Business Registration Certificate':
        return 'Business Registration';
      case 'Valid ID/Passport':
        return 'ID/Passport';
      case 'Proof of Address':
        return 'Proof of Address';
      case 'Tax Registration':
        return 'Tax Registration';
      default:
        return documentType.length > 20 
            ? '${documentType.substring(0, 20)}...' 
            : documentType;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.whiteColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message, 
                style: const TextStyle(color: AppTheme.whiteColor),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 6000), // Longer duration for detailed messages
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showProgressSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: AppTheme.whiteColor))),
          ],
        ),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200), // Shorter for progress updates
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.whiteColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: AppTheme.whiteColor))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 3000), // Longer for success to celebrate
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.whiteColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: AppTheme.whiteColor))),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 4000), // Longer for warnings so user can read
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryblue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Application Submitted!',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Your landlord application has been submitted successfully. You will receive a notification once it\'s reviewed by our team.\n\nYour account will be upgraded to LANDLORD status once approved, allowing you to list properties.\n\nExpected review time: 2-3 business days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                foregroundColor: AppTheme.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _physicalAddressController.dispose();
    _descriptionController.dispose();
    _zoneController.dispose();
    _villageController.dispose();
    super.dispose();
  }
}
