import 'package:flutter/material.dart';
import 'package:pearlnest/screens/common/splash_screen.dart';
import 'package:pearlnest/widgets/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PearlNest Estates',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
