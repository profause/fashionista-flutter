import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_constants.dart';

// ─── Azure Chic (light) design tokens ───────────────────────────────────
const Color _acCanvas = Color(0xFFF0F1F3); // cool light canvas base
const Color _acCard = Color(0xFFFFFFFF); // elevated surfaces (surfaceContainerLow)
const Color _acBorder = Color(0xFFD8D8DA); // architectural hairlines
const Color _acEmber = Color(0xFF0F7CF9); // signature brand accent
const Color _acEmberPressed = Color(0xFF0B62C4);
const Color _acOnEmber = Color(0xFFFFFFFF);
const Color _acCharcoal = Color(0xFF1C1B1F); // editorial text anchor
const Color _acSurface = Color(0xFF1C1B1F);
const Color _acMuted = Color(0xFF49454F); // secondary / metadata text
const Color _acPrimary = Color(0xFF0F7CF9); // azure primary (text/links)
const Color _acPeachContainer = Color(0xFF5FCCFF);
const Color _acOnPrimaryContainer = Color(0xFF0054D1);
const Color _acSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color _acSurfaceLow = Color(0xFFFFFFFF);
const Color _acSurfaceContainer = Color(0xFFF3EDF7);
const Color _acSurfaceHigh = Color(0xFFECE6F0);
const Color _acSurfaceHighest = Color(0xFFE6E0E9);
const Color _acSurfaceDim = Color(0xFFE6E0E9);
const Color _acOnSurfaceVariant = Color(0xFF49454F);
const Color _acOutline = Color(0xFF79747E);
const Color _acInverseSurface = Color(0xFF313033);
const Color _acOnInverseSurface = Color(0xFFF4EFF4);
const Color _acSecondary = Color(0xFF177FF5);
const Color _acSecondaryContainer = Color(0xFF67CFFF);
const Color _acOnSecondaryContainer = Color(0xFF0057CD);
const Color _acTertiary = Color(0xFF0F7EFD);
const Color _acTertiaryContainer = Color(0xFF5FCFFF);
const Color _acOnTertiaryContainer = Color(0xFF0056D5);
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
    surface: _acCanvas,
    onSurface: _acSurface,
    surfaceDim: _acSurfaceDim,
    surfaceBright: _acSurfaceContainerLowest,
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
  ).apply(fontSizeFactor: ScreenUtil().scaleText),
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
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      side: const BorderSide(color: _acBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _acCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: _acCard,
    modalBackgroundColor: _acCard,
    modalBarrierColor: _acScrim,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusLG),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _acCard,
    isDense: true,
    hintStyle: const TextStyle(fontSize: 14, color: _acMuted),
    errorStyle: const TextStyle(fontSize: 12, color: _acError),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMD,
      vertical: 12,
    ),
    // enabledBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _acBorder),
    // ),
    // focusedBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _acEmber, width: 1.5),
    // ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
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
      minimumSize: Size(0, AppConstants.buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      textStyle: TextStyle(
        fontSize: AppConstants.fontSizeTitleMedium,
        fontWeight: FontWeight.w600,
      ),
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
    headerBackgroundColor: _acSurfaceLow,
    headerForegroundColor: _acSurface,
    surfaceTintColor: Colors.transparent,
  ),
);

