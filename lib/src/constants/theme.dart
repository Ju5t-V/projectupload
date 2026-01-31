import 'package:flutter/material.dart';

// Colors extracted from your video
const kPrimaryColor = Color(0xFFB71C1C); // The deep red
const kSecondaryColor = Color(0xFFFFC107); // The gold/yellow
const kBackgroundColor = Color(0xFFF5F5F5); // Light grey background

final appTheme = ThemeData(
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: kBackgroundColor,
  appBarTheme: AppBarTheme(
    backgroundColor: kPrimaryColor,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor, // Button color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);