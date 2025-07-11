import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/widgets/theme_provider.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/blocs/property/property_bloc.dart';
import 'package:pearlnest/blocs/property_upload/property_upload_bloc.dart';
import 'package:pearlnest/blocs/booking/booking_bloc.dart';
import 'package:pearlnest/screens/common/splash_screen.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pearlnest/apis/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    // Continue without .env file - app should still work with default values
  }
  
  // Initialize API client
  await ApiClient.initialize();
  
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
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'PearlNest Estates',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return _buildHome(state);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState state) {
    debugPrint('Building home with auth state: ${state.runtimeType}');
    
    switch (state) {
      case AuthInitial _:
      case AuthInitializing _:
        debugPrint('Showing splash screen');
        return const SplashScreen();
      case AuthSuccess successState:
        debugPrint('Showing home screen for user: ${successState.user.name}');
        return HomeScreen(user: successState.user);
      case AuthUnauthenticated _:
      case AuthFailure _:
        debugPrint('Showing login screen');
        return const LoginScreen();
      default:
        debugPrint('Unknown state, showing login screen');
        return const LoginScreen();
    }
  }
}
