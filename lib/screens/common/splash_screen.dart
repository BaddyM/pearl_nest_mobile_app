// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/models/user.dart';
import 'package:pearlnest/models/user_type.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_event.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/screens/common/onboarding_screen.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;

  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeInOut,
    ));

    _subtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();

    // Check first launch status and handle navigation
    _handleAppInitialization();
  }

  Future<void> _handleAppInitialization() async {
    debugPrint('🚀 Checking app initialization status...');

    // Wait for animations to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _isDisposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      debugPrint('🏠 First launch: $isFirstLaunch');

      if (isFirstLaunch) {
        debugPrint('🎯 First time user - navigating to onboarding');
        if (mounted && !_isDisposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      } else {
        debugPrint('🔄 Returning user - checking auth status');
        // Trigger auth check for returning users
        context.read<AuthBloc>().add(AuthCheckSessionRequested());
      }
    } catch (e) {
      debugPrint('❌ Error checking first launch: $e');
      // Fallback to auth check if SharedPreferences fails
      if (mounted && !_isDisposed) {
        context.read<AuthBloc>().add(AuthCheckSessionRequested());
      }
    }
  }

  void _startAnimations() async {
    if (!mounted || _isDisposed) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _isDisposed) return;
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _isDisposed) return;
    _subtitleController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        debugPrint('💫 SplashScreen received auth state: ${state.runtimeType}');
        if (state is AuthUnauthenticated || state is AuthFailure) {
          debugPrint('🔐 Auth failed - navigating to login');
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
        // AuthSuccess is handled by main.dart's BlocListener
      },
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Opacity(
                      opacity: _logoAnimation.value.clamp(0.0, 1.0),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 300,
                        height: 300,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _titleAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                    child: Opacity(
                      opacity: _titleAnimation.value.clamp(0.0, 1.0),
                      child: Text(
                        'PearlNest Estates',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.getTextColor(context),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _subtitleAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _subtitleAnimation.value)),
                    child: Opacity(
                      opacity: _subtitleAnimation.value.clamp(0.0, 1.0),
                      child: Text(
                        'Find Your Dream Property',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
