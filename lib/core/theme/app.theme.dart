import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Atelier Chic (light) design tokens ─────────────────────────────────
const Color _acCanvas = Color(0xFFF8F9FA); // cool light canvas base
const Color _acCard = Color(0xFFFFFFFF); // pure white surfaces
const Color _acBorder = Color(0xFFE4E7EB); // architectural hairlines
const Color _acEmber = Color(0xFFFF5A00); // signature brand accent
const Color _acEmberPressed = Color(0xFFE04F00);
const Color _acOnEmber = Color(0xFFFFFFFF);
const Color _acCharcoal = Color(0xFF1A1C1E); // editorial text anchor
const Color _acSurface = Color(0xFF141D23);
const Color _acMuted = Color(0xFF6C757D); // secondary / metadata text
const Color _acPrimary = Color(0xFFA83900); // rust primary (text/links)
const Color _acPeachContainer = Color(0xFFFFB59A);
const Color _acOnPrimaryContainer = Color(0xFF511700);
const Color _acSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color _acSurfaceLow = Color(0xFFECF5FE);
const Color _acSurfaceContainer = Color(0xFFE6EFF8);
const Color _acSurfaceHigh = Color(0xFFE0E9F2);
const Color _acSurfaceHighest = Color(0xFFDBE4ED);
const Color _acSurfaceDim = Color(0xFFD2DBE4);
const Color _acOnSurfaceVariant = Color(0xFF5B4137);
const Color _acOutline = Color(0xFF907065);
const Color _acInverseSurface = Color(0xFF293138);
const Color _acOnInverseSurface = Color(0xFFE9F2FB);
const Color _acSecondary = Color(0xFF5D5E61);
const Color _acSecondaryContainer = Color(0xFFE2E2E5);
const Color _acOnSecondaryContainer = Color(0xFF636467);
const Color _acTertiary = Color(0xFF006C49);
const Color _acTertiaryContainer = Color(0xFF00A673);
const Color _acOnTertiaryContainer = Color(0xFF003220);
const Color _acError = Color(0xFFBA1A1A);
const Color _acErrorContainer = Color(0xFFFFDAD6);
const Color _acOnErrorContainer = Color(0xFF93000A);
const Color _acScrim = Color(0x52000000); // rgba(0,0,0,0.32) modal barrier

