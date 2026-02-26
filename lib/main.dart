import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pearlnest/blocs/profile_bloc/profile_bloc.dart';
import 'package:pearlnest/services/profile_service.dart';
import 'firebase_options.dart'; // Add this import
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/widgets/theme_provider.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/blocs/property/property_bloc.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/blocs/chat/chat_bloc.dart';
import 'package:pearlnest/screens/common/splash_screen.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:pearlnest/widgets/permission_initialization_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pearlnest/apis/booking_service.dart';
import 'package:pearlnest/services/deep_link_service.dart';
import 'package:pearlnest/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  await NotificationService.initialize();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    //debugPrint('Warning: Could not load .env file: $e');
    // Continue without .env file - app should still work with default values
  }

  // Initialize API client
  await ApiClient.initialize();

  // Initialize deep link service
  DeepLinkService.initialize();

  //Initialize Shared preferences
  ProfileService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Add a global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<PropertyBloc>(
          create: (context) => PropertyBloc(),
        ),
        BlocProvider<PropertyUploadBloc>(
          create: (context) => PropertyUploadBloc(),
        ),
        BlocProvider<BookingBloc>(
          create: (context) => BookingBloc(bookingService: BookingService()),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                //debugPrint('🔄 BlocListener received state: ${state.runtimeType}');

                if (state is AuthSuccess) {
                  //debugPrint('🏠 Navigating to HomeScreen for user: ${state.user.name}');
                  // Use navigatorKey to access navigator
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(user: state.user),
                      ),
                      (route) => false,
                    );
                  });
                }
              },
              child: MaterialApp(
                title: 'PearlNest Estates',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                debugShowCheckedModeBanner: false,
                navigatorKey: navigatorKey, // Add the navigator key
                home: PermissionInitializationWidget(
                  child: _getInitialScreen(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getInitialScreen() {
    // Always start with SplashScreen - let each screen handle its own state management
    //debugPrint('🏠 Starting with SplashScreen - screens will handle their own navigation');
    return const SplashScreen();
  }
}
