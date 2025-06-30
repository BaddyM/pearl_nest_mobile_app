import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryblue = Color.fromARGB(255, 53, 174, 143);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color blackColor = Color(0xFF212121);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF757575);
  static const Color lightGreyColor = Color(0xFFF5F5F5);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkGreyColor = Color(0xFF404040);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryblue,
    colorScheme: ColorScheme.light(
      primary: primaryblue,
      secondary: accentGreen,
      surface: whiteColor,
      background: whiteColor,
      onPrimary: whiteColor,
      onSecondary: whiteColor,
      onSurface: blackColor,
      onBackground: blackColor,
    ),
    scaffoldBackgroundColor: whiteColor,
    cardColor: lightGreyColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryblue,
      elevation: 0,
      iconTheme: IconThemeData(color: whiteColor),
      titleTextStyle: TextStyle(
        color: whiteColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: blackColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: blackColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: blackColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: blackColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: greyColor,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryblue,
        foregroundColor: whiteColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: greyColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryblue, width: 2),
      ),
      labelStyle: TextStyle(color: greyColor),
      prefixIconColor: greyColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryblue,
    colorScheme: ColorScheme.dark(
      primary: primaryblue,
      secondary: accentGreen,
      surface: darkSurface,
      background: darkBackground,
      onPrimary: whiteColor,
      onSecondary: blackColor,
      onSurface: darkTextPrimary,
      onBackground: darkTextPrimary,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryblue,
      elevation: 0,
      iconTheme: IconThemeData(color: whiteColor),
      titleTextStyle: TextStyle(
        color: whiteColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: darkTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: darkTextPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: darkTextPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: darkTextSecondary,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryblue,
        foregroundColor: whiteColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkTextSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryblue, width: 2),
      ),
      labelStyle: TextStyle(color: darkTextSecondary),
      prefixIconColor: darkTextSecondary,
    ),
  );

  // Helper methods to get theme-aware colors
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onBackground;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.color ?? greyColor;
  }
}