final ThemeData fashionistaLightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: _acEmber,
    onPrimary: _acOnEmber,
    primaryContainer: _acPeachContainer,
    onPrimaryContainer: _acOnPrimaryContainer,
    inversePrimary: _acPeachContainer,
    secondary: _acSecondary,
    onSecondary: _acOnEmber,
    secondaryContainer: _acSecondaryContainer,
    onSecondaryContainer: _acOnSecondaryContainer,
    tertiary: _acTertiary,
    onTertiary: _acOnEmber,
    tertiaryContainer: _acTertiaryContainer,
    onTertiaryContainer: _acOnTertiaryContainer,
    error: _acError,
    onError: _acOnEmber,
    errorContainer: _acErrorContainer,
    onErrorContainer: _acOnErrorContainer,
    surface: Color(0xFFF6FAFF),
    onSurface: _acSurface,
    surfaceDim: _acSurfaceDim,
    surfaceBright: Color(0xFFF6FAFF),
    surfaceContainerLowest: _acSurfaceContainerLowest,
    surfaceContainerLow: _acSurfaceLow,
    surfaceContainer: _acSurfaceContainer,
    surfaceContainerHigh: _acSurfaceHigh,
    surfaceContainerHighest: _acSurfaceHighest,
    onSurfaceVariant: _acOnSurfaceVariant,
    outline: _acOutline,
    outlineVariant: _acBorder,
    surfaceTint: _acPrimary,
    inverseSurface: _acInverseSurface,
    onInverseSurface: _acOnInverseSurface,
    shadow: Color(0xFF000000),
    scrim: _acScrim,
  ),
  scaffoldBackgroundColor: _acCanvas,
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: _acCanvas,
    foregroundColor: _acSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: _acCanvas,
      statusBarIconBrightness: Brightness.dark, // Android icons
      statusBarBrightness: Brightness.light, // iOS icons
    ),
  ),
  iconTheme: const IconThemeData(color: _acMuted, size: 24),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: _acMuted),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.8,
      color: _acSurface,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.48,
      color: _acSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: -0.24,
      color: _acSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: -0.1,
      color: _acSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.33,
      color: _acSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: _acSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      color: _acSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: _acSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      color: _acSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: _acMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      color: _acSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.24,
      color: _acMuted,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0.44,
      color: _acMuted,
    ),
  ),
  dividerColor: _acBorder,
  dividerTheme: const DividerThemeData(
    color: _acBorder,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    color: _acCard,
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: 0.06),
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _acBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _acCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: _acCard,
    modalBackgroundColor: _acCard,
    modalBarrierColor: _acScrim,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _acCard,
    isDense: true,
    hintStyle: const TextStyle(fontSize: 14, color: _acMuted),
    errorStyle: const TextStyle(fontSize: 12, color: _acError),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    // enabledBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _acBorder),
    // ),
    // focusedBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _acEmber, width: 1.5),
    // ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _acBorder),
    ),
    labelStyle: const TextStyle(fontSize: 14, color: _acMuted),
    prefixIconColor: _acMuted,
    suffixIconColor: _acMuted,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _acEmber,
      disabledBackgroundColor: _acEmberPressed.withValues(alpha: 0.4),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
      overlayColor: _acEmberPressed.withValues(alpha: 0.4),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _acEmber,
      foregroundColor: Colors.white,
      elevation: 0,
      overlayColor: _acEmberPressed.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _acCharcoal,
      backgroundColor: _acCard,
      side: const BorderSide(color: _acBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: _acMuted),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: const WidgetStatePropertyAll(Colors.white),
    trackColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? _acEmber
          : const Color(0xFFCBD5E1);
    }),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected) ? _acEmber : _acBorder;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? _acEmber
          : Colors.transparent;
    }),
    side: const BorderSide(color: _acBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _acCanvas,
    selectedColor: _acEmber.withValues(alpha: 0.08),
    side: const BorderSide(color: _acBorder),
    shape: const StadiumBorder(),
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: _acMuted,
    ),
    secondaryLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _acEmber,
      letterSpacing: 0.24,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _acEmber,
    circularTrackColor: _acBorder,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _acCard,
    indicatorColor: _acEmber.withValues(alpha: 0.08),
    surfaceTintColor: Colors.transparent,
    height: 64,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: _acEmber);
      }
      return const IconThemeData(color: _acMuted);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _acEmber,
        );
      }
      return const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _acMuted,
      );
    }),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _acCharcoal,
    contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: _acEmber,
    unselectedLabelColor: _acMuted,
    indicatorColor: _acEmber,
    dividerColor: _acBorder,
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: _acCard,
    headerBackgroundColor: const Color(0xFFF6FAFF),
    headerForegroundColor: _acSurface,
    surfaceTintColor: Colors.transparent,
  ),
);

// ─── Obsidian Ember (dark) design tokens ────────────────────────────────
const Color _odBase = Color(0xFF0D0D0C); // canvas floor
const Color _odCard = Color(0xFF1A1A19); // elevated containers, inputs, sheets
const Color _odBorder = Color(0xFF2D2D2A); // structural outlines / dividers
const Color _odPrimary = Color(0xFFFF5A00); // ember accent
const Color _odPrimaryPressed = Color(0xFFE04F00);
const Color _odPrimaryPeach = Color(0xFFFFB59A);
const Color _odOnPrimary = Color(0xFFFFFFFF);
const Color _odOnPrimaryDark = Color(0xFF5B1B00);
const Color _odInversePrimary = Color(0xFFA83900);
const Color _odSurface = Color(0xFF131312);
const Color _odOnSurface = Color(0xFFE5E2E0);
const Color _odSurfaceDim = Color(0xFF131312);
const Color _odSurfaceBright = Color(0xFF3A3938);
const Color _odSurfaceContainerLowest = Color(0xFF0E0E0D);
const Color _odSurfaceLow = Color(0xFF1C1C1A);
const Color _odSurfaceContainer = Color(0xFF20201E);
const Color _odSurfaceHigh = Color(0xFF2A2A29);
const Color _odSurfaceHighest = Color(0xFF353533);
const Color _odOnSurfaceVariant = Color(0xFFE4BEB1);
const Color _odOutline = Color(0xFFAB897E);
const Color _odSecondary = Color(0xFFC8C6C4);
const Color _odOnSecondary = Color(0xFF31302F);
const Color _odSecondaryContainer = Color(0xFF474745);
const Color _odOnSecondaryContainer = Color(0xFFB7B5B3);
const Color _odTertiary = Color(0xFFA0C9FF);
const Color _odOnTertiary = Color(0xFF00325A);
const Color _odTertiaryContainer = Color(0xFF0095FC);
const Color _odOnTertiaryContainer = Color(0xFF002C50);
const Color _odError = Color(0xFFFFB4AB);
const Color _odOnError = Color(0xFF690005);
const Color _odErrorContainer = Color(0xFF93000A);
const Color _odOnErrorContainer = Color(0xFFFFDAD6);
const Color _odInverseSurface = Color(0xFFE5E2E0);
const Color _odInverseOnSurface = Color(0xFF31302F);
const Color _odTrackInactive = Color(0xFF2C2C2E);
const Color _odMuted = Color(0xFFA1A19A);
const Color _odScrim = Color(0xB70D0D0C); // rgba(13,13,12,0.72)

