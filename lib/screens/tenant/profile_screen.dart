// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/mock_booking_data.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/tenant/contact_developer_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_application_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_booking_requests_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_dashboard_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_property_management_screen.dart';
import 'package:pearlnest/screens/tenant/edit_profile_screen.dart';
import 'package:pearlnest/screens/tenant/help_and_support_screen.dart';
import 'package:pearlnest/screens/tenant/privacy_policy_screen.dart';
import 'package:pearlnest/screens/tenant/settings_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Landlord? landlord;

  const ProfileScreen({
    super.key, 
    required this.user,
    this.landlord,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildProfileInfo(),
              if (widget.user.userType == UserType.tenant) _buildBecomeLandlordCard(),
              _buildMenuItems(),
            ],
          ),
        ),
      ),
    );
  }

  Landlord _createDummyLandlord() {
    return Landlord(
      id: widget.user.id,
      userId: widget.user.id,
      businessName: '${widget.user.name} Properties',
      businessDescription: 'Professional property management services',
      businessAddress: '123 Business St, City',
      businessPhone: widget.user.phone,
      businessEmail: widget.user.email,
      licenseNumber: 'LIC123456789',
      taxId: 'TAX987654321',
      bankAccountNumber: '1234567890',
      bankName: 'Demo Bank',
      rating: 4.5,
      totalProperties: 2,
      totalBookings: 15,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(), businessRegistrationNumber: '', verificationDocuments: [], applicationDate: DateTime.now().subtract(Duration(days: 30)),
    );
  }

  Widget _buildProfileHeader() {
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.whiteColor, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.getCardColor(context),
              backgroundImage: widget.user.profileImage != null
                  ? NetworkImage(widget.user.profileImage!)
                  : null,
              child: widget.user.profileImage == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryblue,
                    )
                  : null,
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.user.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteColor,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.whiteColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getUserTypeString(widget.user.userType),
              style: TextStyle(
                color: AppTheme.whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.user.isVerified) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  color: AppTheme.getTextColor(context),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Verified Account',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(Icons.email, 'Email', widget.user.email),
          SizedBox(height: 16),
          _buildInfoRow(Icons.phone, 'Phone', widget.user.phone),
          SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today,
            'Member Since',
            '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
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
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBecomeLandlordCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryblue,
                AppTheme.primaryblue.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppTheme.whiteColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Become a Landlord',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Start earning by listing your properties on PearlNest. Join thousands of successful landlords and grow your business.',
                style: TextStyle(
                  color: AppTheme.getTextColor(context).withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LandlordApplicationScreen(user: widget.user),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getBackgroundColor(context),
                        foregroundColor: AppTheme.primaryblue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      _showLandlordInfoDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.whiteColor,
                      side: BorderSide(color: AppTheme.whiteColor),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Learn More'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
      if (widget.user.userType == UserType.landlord) ...[
        _buildMenuItem(
          Icons.dashboard,
          'Landlord Dashboard',
          () {
            final landlord = widget.landlord ?? _createDummyLandlord();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LandlordDashboardScreen(
                  user: widget.user,
                  landlord: landlord,
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.home_work,
          'My Properties',
          () {
            final landlord = widget.landlord ?? _createDummyLandlord();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LandlordPropertyManagementScreen(
                  user: widget.user,
                  landlord: landlord,
                  properties: [],
                ),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.calendar_today,
          'Bookings',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LandlordBookingRequestsScreen(
                  user: widget.user,
                  bookings: MockBookingData.generateMockBookings(),
                ),
              ),
            );
          },
        ),
      ],
        _buildMenuItem(
          Icons.settings,
          'Settings',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(user: widget.user),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.help_outline,
          'Help & Support',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HelpSupportScreen(user: widget.user),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.code,
          "Contact Developer",
          () {
            Navigator.push (
              context,
              MaterialPageRoute(
                builder: (context) => ContactDeveloperScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivacyPolicyScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          Icons.logout,
          'Logout',
          () {
            _showLogoutDialog();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryblue,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : AppTheme.getTextColor(context),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.getSecondaryTextColor(context),
      ),
      onTap: onTap,
    );
  }

  void _showLandlordInfoDialog() {
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
              Icon(Icons.business, color: AppTheme.primaryblue),
              SizedBox(width: 8),
              Text(
                'Landlord Benefits',
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'As a PearlNest landlord, you get:',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              _buildBenefitItem('📈', 'Increased property visibility'),
              _buildBenefitItem('💰', 'Competitive commission rates'),
              _buildBenefitItem('🛡️', 'Verified tenant screening'),
              _buildBenefitItem('📱', 'Easy property management tools'),
              _buildBenefitItem('💬', 'Direct communication with tenants'),
              _buildBenefitItem('📊', 'Analytics and insights'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LandlordApplicationScreen(user: widget.user),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                foregroundColor: AppTheme.whiteColor,
              ),
              child: Text('Apply Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          title: Text(
            'Logout',
            style: TextStyle(color: AppTheme.getTextColor(context)),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.tenant:
        return 'Tenant';
      case UserType.landlord:
        return 'Landlord';
    }
  }
}
