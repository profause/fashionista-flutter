import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ThemeData fashionistaLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF262626), // Black
    onPrimary: Color(0xFFFFFFFF), // White on black

    secondary: Color(0xFF2E2E2E), // Dark grey
    onSecondary: Color(0xFFFFFFFF),

    surface: Color(0xFFF7F7F7), // Off-white background
    onSurface: Color(0xFF262626), // Black text/icons

    error: Colors.red,
    onError: Colors.white,

    surfaceContainerHighest: Color(0xFFF0F0F0), // Light grey cards/panels
    onSurfaceVariant: Color(0xFF262626),

    outline: Color(0xFF6E6E6E), // Medium grey borders/icons
    shadow: Color(0xFF262626),
    scrim: Color(0xFF262626),

    inverseSurface: Color(0xFF262626),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFFFFFFFF),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1C1C1C),
    foregroundColor: Colors.white,
    elevation: 1,
    scrolledUnderElevation: 0,
    shadowColor: Color(0xFF262626),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark, // Android icons
      statusBarBrightness: Brightness.light, // iOS icons
    ),
  ),
  dividerColor: const Color(0xFFE0E0E0),
);

final ThemeData fashionistaDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFFFFF), // White
    onPrimary: Color(0xFF262626), // Black on white

    secondary: Color(0xFFE0E0E0), // Light grey
    onSecondary: Color(0xFF262626),

    surface: Color(0xFF121212), // Almost black background
    onSurface: Color(0xFFFFFFFF), // White text/icons

    error: Colors.red,
    onError: Colors.black,

    surfaceContainerHighest: Color(0xFF1E1E1E), // Dark grey cards/panels
    onSurfaceVariant: Color(0xFFFFFFFF),

    outline: Color(0xFF6E6E6E),
    shadow: Color(0xFF262626),
    scrim: Color(0xFF262626),

    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF262626),
    inversePrimary: Color(0xFF262626),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1C1C1C),
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dividerColor: const Color(0xFF2C2C2C),
);

class AppTheme {
  static Color black = const Color(0xFF262626);
  static Color white = const Color(0xFFFFFFFF);
  static Color lightGrey = const Color(0xFFE0E0E0);
  static Color darkGrey = const Color(0xFF6E6E6E);
  static Color charcoal = const Color(0xFF1C1C1C);

  static TextStyle titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle appTitleStyle = const TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
  );
}