final ThemeData fashionistaDarkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: _odPrimary,
    onPrimary: _odOnPrimary,
    primaryContainer: _odPrimaryPeach,
    onPrimaryContainer: _odOnPrimaryDark,
    inversePrimary: _odInversePrimary,
    secondary: _odSecondary,
    onSecondary: _odOnSecondary,
    secondaryContainer: _odSecondaryContainer,
    onSecondaryContainer: _odOnSecondaryContainer,
    tertiary: _odTertiary,
    onTertiary: _odOnTertiary,
    tertiaryContainer: _odTertiaryContainer,
    onTertiaryContainer: _odOnTertiaryContainer,
    error: _odError,
    onError: _odOnError,
    errorContainer: _odErrorContainer,
    onErrorContainer: _odOnErrorContainer,
    surface: _odSurface,
    onSurface: _odOnSurface,
    surfaceDim: _odSurfaceDim,
    surfaceBright: _odSurfaceBright,
    surfaceContainerLowest: _odSurfaceContainerLowest,
    surfaceContainerLow: _odSurfaceLow,
    surfaceContainer: _odSurfaceContainer,
    surfaceContainerHigh: _odSurfaceHigh,
    surfaceContainerHighest: _odSurfaceHighest,
    onSurfaceVariant: _odOnSurfaceVariant,
    outline: _odOutline,
    outlineVariant: Color(0xFF353637),
    surfaceTint: _odPrimaryPeach,
    inverseSurface: _odInverseSurface,
    onInverseSurface: _odInverseOnSurface,
    shadow: Color(0xFF000000),
    scrim: _odScrim,
  ),
  scaffoldBackgroundColor: _odBase,
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: _odBase,
    foregroundColor: _odOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: _odBase,
      statusBarIconBrightness: Brightness.light, // Android icons
      statusBarBrightness: Brightness.dark, // iOS icons
    ),
  ),
  iconTheme: const IconThemeData(color: _odOnSurface, size: 24),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: _odOnSurface),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.64,
      color: _odOnSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.23,
      letterSpacing: -0.39,
      color: _odOnSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.33,
      color: _odOnSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      color: _odOnSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.29,
      color: _odOnSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.38,
      color: _odOnSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: _odOnSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      color: _odOnSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.12,
      color: _odOnSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: _odOnSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.29,
      color: _odOnSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: _odOnSurfaceVariant,
    ),
  ),
  dividerColor: _odBorder,
  dividerTheme: const DividerThemeData(
    color: _odBorder,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    color: _odCard,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _odBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _odCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: _odCard,
    modalBackgroundColor: _odCard,
    modalBarrierColor: _odScrim,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _odCard,
    isDense: true,
    hintStyle: const TextStyle(fontSize: 14, color: _odMuted),
    errorStyle: const TextStyle(fontSize: 12, color: _odError),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    // enabledBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _odBorder),
    // ),
    // focusedBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _odPrimary, width: 1.5),
    // ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _odBorder),
    ),
    labelStyle: const TextStyle(fontSize: 14, color: _odMuted),
    prefixIconColor: _odMuted,
    suffixIconColor: _odMuted,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _odPrimary,
      disabledBackgroundColor: _odPrimaryPressed.withValues(alpha: 0.4),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _odPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: _odCard,
      side: const BorderSide(color: _odBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: _odPrimary),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: const WidgetStatePropertyAll(Colors.white),
    trackColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? _odPrimary
          : _odTrackInactive;
    }),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected) ? _odPrimary : _odOutline;
    }),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? _odPrimary
          : Colors.transparent;
    }),
    side: const BorderSide(color: _odOutline),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _odBorder.withValues(alpha: 0.5),
    selectedColor: _odPrimary.withValues(alpha: 0.15),
    side: const BorderSide(color: _odBorder),
    shape: const StadiumBorder(),
    labelStyle: const TextStyle(fontSize: 14, color: _odMuted),
    secondaryLabelStyle: const TextStyle(fontSize: 14, color: _odPrimary),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _odPrimary,
    circularTrackColor: _odBorder,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _odBase,
    indicatorColor: _odCard,
    surfaceTintColor: Colors.transparent,
    height: 64,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: _odPrimary);
      }
      return const IconThemeData(color: _odMuted);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _odPrimary,
        );
      }
      return const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _odMuted,
      );
    }),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _odSurfaceHighest,
    contentTextStyle: const TextStyle(fontSize: 14, color: _odOnSurface),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: _odPrimary,
    unselectedLabelColor: _odMuted,
    indicatorColor: _odPrimary,
    dividerColor: _odBorder,
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: _odCard,
    headerBackgroundColor: _odSurfaceLow,
    headerForegroundColor: _odOnSurface,
    surfaceTintColor: Colors.transparent,
  ),
);

