// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:pearlnest/apis/auth_service.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/blocs/profile_bloc/profile_bloc.dart';
import 'package:pearlnest/models/landlord.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/common/onboarding_screen.dart';
import 'package:pearlnest/screens/tenant/bookings_list_screen.dart';
import 'package:pearlnest/screens/tenant/tenant_booking_history_screen.dart';
import 'package:pearlnest/screens/tenant/contact_developer_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_application_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_booking_requests_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_dashboard_screen.dart';
import 'package:pearlnest/screens/landlord/landlord_property_management_screen.dart';
import 'package:pearlnest/screens/tenant/edit_profile_screen.dart';
import 'package:pearlnest/screens/tenant/help_and_support_screen.dart';
import 'package:pearlnest/screens/tenant/privacy_policy_screen.dart';
import 'package:pearlnest/screens/tenant/settings_screen.dart';
import 'package:pearlnest/utils/image_helper.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/error_widget.dart';
import 'package:pearlnest/widgets/loading_widget.dart';
import 'package:pearlnest/widgets/registration_status_card.dart';

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
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(FetchProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: AppTheme.primaryblue,
        elevation: 0,
        automaticallyImplyLeading: true,
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
              if (widget.user.userType == UserType.tenant)
                BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
                  if (state is ProfileLoadingState) {
                    return LoadingWidget(height: MediaQuery.of(context).size.height * 0.1);
                  } else if (state is ProfileLoadedState) {
                    List<Map<String, dynamic>> reg = List<Map<String, dynamic>>.from(state.data["LandLordRegistration"]);
                    if (reg.isNotEmpty) {
                      return ListView.builder(
                          itemCount: reg.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            RegistrationStatus status = RegistrationStatus.fromString((reg[index]["status"]).toString().toLowerCase());
                            String registrationId = reg[index]["id"].toString();
                            String dateSubmitted = reg[index]["createdAt"].toString();
                            return status == RegistrationStatus.rejected ? _buildBecomeLandlordCard() : RegistrationStatusCard(status: status, registrationId: registrationId, dateSubmitted: DateFormat("dd-MMM-yyyy").format(DateTime.parse(dateSubmitted)));
                          });
                    } else {
                      return _buildBecomeLandlordCard();
                    }
                  } else if (state is ProfileErrorState) {
                    return CustomErrorWidget(message: state.msg ?? "Sorry, failed to fetch profile.\nPlease try again later.");
                  } else {
                    return SizedBox();
                  }
                }),
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
      updatedAt: DateTime.now(),
      businessRegistrationNumber: '',
      verificationDocuments: [],
      applicationDate: DateTime.now().subtract(Duration(days: 30)),
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
              child: widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: ImageHelper.getFullImageUrl(widget.user.profileImage!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryblue),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryblue,
                        ),
                        cacheManager: DefaultCacheManager(),
                        fadeInDuration: Duration(milliseconds: 300),
                        fadeOutDuration: Duration(milliseconds: 300),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryblue,
                    ),
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
              colors: [AppTheme.primaryblue, AppTheme.primaryblue.withOpacity(0.8)],
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
                'Make your property easily discoverable by listing it on Pearlnest - reach a wider audience and attract potential tenants or buyers with our platform.',
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
        ],
        if (widget.user.userType == UserType.tenant || widget.user.userType == UserType.landlord)
          _buildMenuItem(
            Icons.calendar_today,
            'Bookings',
            () {
              if (widget.user.userType == UserType.landlord) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LandlordBookingRequestsScreen(
                      user: widget.user,
                    ),
                  ),
                );
              } else if (widget.user.userType == UserType.tenant) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingsListScreen(
                      user: widget.user,
                    ),
                  ),
                );
              } else {}
            },
          ),
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
            Navigator.push(
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
          Icons.delete_forever_outlined,
          'Delete Account',
          () {
            _showDeleteAccountDialog();
          },
          isDestructive: true,
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
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
    //debugPrint('🔍 ProfileScreen: Showing logout dialog');
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        //debugPrint('🔍 ProfileScreen: Building logout dialog');
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            //debugPrint('🔍 ProfileScreen: Dialog BlocListener received state: ${state.runtimeType}');
            if (state is AuthUnauthenticated) {
              //debugPrint('🔍 ProfileScreen: Logout completed, navigating to OnboardingScreen');
              // Close the dialog
              Navigator.of(context).pop();

              // Navigate to OnboardingScreen and clear the entire navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            //debugPrint('🔍 ProfileScreen: Dialog BlocBuilder received state: ${state.runtimeType}');
            final isLoading = state is AuthLoading;

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
                  onPressed: isLoading
                      ? null
                      : () {
                          //debugPrint('🔍 ProfileScreen: Cancel button pressed');
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          //debugPrint('🔍 ProfileScreen: Logout button pressed');
                          // Trigger logout - BlocListener will handle navigation
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    // Show initial warning dialog with important information
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Deleting your account will permanently remove:',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._buildDeletionPoints(),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'If you have any active bookings or pending transactions, please resolve them before deleting your account.',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to continue?',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteAccountConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDeletionPoints() {
    final points = [
      '• Your profile and personal information',
      '• All your property listings (if landlord)',
      '• Your booking history',
      '• Your favorite properties',
      '• All chat conversations',
      '• Your reviews and ratings',
    ];

    return points
        .map((point) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                point,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 14,
                ),
              ),
            ))
        .toList();
  }

  void _showDeleteAccountConfirmation() {
    final TextEditingController reasonController = TextEditingController();
    String? selectedReason;

    final reasons = [
      'I found a better alternative',
      'I no longer need this service',
      'Privacy concerns',
      'Too many notifications',
      'Account security issues',
      'Other (please specify)',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Final Confirmation',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help us improve by telling us why you\'re leaving (optional):',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGreyColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: reasons.map((reason) {
                          return RadioListTile<String>(
                            title: Text(
                              reason,
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: 14,
                              ),
                            ),
                            value: reason,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedReason = value;
                              });
                            },
                            activeColor: AppTheme.primaryblue,
                          );
                        }).toList(),
                      ),
                    ),
                    if (selectedReason == 'Other (please specify)') ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Please tell us more...',
                          hintStyle: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.lightGreyColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryblue),
                          ),
                          filled: true,
                          fillColor: AppTheme.lightGreyColor.withValues(alpha: 0.1),
                        ),
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This will permanently delete your account and all associated data.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 16,
                    ),
                  ),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final reason = selectedReason == 'Other (please specify)' ? reasonController.text.trim() : selectedReason;
                              _performAccountDeletion(reason);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                              ),
                            )
                          : Text(
                              'Delete Account',
                              style: TextStyle(
                                color: AppTheme.whiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performAccountDeletion(String? reason) async {
    try {
      // Call the delete account API
      final result = await AuthService.deleteAccount(
        userId: widget.user.id,
        reason: reason,
      );

      // Close the confirmation dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Show success message
        if (mounted) {
          _showAccountDeletedDialog();
        }

        // Trigger logout through AuthBloc to navigate to login screen
        if (mounted) {
          context.read<AuthBloc>().add(AuthLogoutRequested());
        }
      } else {
        // Show error message
        if (mounted) {
          _showDeletionErrorDialog(result['message'] ?? 'Failed to delete account');
        }
      }
    } catch (e) {
      // Close the confirmation dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        _showDeletionErrorDialog('An error occurred while deleting your account. Please try again.');
      }
    }
  }

  void _showAccountDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Account Deleted',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your account has been permanently deleted. Thank you for using PearlNest Estates.',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'You will now be redirected to the login screen.',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeletionErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Deletion Failed',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: AppTheme.primaryblue,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontSize: 16,
                ),
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
      case UserType.admin:
        return 'Admin';
    }
  }
}
