// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Find Your Perfect Property',
      description: 'Discover thousands of premium properties tailored to your lifestyle and budget preferences',
      image: 'assets/images/icon_3.png',
    ),
    OnboardingItem(
      title: 'Easy Booking Process',
      description: 'Schedule property viewings and secure your dream home with our streamlined booking system',
      image: 'assets/images/icon_2.png',
    ),
    OnboardingItem(
      title: 'Connect with Landlords',
      description: 'Chat directly with property owners and get instant responses to all your questions',
      image: 'assets/images/icon_4.png',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentPage == _items.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      //debugPrint('✅ Completing onboarding - marking first launch as complete');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', false);

      if (mounted) {
        debugPrint('🔐 Navigating to home screen');
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const LoginScreen()),
        // );

        final User user = User(
          id: "",
          name: "",
          email: "",
          phone: "",
          userType: UserType.tenant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: user,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const LoginScreen()),
        // );

        final User user = User(
          id: "",
          name: "",
          email: "",
          phone: "",
          userType: UserType.tenant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: user,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final horizontalPadding = screenSize.width * 0.06;
    final bottomPadding = isSmallScreen ? 16.0 : 32.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppTheme.primaryblue),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        item: _items[index],
                        screenSize: screenSize,
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: isSmallScreen ? 6 : 8,
                            width: _currentPage == index ? (isSmallScreen ? 24 : 32) : (isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 32),
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E5631),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _items.length - 1 ? 'Get Started' : 'Continue',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _items.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class OnboardingItem {
  final String title;
  final String description;
  final String image;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final Size screenSize;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;
    final horizontalPadding = screenSize.width * 0.08;

    final imageHeight = isVerySmallScreen
        ? screenSize.height * 0.25
        : isSmallScreen
            ? screenSize.height * 0.3
            : screenSize.height * 0.35;

    final titleFontSize = isVerySmallScreen
        ? 24.0
        : isSmallScreen
            ? 28.0
            : 32.0;
    final descriptionFontSize = isVerySmallScreen
        ? 14.0
        : isSmallScreen
            ? 16.0
            : 18.0;

    final spacingAfterImage = isVerySmallScreen
        ? 24.0
        : isSmallScreen
            ? 32.0
            : 48.0;
    final spacingAfterTitle = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 16.0
            : 20.0;
    final spacingAfterDescription = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 30.0
            : 40.0;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenSize.height * 0.05),
            Container(
              height: imageHeight,
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: 320,
                minHeight: isVerySmallScreen ? 150 : 200,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isSmallScreen ? 15 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
                child: Image.asset(
                  item.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: spacingAfterImage),
            Text(
              item.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacingAfterTitle),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: descriptionFontSize,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: spacingAfterDescription),
            Container(
              width: isSmallScreen ? 40 : 60,
              height: isSmallScreen ? 3 : 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: screenSize.height * 0.05),
          ],
        ),
      ),
    );
  }
}