// ─── Midnight Azure (dark) design tokens ────────────────────────────────
const Color _odBase = Color(0xFF10090D); // canvas floor
const Color _odCard = Color(0xFF1D1418); // elevated containers, inputs, sheets
const Color _odBorder = Color(0xFF49454F); // structural outlines / dividers
const Color _odPrimary = Color(0xFF0068E5); // azure accent
const Color _odPrimaryPressed = Color(0xFF0040BD);
const Color _odPrimaryPeach = Color(0xFF5FCCFF);
const Color _odOnPrimary = Color(0xFFFFFFFF);
const Color _odOnPrimaryDark = Color(0xFF0040BD);
const Color _odInversePrimary = Color(0xFF0F7CF9);
const Color _odSurface = Color(0xFF10090D);
const Color _odOnSurface = Color(0xFFE6E0E9);
const Color _odSurfaceDim = Color(0xFF10090D);
const Color _odSurfaceBright = Color(0xFF362F33);
const Color _odSurfaceContainerLowest = Color(0xFF0B0509);
const Color _odSurfaceLow = Color(0xFF1D1418);
const Color _odSurfaceContainer = Color(0xFF211A1E);
const Color _odSurfaceHigh = Color(0xFF2B2329);
const Color _odSurfaceHighest = Color(0xFF362F33);
const Color _odOnSurfaceVariant = Color(0xFFCAC4D0);
const Color _odOutline = Color(0xFF938F99);
const Color _odSecondary = Color(0xFF036BE1);
const Color _odOnSecondary = Color(0xFFFFFFFF);
const Color _odSecondaryContainer = Color(0xFF0043B9);
const Color _odOnSecondaryContainer = Color(0xFFFFFFFF);
const Color _odTertiary = Color(0xFF006AE9);
const Color _odOnTertiary = Color(0xFFFFFFFF);
const Color _odTertiaryContainer = Color(0xFF0042C1);
const Color _odOnTertiaryContainer = Color(0xFFFFFFFF);
const Color _odError = Color(0xFFFFB4AB);
const Color _odOnError = Color(0xFF000000);
const Color _odErrorContainer = Color(0xFF93000A);
const Color _odOnErrorContainer = Color(0xFFFFDAD6);
const Color _odInverseSurface = Color(0xFFE6E0E9);
const Color _odInverseOnSurface = Color(0xFF313033);
const Color _odTrackInactive = Color(0xFF362F33);
const Color _odMuted = Color(0xFF938F99);
const Color _odScrim = Color(0xB710090D); // rgba(16,9,13,0.72)

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
    outlineVariant: _odBorder,
    surfaceTint: _odPrimary,
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
  ).apply(fontSizeFactor: ScreenUtil().scaleText),
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
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      side: const BorderSide(color: _odBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _odCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: _odCard,
    modalBackgroundColor: _odCard,
    modalBarrierColor: _odScrim,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusLG),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _odCard,
    isDense: true,
    hintStyle: const TextStyle(fontSize: 14, color: _odMuted),
    errorStyle: const TextStyle(fontSize: 12, color: _odError),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMD,
      vertical: 12,
    ),
    // enabledBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _odBorder),
    // ),
    // focusedBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: const BorderSide(color: _odPrimary, width: 1.5),
    // ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
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
      minimumSize: Size(0, AppConstants.buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      textStyle: TextStyle(
        fontSize: AppConstants.fontSizeTitleMedium,
        fontWeight: FontWeight.w600,
      ),
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

  /// Screen canvas (light #FFFBFE, dark #10090D).
  Color get canvasBackground => Theme.of(this).scaffoldBackgroundColor;

  /// Elevated card / input surface (light #F7F2FA, dark #1D1418).
  Color get cardSurface =>
      Theme.of(this).cardTheme.color ?? const Color(0xFFFFFFFF);

  /// Hairline borders & dividers (light #CAC4D0, dark #49454F).
  Color get hairline => Theme.of(this).colorScheme.outlineVariant;

  /// Stronger inactive-control border (light #79747E, dark #938F99).
  Color get softBorder => Theme.of(this).colorScheme.outline;

  /// Primary text (light #1C1B1F, dark #E6E0E9).
  Color get onCanvasText => Theme.of(this).colorScheme.onSurface;

  /// Muted / secondary text (light #49454F, dark #CAC4D0).
  Color get mutedText => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Body / description text (light #49454F, dark #CAC4D0).
  Color get descriptionText => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Row label / icon tile color (light #79747E, dark #938F99).
  Color get secondaryLabel => Theme.of(this).colorScheme.outline;

  /// Neutral icon tile background (light #ECE6F0, dark #2B2329).
  Color get iconSubstrate => Theme.of(this).colorScheme.surfaceContainerHigh;

  /// Tonal / secondary button background (light #F3EDF7, dark #2B2329).
  Color get secondaryButtonBg => isDarkTheme
      ? Theme.of(this).colorScheme.surfaceContainerHigh
      : Theme.of(this).colorScheme.surfaceContainer;

  /// Faint placeholder text (light #79747E, dark #938F99).
  Color get placeholderText => Theme.of(this).colorScheme.outline;

  /// Signature brand accent, constant across both themes.
  Color get accent => const Color(0xFF0F7CF9);
}

class AppTheme {
  static Color black = const Color(0xFF262626);
  static Color white = const Color(0xFFFFFFFF);
  static Color lightGrey = const Color(0xFFE0E0E0);
  static Color darkGrey = const Color(0xFF6E6E6E);
  static Color charcoal = const Color(0xFF1C1C1C);
  static Color appIconColor = const Color(0xFF0F7CF9);
  static Color appIconColorTint = const Color(0xFF4BB8FF);

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
