// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/models/user.dart';

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

  bool _isLoading = false;

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
      backgroundColor: AppTheme.whiteColor,
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
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
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
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
                          onPressed: _isLoading ? null : _handleSubmitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
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
        color: AppTheme.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.1),
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
                  color: AppTheme.blackColor,
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
      style: const TextStyle(color: AppTheme.blackColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.greyColor),
        hintStyle: TextStyle(color: AppTheme.greyColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        filled: true,
        fillColor: AppTheme.lightGreyColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
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
        labelStyle: const TextStyle(color: AppTheme.greyColor),
        prefixIcon: Icon(icon, color: AppTheme.primaryblue),
        filled: true,
        fillColor: AppTheme.lightGreyColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
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
      style: const TextStyle(color: AppTheme.blackColor),
      dropdownColor: AppTheme.whiteColor,
    );
  }

  Widget _buildSpecializationsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your property specializations:',
          style: TextStyle(
            color: AppTheme.blackColor,
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
                      : AppTheme.lightGreyColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryblue
                        : AppTheme.greyColor.withOpacity(0.3),
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
                        color: isSelected ? AppTheme.whiteColor : AppTheme.blackColor,
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
                child: const Text(
                  'Upload each document separately for faster verification',
                  style: TextStyle(
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w500,
                  ),
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
                  : AppTheme.lightGreyColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUploaded
                    ? AppTheme.primaryblue.withOpacity(0.3)
                    : AppTheme.greyColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppTheme.primaryblue
                        : AppTheme.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle : Icons.upload_file,
                    color: isUploaded ? AppTheme.whiteColor : AppTheme.greyColor,
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
                        style: const TextStyle(
                          color: AppTheme.blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUploaded) ...[
                        const SizedBox(height: 4),
                        Text(
                          fileName,
                          style: const TextStyle(
                            color: AppTheme.greyColor,
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

  void _handleDocumentUpload(String documentType) {
    setState(() {
      _uploadedDocuments[documentType] =
          '${documentType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.whiteColor),
            const SizedBox(width: 12),
            Text('$documentType uploaded successfully', style: TextStyle(color: AppTheme.lightGreyColor),),
          ],
        ),
        duration: Duration(milliseconds: 500),
        backgroundColor: AppTheme.primaryblue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
        _showErrorSnackBar('Please upload at least 2 required documents');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.whiteColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 500),
        margin: EdgeInsets.all(16),
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
        backgroundColor: AppTheme.whiteColor,
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
            const Text(
              'Application Submitted!',
              style: TextStyle(
                color: AppTheme.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your landlord application has been submitted successfully. You will receive a notification once it\'s reviewed.\n\nExpected review time: 2-3 business days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.greyColor,
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
