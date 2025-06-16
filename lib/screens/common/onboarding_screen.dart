// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryblue
            ),
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
                      return OnboardingPage(item: _items[index]);
                    },
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E5631),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _items.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _items.length - 1
                                    ? Icons.rocket_launch
                                    : Icons.arrow_forward,
                                size: 20,
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

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                item.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
