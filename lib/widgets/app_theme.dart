import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryblue = Color.fromARGB(255, 53, 174, 143);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color blackColor = Color(0xFF212121);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF757575);
  static const Color lightGreyColor = Color(0xFFF5F5F5);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryblue,
    colorScheme: ColorScheme.light(
      primary: primaryblue,
      surface: whiteColor,
      onPrimary: whiteColor,
      onSecondary: whiteColor,
      onSurface: blackColor,
    ),
    scaffoldBackgroundColor: whiteColor,
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
    colorScheme: ColorScheme.dark(
      secondary: accentGreen,
      surface: Color(0xFF303030),
      onPrimary: blackColor,
      onSecondary: blackColor,
      onSurface: whiteColor,
    ),
    scaffoldBackgroundColor: blackColor,
  );
}
