// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/models/admin.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/screens/chat/admin_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  final User user;

  const HelpSupportScreen({
    super.key,
    required this.user,
  });

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  Admin? _supportAdmin;
  bool _contactLoading = true;
  String? _contactError;

  final List<String> _categories = [
    'General',
    'Account Issues',
    'Property Listing',
    'Booking Problems',
    'Payment Issues',
    'Technical Support',
    'Report a Bug',
    'Feature Request',
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportContact();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportContact() async {
    try {
      final supportAdmin = await ChatService.fetchSupportAdmin();
      if (!mounted) return;
      setState(() {
        _supportAdmin = supportAdmin;
        _contactError = supportAdmin == null
            ? 'Support contact details are not available right now.'
            : null;
        _contactLoading = false;
      });
    } catch (error) {
      debugPrint('Could not load support contact details: $error');
      if (!mounted) return;
      setState(() {
        _contactError = 'Support contact details could not be loaded.';
        _contactLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: AppTheme.whiteColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildQuickActions(),
              _buildFAQSection(),
              _buildContactForm(),
              _buildContactInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 60,
            color: AppTheme.whiteColor,
          ),
          SizedBox(height: 16),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We\'re here to assist you 24/7',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  Icons.chat,
                  'Live Chat',
                  'Chat with our support team',
                  () => _startLiveChat(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  Icons.call,
                  'Call Us',
                  'Speak directly with support',
                  () => _makePhoneCall(),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  Icons.email,
                  'Email',
                  'Send us an email',
                  () => _sendEmail(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  Icons.language,
                  'Our Website',
                  'Visit our Website',
                  () => _openWebsite(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryblue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryblue,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          _buildFAQItem(
            'How do I list my property?',
            'Go to your profile, apply to become a landlord, and once approved, you can add properties through the property management section.',
          ),
          _buildFAQItem(
            'How do I book a property?',
            'Choose your dates and send a booking request. No payment is due while it is waiting for landlord approval. If approved, complete checkout from My Bookings to confirm the reservation.',
          ),
          _buildFAQItem(
            'What payment methods are accepted?',
            'Available payment methods are shown during checkout after a booking request is approved.',
          ),
          _buildFAQItem(
            'How do I cancel a booking?',
            'You can cancel a booking through your bookings section. Cancellation policies vary by property and timing.',
          ),
          _buildFAQItem(
            'What documents are needed to become a landloard?',
            'Property proof documents or Images, A valid government ID or Passport',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextColor(context),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send us a message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getSecondaryTextColor(context).withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
                    border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppTheme.getCardColor(context),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: AppTheme.getTextColor(context)),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Describe your issue or question...',
                    hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryblue),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryblue,
                      foregroundColor: AppTheme.whiteColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                          )
                        : Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          if (_contactLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_contactError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _contactError!,
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _contactLoading = true;
                        _contactError = null;
                      });
                      _loadSupportContact();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
            if (_supportAdmin!.contact.trim().isNotEmpty)
              _buildContactInfoItem(
                Icons.phone,
                'Phone Support',
                _supportAdmin!.contact.trim(),
                'Support contact from the PearlNest team',
              ),
            if (_supportAdmin!.email.trim().isNotEmpty)
              _buildContactInfoItem(
                Icons.email,
                'Email Support',
                _supportAdmin!.email.trim(),
                'Email the PearlNest support team',
              ),
          ],
          _buildContactInfoItem(
            Icons.access_time,
            'Business Hours',
            'Monday - Friday: 9:00 AM - 6:00 PM',
            'Weekend: 10:00 AM - 4:00 PM',
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoItem(
    IconData icon,
    String title,
    String info,
    String subtitle,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryblue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryblue,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryblue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    // Navigate to admin list screen for live chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminListScreen(
          user: widget.user,
          propertyTitle: 'Help & Support',
          randomAdminOnly: true,
        ),
      ),
    );
  }

  void _makePhoneCall() async {
    final phone = _supportAdmin?.contact.trim() ?? '';
    if (phone.isEmpty) {
      _showErrorDialog('Support phone number is not available right now.');
      return;
    }
    final phoneNumber = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneNumber)) {
        await launchUrl(phoneNumber);
      } else {
        _showErrorDialog('Could not launch phone dialer');
      }
    } catch (e, stackTrace) {
      //debugPrint('Phone call error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _showErrorDialog('Error making phone call: $e');
    }
  }

  void _sendEmail() async {
    final email = _supportAdmin?.email.trim() ?? '';
    if (email.isEmpty) {
      _showErrorDialog('Support email address is not available right now.');
      return;
    }
    final emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request from ${widget.user.name}',
        'body': 'Hello PearlNest Support Team,\n\n',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        await Clipboard.setData(ClipboardData(text: email));
        _showSuccessDialog('Email address copied to clipboard');
      }
    } catch (e, stackTrace) {
      //debugPrint('Email launch error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _showErrorDialog('Error opening email client: $e');
    }
  }

  void _openWebsite() async {
    const websiteUrl = 'https://www.pearlnestestates.com/';
    try {
      final Uri url = Uri.parse(websiteUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Could not launch website');
      }
    } catch (e, stackTrace) {
      //debugPrint('Website launch error: $e');
      //debugPrint('Stack trace: $stackTrace');
      _showErrorDialog('Error opening website: $e');
    }
  }

  void _submitMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a message');
      return;
    }

    final subject = Uri.encodeComponent("Support Request - $_selectedCategory");
    final body = Uri.encodeComponent(_messageController.text.trim());
    final email = _supportAdmin?.email.trim() ?? '';
    if (email.isEmpty) {
      _showErrorDialog('Support email address is not available right now.');
      return;
    }

    final uri = Uri.parse("mailto:$email?subject=$subject&body=$body");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorDialog('Could not open email client.');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Success',
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppTheme.primaryblue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
