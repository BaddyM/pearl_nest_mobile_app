import 'package:flutter/material.dart';
import 'package:pearlnest/apis/api_client.dart';
import 'package:pearlnest/widgets/theme_provider.dart';
import 'package:pearlnest/providers/auth_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'PearlNest Estates',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: _buildHome(authProvider),
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthProvider authProvider) {
    switch (authProvider.status) {
      case AuthStatus.unknown:
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return HomeScreen(user: authProvider.user!);
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
