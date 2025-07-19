import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
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
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    // Continue without .env file - app should still work with default values
  }
  
  // Initialize API client
  await ApiClient.initialize();
  
  // Initialize deep link service
  DeepLinkService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                debugPrint('🔄 BlocBuilder called with state: ${state.runtimeType}');
                return MaterialApp(
                  title: 'PearlNest Estates',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  debugShowCheckedModeBanner: false,
                  home: PermissionInitializationWidget(child:_buildHome(state)),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState state) {
    debugPrint('Building home with auth state: ${state.runtimeType}');
    debugPrint('Auth state details: $state');
    
    Widget homeWidget;
    
    switch (state) {
      case AuthInitial _:
         debugPrint('Showing splash screen - AuthInitial');
         homeWidget = const SplashScreen();
         break;
      case AuthInitializing _:
        debugPrint('Showing splash screen - AuthInitializing');
        homeWidget = const SplashScreen();
        break;
      case AuthLoading _:
        debugPrint(' - AuthLoading');
        homeWidget = const SplashScreen();
        break;
      case AuthSuccess successState:
        debugPrint('Showing home screen for user: ${successState.user.name}');
        debugPrint('🏠 Creating HomeScreen widget for user: ${successState.user.name}');
        homeWidget = HomeScreen(user: successState.user);
        debugPrint('🏠 HomeScreen widget created successfully');
        break;
      case AuthUnauthenticated _:
        debugPrint('Showing onboarding screen - AuthUnauthenticated');
        homeWidget = const SplashScreen();
        break;
      case AuthOtpRequired _:
        debugPrint('Showing splash screen - AuthOtpRequired (handled by login screen)');
        homeWidget = const SplashScreen();
        break;
      case AuthFailure _:
        debugPrint('Showing splash screen - AuthFailure');
        homeWidget = const SplashScreen();
        break;
      default:
         debugPrint('Showing splash screen - default case');
        homeWidget = const SplashScreen();
        break;
    }
    debugPrint('🏠 Returning widget: ${homeWidget.runtimeType}');
    return homeWidget;
  }
}