/// Theme-aware color roles used by restyled screens so they render correctly
/// in both the light ("Atelier Chic") and dark ("Obsidian Ember") themes.
extension FashionistaThemeRole on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Screen canvas (light #F8F9FA, dark #0D0D0C).
  Color get canvasBackground => Theme.of(this).scaffoldBackgroundColor;

  /// Elevated card / input surface (light white, dark #1A1A19).
  Color get cardSurface =>
      Theme.of(this).cardTheme.color ?? const Color(0xFFFFFFFF);

  /// Hairline borders & dividers (light #E2E8F0, dark #2D2D2A).
  Color get hairline => Theme.of(this).colorScheme.outlineVariant;

  /// Stronger inactive-control border (light #CBD5E1, dark #353533).
  Color get softBorder =>
      isDarkTheme ? const Color(0xFF353533) : const Color(0xFFCBD5E1);

  /// Primary text (light #1A1C1E, dark #E5E2E0).
  Color get onCanvasText => Theme.of(this).colorScheme.onSurface;

  /// Muted / secondary text (light #6C757D, dark #A1A19A).
  Color get mutedText =>
      isDarkTheme ? const Color(0xFFA1A19A) : const Color(0xFF6C757D);

  /// Body / description text (light #374151, dark #A1A19A).
  Color get descriptionText =>
      isDarkTheme ? const Color(0xFFA1A19A) : const Color(0xFF374151);

  /// Row label / icon tile color (light #64748B, dark #94A3B8).
  Color get secondaryLabel =>
      isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Neutral icon tile background (light #F1F5F9, dark #262624).
  Color get iconSubstrate =>
      isDarkTheme ? const Color(0xFF262624) : const Color(0xFFF1F5F9);

  /// Tonal / secondary button background (light #F3F4F6, dark #262624).
  Color get secondaryButtonBg =>
      isDarkTheme ? const Color(0xFF262624) : const Color(0xFFF3F4F6);

  /// Faint placeholder text (light #94A3B8, dark #8A8A83).
  Color get placeholderText =>
      isDarkTheme ? const Color(0xFF8A8A83) : const Color(0xFF94A3B8);

  /// Signature brand accent, constant across both themes.
  Color get accent => const Color(0xFFFF5A00);
}

class AppTheme {
  static Color black = const Color(0xFF262626);
  static Color white = const Color(0xFFFFFFFF);
  static Color lightGrey = const Color(0xFFE0E0E0);
  static Color darkGrey = const Color(0xFF6E6E6E);
  static Color charcoal = const Color(0xFF1C1C1C);
  static Color appIconColor = const Color(0xFFF55B02);
  static Color appIconColorTint = const Color(0xFFf77b34);

  static TextStyle titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle appTitleStyle = const TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
  );
}

final materialColorPairs = [
  {'background': '90CAF9', 'foreground': '000000'},
  {'background': 'A5D6A7', 'foreground': '000000'},
  {'background': 'FFE082', 'foreground': '000000'},
  {'background': 'EF9A9A', 'foreground': '000000'},
  {'background': 'B0BEC5', 'foreground': '000000'}, // default grey[500]
];

Map<String, String> getRandomColorPair() {
  final random = Random();
  return materialColorPairs[random.nextInt(materialColorPairs.length)];
}
