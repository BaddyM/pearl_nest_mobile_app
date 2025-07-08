import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/widgets/theme_provider.dart';
import 'package:pearlnest/providers/auth_provider.dart';
import 'package:pearlnest/blocs/auth/auth_bloc.dart';
import 'package:pearlnest/blocs/auth/auth_state.dart';
import 'package:pearlnest/blocs/property/property_bloc.dart';
import 'package:pearlnest/screens/common/splash_screen.dart';
import 'package:pearlnest/screens/common/login_screen.dart';
import 'package:pearlnest/screens/tenant/home_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
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
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          // Keep AuthProvider for backward compatibility during transition
          ChangeNotifierProvider(create: (context) => AuthProvider()),
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
    
    switch (state.runtimeType) {
      case AuthInitial:
      case AuthInitializing:
        debugPrint('Showing splash screen');
        return const SplashScreen();
      case AuthSuccess:
        final successState = state as AuthSuccess;
        debugPrint('Showing home screen for user: ${successState.user.name}');
        return HomeScreen(user: successState.user);
      case AuthUnauthenticated:
      case AuthFailure:
        debugPrint('Showing login screen');
        return const LoginScreen();
      default:
        debugPrint('Unknown state, showing login screen');
        return const LoginScreen();
    }
  }
}
