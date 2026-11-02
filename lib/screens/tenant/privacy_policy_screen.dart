// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:pearlnest/apis/chat_service.dart';
import 'package:pearlnest/models/admin.dart';
import 'package:pearlnest/apis/policy_service.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final int initialTabIndex;

  const PrivacyPolicyScreen({super.key, this.initialTabIndex = 0});

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _privacyPolicy;
  String? _termsAndConditions;
  List<RefundTier> _refundTiers = const [];
  String? _policyLoadError;
  bool _isLoadingPolicies = true;
  Admin? _supportAdmin;
  bool _isLoadingSupportContact = true;
  String? _supportContactError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadPolicies();
    _loadSupportContact();
  }

  Future<void> _loadSupportContact() async {
    try {
      final admin = await ChatService.fetchSupportAdmin();
      if (!mounted) return;
      setState(() {
        _supportAdmin = admin;
        _supportContactError = admin == null
            ? 'Support contact details are not available right now.'
            : null;
        _isLoadingSupportContact = false;
      });
    } catch (error) {
      debugPrint('Could not load policy support contacts: $error');
      if (!mounted) return;
      setState(() {
        _supportContactError = 'Support contact details could not be loaded.';
        _isLoadingSupportContact = false;
      });
    }
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoadingPolicies = true;
      _policyLoadError = null;
    });
    try {
      final policies = await PolicyService.fetchPolicies();
      if (!mounted) return;
      setState(() {
        _privacyPolicy = policies.privacyPolicy;
        _termsAndConditions = policies.termsAndConditions;
        _refundTiers = policies.refundTiers;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _policyLoadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingPolicies = false);
    }
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
          if (_policyLoadError != null) _buildPolicyLoadError(),
          if (_isLoadingPolicies) const LinearProgressIndicator(minHeight: 2),
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

  Widget _buildPolicyLoadError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryblue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Current policies could not be loaded. The built-in policy text is shown instead.',
                ),
              ),
              TextButton(
                onPressed: _isLoadingPolicies ? null : _loadPolicies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
    if (_privacyPolicy != null) {
      return _buildLivePolicyContent('Privacy Policy', _privacyPolicy!);
    }
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
            'On-device chat storage',
            [
              'The app stores a limited local copy of your conversation list and recent messages so chats can open quickly while the network refreshes. The cache is limited to 200 messages per conversation and kept for up to 30 days.',
              'The local cache is not currently encrypted. It is removed when you log out; messages may also remain on PearlNest servers under this policy.',
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
    if (_termsAndConditions != null) {
      return _buildLivePolicyContent(
        'Terms and Conditions',
        _termsAndConditions!,
      );
    }
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
              'Tenants can cancel pending or approved bookings from My Bookings',
              'Cancelling a booking does not automatically refund completed payments; submit a separate refund request under the applicable policy',
              'We may charge additional fees for platform services',
            ],
          ),

          _buildSection(
            'Booking changes and travel insurance',
            [
              'Tenants can request new booking dates from an approved accommodation booking. The landlord must review the request and the tenant must accept the updated quote.',
              "The existing booking remains unchanged unless the tenant accepts the landlord's offer. Any additional balance is payable separately; a reduction may require a separate refund request under the applicable policy.",
              'A chat message about changing dates is not itself an approved change. If the in-app request is unavailable, contact PearlNest Support.',
              'PearlNest does not provide or arrange travel insurance',
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
              'Tenants can cancel pending and approved bookings from My Bookings',
              'Refund eligibility and amounts follow the current refund terms shown in the app',
              'Review the applicable refund terms before confirming a cancellation',
            ],
          ),

          if (_refundTiers.isNotEmpty)
            _buildRefundTiersSection()
          else
            _buildUnavailableRefundNotice(),

          _buildSection(
            'Host Cancellations',
            [
              'Hosts should not cancel confirmed reservations',
              'If a host cancels or rejects a booking, contact PearlNest Support to review available options and any applicable refund',
              'Any refund depends on the booking status and the current refund terms',
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
              'Open My Bookings and select an active booking',
              'Choose Cancel booking and confirm the cancellation',
              'The app currently allows cancellation of pending and approved bookings',
              'You will receive a confirmation email when the cancellation succeeds',
              'A completed payment is not refunded automatically; use Request a refund on the cancelled booking in booking history',
            ],
          ),

          _buildSection(
            'Refund Processing',
            [
              'Cancellation and refund are separate actions',
              'Submit a refund request from the booking history when the booking has completed payments',
              'The amount and eligibility follow the current refund terms shown in the app',
              'Processing time depends on review and the payment provider; contact PearlNest Support for a status update',
            ],
          ),

          _buildSection(
            'Modification vs. Cancellation',
            [
              'For an approved accommodation booking, submit a date-change request from My Bookings',
              'The landlord reviews the requested dates and returns a quote; the existing booking stays unchanged until you accept that offer',
              'Any additional balance must be paid separately. If the revised total is lower than the amount already paid, submit a separate refund request under the applicable refund policy',
              'If the in-app change request is unavailable, contact PearlNest Support. A chat message alone does not change a booking',
            ],
          ),

          _buildSection(
            'Travel Insurance',
            [
              'PearlNest does not provide, sell, or arrange travel insurance',
              'If you want cover, contact an insurer or licensed insurance adviser directly',
              'Cover, exclusions, cancellation rights, and claims are determined by the insurer, not PearlNest',
            ],
          ),

          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildLivePolicyContent(String title, String content) {
    final readableContent = content
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 12),
          SelectableText(
            readableContent,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.getTextColor(context),
            ),
          ),
          if (title == 'Privacy Policy')
            _buildSection(
              'On-device chat storage',
              [
                'The app stores a limited local copy of your conversation list and recent messages so chats can open quickly while the network refreshes. The cache is limited to 200 messages per conversation and kept for up to 30 days.',
                'The local cache is not currently encrypted. It is removed when you log out; messages may also remain on PearlNest servers under this policy.',
              ],
            ),
          if (title == 'Terms and Conditions')
            _buildSection(
              'Current booking features',
              [
                'Tenants can cancel pending or approved bookings from My Bookings; cancelling does not automatically refund completed payments.',
                'Tenants can request new dates for approved accommodation bookings. The landlord reviews the request, then the tenant must accept the updated quote; the current booking stays unchanged until acceptance.',
                'An increased total leaves an additional balance payable separately. A reduced total may be eligible for a separate refund request under the current refund terms.',
                'A chat message is not an approved booking change; use the in-app change request or contact support if unavailable.',
                'PearlNest does not provide or arrange travel insurance.',
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRefundTiersSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryblue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryblue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refunds by booking status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Refund percentages are based on the booking status.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ..._refundTiers.map((tier) {
            final status = tier.bookingStatus
                .replaceAll('_', ' ')
                .replaceAll('-', ' ')
                .split(RegExp(r'\s+'))
                .map((word) => word.isEmpty
                    ? word
                    : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
                .join(' ');
            final percentage = tier.refundPercent % 1 == 0
                ? tier.refundPercent.toStringAsFixed(0)
                : tier.refundPercent.toString();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  Text(
                    '$percentage% refund',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryblue,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnavailableRefundNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Current refund terms are unavailable right now. Please try again later or check with PearlNest Support before cancelling.',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppTheme.getTextColor(context),
        ),
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
          if (_isLoadingSupportContact)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (_supportContactError != null)
            Row(
              children: [
                Expanded(child: Text(_supportContactError!)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoadingSupportContact = true;
                      _supportContactError = null;
                    });
                    _loadSupportContact();
                  },
                  child: const Text('Retry'),
                ),
              ],
            )
          else ...[
            if (_supportAdmin!.email.trim().isNotEmpty)
              _buildContactItem(Icons.email_outlined, 'Email', _supportAdmin!.email.trim()),
            if (_supportAdmin!.contact.trim().isNotEmpty)
              _buildContactItem(Icons.phone_outlined, 'Phone', _supportAdmin!.contact.trim()),
          ],
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
