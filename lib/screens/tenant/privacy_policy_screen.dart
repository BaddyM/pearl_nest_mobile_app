// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.only(left: 8, top: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.whiteColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.whiteColor,
                size: 18,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrivacyPolicyTab(),
                _buildTermsAndConditionsTab(),
                _buildCancellationPolicyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryblue,
            AppTheme.primaryblue.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryblue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Legal Information',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Privacy, Terms & Policies',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.whiteColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.whiteColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppTheme.whiteColor.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.whiteColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(4),
              labelColor: AppTheme.primaryblue,
              unselectedLabelColor: AppTheme.whiteColor.withValues(alpha: 0.8),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Privacy Policy',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Terms & Conditions',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Cancellation Policy',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPrivacyPolicyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Privacy Policy'),
          // _buildLastUpdated('Last updated: December 2024'),
          SizedBox(height: 20),

          _buildSection(
            'Information We Collect',
            [
              'Personal Information: Name, email address, phone number, and profile picture',
              'Property Information: Property details, photos, location, and pricing',
              'Booking Information: Reservation details, payment information, and communication history',
              'Usage Data: App usage patterns, device information, and analytics data',
              'Location Data: GPS coordinates when you use location-based features',
            ],
          ),

          _buildSection(
            'How We Use Your Information',
            [
              'To provide and maintain our property rental services',
              'To process bookings and facilitate communication between hosts and guests',
              'To send you important updates about your bookings and account',
              'To improve our app and develop new features',
              'To prevent fraud and ensure platform security',
              'To comply with legal obligations and resolve disputes',
            ],
          ),

          _buildSection(
            'Information Sharing',
            [
              'With other users when you make or receive booking requests',
              'With payment processors to handle transactions securely',
              'With service providers who help us operate our platform',
              'When required by law or to protect our rights and safety',
              'In connection with a business transfer or acquisition',
            ],
          ),

          _buildSection(
            'Data Security',
            [
              'We use industry-standard encryption to protect your data',
              'Regular security audits and monitoring systems',
              'Secure data centers with restricted access',
              'Employee training on data protection best practices',
              'Incident response procedures for potential breaches',
            ],
          ),

          _buildSection(
            'Your Rights',
            [
              'Access and review your personal information',
              'Request corrections to inaccurate data',
              'Delete your account and associated data',
              'Export your data in a portable format',
              'Opt-out of marketing communications',
              'Restrict certain data processing activities',
            ],
          ),

          _buildSection(
            'Cookies and Tracking',
            [
              'Essential cookies for app functionality',
              'Analytics cookies to understand user behavior',
              'Preference cookies to remember your settings',
              'You can manage cookie preferences in your device settings',
            ],
          ),

          _buildSection(
            'Third-Party Services',
            [
              'Payment processing (Pesapal)',
              'Maps and location services (Google Maps)',
              'Analytics and crash reporting',
              'Customer support tools',
              'Marketing and communication platforms',
            ],
          ),

          _buildSection(
            'International Transfers',
            [
              'Your data may be processed in countries outside your residence',
              'We ensure adequate protection through legal safeguards',
              'Data transfers comply with applicable privacy laws',
            ],
          ),

          _buildSection(
            'Children\'s Privacy',
            [
              'Our service is not intended for users under 18 years old',
              'We do not knowingly collect data from children',
              'Parents can contact us to remove any child\'s information',
            ],
          ),

          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Terms and Conditions'),
          // _buildLastUpdated('Last updated: December 2024'),
          SizedBox(height: 20),

          _buildSection(
            'Acceptance of Terms',
            [
              'By using PearlNest, you agree to these terms and conditions',
              'These terms apply to all users, hosts, and guests',
              'We may update these terms from time to time',
              'Continued use constitutes acceptance of updated terms',
            ],
          ),

          _buildSection(
            'User Accounts',
            [
              'You must be at least 18 years old to create an account',
              'Provide accurate and complete information',
              'Maintain the security of your account credentials',
              'You are responsible for all activities under your account',
              'One person may not maintain multiple accounts',
            ],
          ),

          _buildSection(
            'Host Responsibilities',
            [
              'Provide accurate property descriptions and photos',
              'Maintain your property in good condition',
              'Respond to booking requests promptly',
              'Honor confirmed reservations',
              'Comply with local laws and regulations',
              'Maintain appropriate insurance coverage',
            ],
          ),

          _buildSection(
            'Guest Responsibilities',
            [
              'Treat properties with respect and care',
              'Follow house rules and property guidelines',
              'Pay all fees and charges on time',
              'Communicate honestly with hosts',
              'Report any issues or damages promptly',
              'Leave properties in clean condition',
            ],
          ),

          _buildSection(
            'Booking and Payments',
            [
              'All bookings are subject to host approval',
              'Payment is processed securely through our platform',
              'Fees and taxes are clearly displayed before booking',
              'Refunds are subject to the applicable cancellation policy',
              'We may charge additional fees for platform services',
            ],
          ),

          _buildSection(
            'Prohibited Activities',
            [
              'Fraudulent or deceptive practices',
              'Harassment or discrimination',
              'Violation of local laws or regulations',
              'Unauthorized commercial activities',
              'Spam or unsolicited communications',
              'Circumventing platform fees or policies',
            ],
          ),

          _buildSection(
            'Intellectual Property',
            [
              'PearlNest owns all platform content and trademarks',
              'Users retain rights to their own content',
              'By posting content, you grant us a license to use it',
              'Respect the intellectual property rights of others',
            ],
          ),

          _buildSection(
            'Limitation of Liability',
            [
              'PearlNest is a platform connecting hosts and guests',
              'We are not responsible for the condition of properties',
              'Users interact at their own risk',
              'Our liability is limited to the maximum extent allowed by law',
              'We do not guarantee the accuracy of user-generated content',
            ],
          ),

          _buildSection(
            'Dispute Resolution',
            [
              'We encourage users to resolve disputes directly',
              'Our support team can provide assistance',
              'Serious disputes may be subject to arbitration',
              'Legal action must be brought within one year',
            ],
          ),

          _buildSection(
            'Termination',
            [
              'Either party may terminate the agreement at any time',
              'We may suspend or terminate accounts for violations',
              'Termination does not affect existing booking obligations',
              'Some provisions survive termination of the agreement',
            ],
          ),

          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Cancellation Policy'),
          // _buildLastUpdated('Last updated: December 2024'),
          SizedBox(height: 20),

          _buildSection(
            'Overview',
            [
              'Cancellation policies protect both hosts and guests',
              'Each property may have different cancellation terms',
              'Policies are clearly displayed before booking',
              'Refund amounts depend on timing and policy type',
            ],
          ),

          _buildPolicyTypeSection(
            'Flexible Policy',
            'Full refund 1 day prior to arrival',
            [
              'Cancel up to 24 hours before check-in for a full refund',
              'Cancel within 24 hours: no refund for the first night',
              'Service fees are refunded when cancellation is made within 48 hours of booking',
              'If the guest cancels after check-in, nights not spent are not refunded',
            ],
            Colors.green,
          ),

          _buildPolicyTypeSection(
            'Moderate Policy',
            'Full refund 5 days prior to arrival',
            [
              'Cancel up to 5 days before check-in for a full refund',
              'Cancel within 5 days: 50% refund for nights not spent',
              'Cancel within 24 hours of check-in: no refund',
              'Service fees are refunded when cancellation is made within 48 hours of booking',
            ],
            Colors.orange,
          ),

          _buildPolicyTypeSection(
            'Strict Policy',
            '50% refund up until 1 week prior to arrival',
            [
              'Cancel up to 7 days before check-in for a 50% refund',
              'Cancel within 7 days of check-in: no refund',
              'No refund for early departure or unused nights',
              'Service fees are only refunded if cancellation is made within 48 hours of booking',
            ],
            Colors.red,
          ),

          _buildSection(
            'Host Cancellations',
            [
              'Hosts should not cancel confirmed reservations',
              'If a host cancels, guests receive a full refund',
              'Hosts may face penalties for frequent cancellations',
              'We will help find alternative accommodations when possible',
            ],
          ),

          _buildSection(
            'Extenuating Circumstances',
            [
              'Natural disasters and severe weather events',
              'Government travel restrictions or advisories',
              'Serious illness or injury (with documentation)',
              'Death in the immediate family',
              'Military deployment or emergency service calls',
              'Documentation may be required for refund consideration',
            ],
          ),

          _buildSection(
            'How to Cancel',
            [
              'Log into your PearlNest account',
              'Go to "My Trips" or "My Bookings"',
              'Select the reservation you want to cancel',
              'Click "Cancel Reservation" and follow the prompts',
              'You will receive a confirmation email',
              'Refunds are processed within 5-10 business days',
            ],
          ),

          _buildSection(
            'Refund Processing',
            [
              'Refunds are issued to the original payment method',
              'Processing time varies by payment provider',
              'Credit cards: 5-10 business days',
              'PayPal: 1-3 business days',
              'Bank transfers: 3-7 business days',
              'You will receive email confirmation when refund is processed',
            ],
          ),

          _buildSection(
            'Modification vs. Cancellation',
            [
              'Consider modifying your reservation instead of cancelling',
              'Date changes may be possible with host approval',
              'Modifications may incur additional fees',
              'Contact the host directly to discuss options',
              'Our support team can assist with modifications',
            ],
          ),

          _buildSection(
            'Travel Insurance',
            [
              'Consider purchasing travel insurance for additional protection',
              'Insurance may cover cancellations due to covered reasons',
              'Review insurance terms carefully before purchasing',
              'PearlNest does not provide travel insurance directly',
            ],
          ),

          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryblue,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Widget _buildLastUpdated(String date) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: AppTheme.primaryblue.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: AppTheme.primaryblue.withOpacity(0.3)),
  //     ),
  //     child: Text(
  //       date,
  //       style: TextStyle(
  //         fontSize: 14,
  //         fontStyle: FontStyle.italic,
  //         color: AppTheme.primaryblue,
  //         fontWeight: FontWeight.w500,
  //       ),
  //       textAlign: TextAlign.center,
  //     ),
  //   );
  // }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
              height: 1.3,
            ),
          ),
          SizedBox(height: 12),
          ...items.map((item) => Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryblue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.getTextColor(context),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPolicyTypeSection(String title, String subtitle, List<String> items, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whiteColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12),
          ...items.map((item) => Container(
                margin: EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 40),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryblue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support_outlined,
                color: AppTheme.primaryblue,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryblue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'If you have any questions about this policy or our practices, please contact us:',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.getTextColor(context),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          _buildContactItem(Icons.email_outlined, 'Email', 'pearlnestestates@gmail.com'),
          _buildContactItem(Icons.phone_outlined, 'Phone', '+256791597476'),
          _buildContactItem(Icons.location_on_outlined, 'Address', 'Kampala Uganda'),
          _buildContactItem(Icons.access_time_outlined, 'Support Hours', 'Monday - Friday: 9:00 AM - 5:00 PM PST\nWeekends: 10:00 AM - 4:00 PM PST'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryblue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
