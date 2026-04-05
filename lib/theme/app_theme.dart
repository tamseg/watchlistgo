import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // ─── Glass Aesthetics ────────────────────────────────────────────
  // Centralized frosted glass parameters
  static const double glassBlurSigma = 15.0;
  static const double glassOpacity = 0.5;

  static Widget buildFrostedGlassBackground() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glassBlurSigma, sigmaY: glassBlurSigma),
        child: Container(
          color: Colors.white.withValues(alpha: glassOpacity),
        ),
      ),
    );
  }
  // ─── Semantic Colors ─────────────────────────────────────────────
  // Change these in one place to update the entire app.

  // Brand
  static const Color primaryColor = Colors.cyan;
  static const Color navActiveColor = Color(0xFF1E88E5);
  static const Color darkTextColor = Color(0xFF212121); // grey[900]

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.5, -3.0),
    end: Alignment(0.5, 3.0),
    colors: [
      Color(0xFF4acbde),
      Color(0xFF429ae0),
      Color(0xFF5488e6),
      Color(0xFF7d6dec),
    ],
    stops: [0.10, 0.40, 0.60, 0.9],
  );

  // Backgrounds
  static const Color scaffoldColor = Colors.white;
  static const Color placeholderColor = Color(0xFFE0E0E0); // grey[300]
  static final Color tabTrackColor = Colors.grey[200]!;

  // Detail Pages
  static const Color ratingStarColor = Colors.amber;
  static const Color secondaryTextColor = Color(0xFF8E8E93); // grey[500]
  static const Color metaIconColor = Colors.grey;
  static const Color fallbackTitleColor = Colors.black;
  static const Color shadowColor = Color(0x0D000000);
  static const Color detailAppBarIconColor = Colors.white;

  // Backdrop Gradient
  static const Color backdropOverlayDark = Colors.black;
  static const Color backdropOverlayLight = Colors.white;

  // Episode Badge (Series Detail)
  static const Color episodeBadgeColor = Colors.blue;

  // ─── Theme Data ──────────────────────────────────────────────────

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5edde0), // Using exact electric cyan for the seed
      primary: const Color(0xFF5edde0),   // Using exact electric cyan for primary
    ),
    scaffoldBackgroundColor: scaffoldColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: scaffoldColor,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      indicator: tabPillDecoration,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: primaryColor,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: darkTextColor,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: darkTextColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF616161),
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor.withValues(alpha: 0.7),
      ),
    ),
  );

  // ─── Layout Constants ────────────────────────────────────────────

  static const double appBarBottomHeight = 80.0;
  static const EdgeInsets appBarBottomPadding = EdgeInsets.only(
    top: 28.0,
    bottom: 12.0,
  );
  static const double tabContainerHeight = 40.0;
  static const double tabContainerWidth = 250.0;
  static const EdgeInsets tabIndicatorPadding = EdgeInsets.all(4.0);
  static const double detailLogoHeight = 60.0;
  static const double detailLogoMaxWidthFactor = 0.55; // fraction of screen width
  static const double backdropHeight = 300.0;
  static const double cardHeight = 88.0;

  // ─── Custom Decorations ──────────────────────────────────────────

  static const double tabBorderRadius = 4.0;

  static final BoxDecoration tabTrackDecoration = BoxDecoration(
    color: tabTrackColor,
    borderRadius: BorderRadius.circular(tabBorderRadius),
  );

  static final BoxDecoration tabPillDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(tabBorderRadius),
    color: primaryColor,
  );

  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 8,
    spreadRadius: 1,
    offset: const Offset(0, 2),
  );

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: [cardShadow],
  );

  // ─── Text Styles ─────────────────────────────────────────────────

  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle watchlistPartStyle = TextStyle(
    color: darkTextColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle goPartStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
  );

  // ─── Helper Methods ──────────────────────────────────────────────

  /// Builds the gradient overlay used on backdrop images in detail pages.
  static List<Color> get backdropGradientColors => [
    backdropOverlayDark.withValues(alpha: 0.2),
    Colors.transparent,
    Colors.transparent,
    backdropOverlayLight.withValues(alpha: 0.5),
    backdropOverlayLight,
  ];

  static const List<double> backdropGradientStops = [0.0, 0.1, 0.6, 0.85, 1.0];
}
