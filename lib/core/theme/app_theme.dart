// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── PALETTE ──────────────────────────────────────────────────────────────────
class LTColors {
  LTColors._();

  // Backgrounds
  static const bg       = Color(0xFF070707);
  static const surface1 = Color(0xFF0E0E0E);
  static const surface2 = Color(0xFF141414);
  static const surface3 = Color(0xFF1C1C1C);
  static const surface4 = Color(0xFF242424);

  // Borders
  static const border1  = Color(0xFF1E1E1E);
  static const border2  = Color(0xFF2A2A2A);
  static const border3  = Color(0xFF383838);

  // Text
  static const text1    = Color(0xFFF0F0F0);
  static const text2    = Color(0xFF888888);
  static const text3    = Color(0xFF484848);
  static const text4    = Color(0xFF2E2E2E);

  // Brand Accents
  static const cyan     = Color(0xFF3ECFCA);
  static const cyanDim  = Color(0x1F3ECFCA);  // 12%
  static const cyanGlow = Color(0x4D3ECFCA);  // 30%

  static const gold     = Color(0xFFC8A84C);
  static const goldDim  = Color(0x1FC8A84C);

  static const green    = Color(0xFF4DB87A);
  static const greenDim = Color(0x1F4DB87A);

  static const red      = Color(0xFFD95F5F);
  static const redDim   = Color(0x1FD95F5F);

  static const violet   = Color(0xFF8B7CF6);
  static const violetDim= Color(0x1F8B7CF6);

  static const amber    = Color(0xFFF0A868);

  // Gradients
  static const gradientCyan = LinearGradient(
    colors: [Color(0xFF3ECFCA), Color(0xFF2BB5B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFC8A84C), Color(0xFFAA8C38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGradient(Color accent) => LinearGradient(
    colors: [accent.withOpacity(0.08), Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Mood colors
  static const moodColors = [
    Color(0xFFD95F5F), // terrible
    Color(0xFFF0A868), // bad
    Color(0xFF888888), // neutral
    Color(0xFF4DB87A), // good
    Color(0xFF3ECFCA), // great
  ];

  // Priority
  static const priorityHigh   = Color(0xFFD95F5F);
  static const priorityMedium = Color(0xFFC8A84C);
  static const priorityLow    = Color(0xFF4DB87A);
}

// ─── TYPOGRAPHY ───────────────────────────────────────────────────────────────
class LTText {
  LTText._();

  static TextStyle display(double size) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    color: LTColors.text1,
    letterSpacing: -0.03 * size,
    height: 1.1,
  );

  static TextStyle heading(double size, {FontWeight weight = FontWeight.w500}) =>
    GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: LTColors.text1,
      letterSpacing: -0.015 * size,
      height: 1.2,
    );

  static TextStyle body(double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color ?? LTColors.text1,
    height: 1.55,
  );

  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: LTColors.text3,
    letterSpacing: 0.12,
    height: 1.3,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    color: LTColors.text2,
    height: 1.5,
  );
}

// ─── RADIUS ───────────────────────────────────────────────────────────────────
class LTRadius {
  LTRadius._();
  static const xs  = BorderRadius.all(Radius.circular(6));
  static const sm  = BorderRadius.all(Radius.circular(10));
  static const md  = BorderRadius.all(Radius.circular(14));
  static const lg  = BorderRadius.all(Radius.circular(18));
  static const xl  = BorderRadius.all(Radius.circular(24));
  static const xxl = BorderRadius.all(Radius.circular(32));
  static const full= BorderRadius.all(Radius.circular(999));
}

// ─── SHADOWS ──────────────────────────────────────────────────────────────────
class LTShadow {
  LTShadow._();
  static const sm = [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0,1))];
  static const md = [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0,4))];
  static const lg = [BoxShadow(color: Color(0x77000000), blurRadius: 40, offset: Offset(0,12))];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(color: color.withOpacity(0.30), blurRadius: 20, offset: const Offset(0,4)),
  ];
}

// ─── SPACING ──────────────────────────────────────────────────────────────────
class LTSpace {
  LTSpace._();
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 14.0;
  static const lg  = 20.0;
  static const xl  = 28.0;
  static const xxl = 40.0;
}

// ─── THEME ────────────────────────────────────────────────────────────────────
class LTTheme {
  LTTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LTColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   LTColors.cyan,
      secondary: LTColors.gold,
      surface:   LTColors.surface1,
      error:     LTColors.red,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor:    LTColors.text1,
      displayColor: LTColors.text1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LTColors.bg,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(color: LTColors.text1, fontSize: 17, fontWeight: FontWeight.w500),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      },
    ),
    dividerColor: LTColors.border1,
    dividerTheme: const DividerThemeData(color: LTColors.border1, thickness: 1, space: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LTColors.surface2,
      border: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
      enabledBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
      focusedBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.cyan, width: 1.5)),
      hintStyle: LTText.body(14, color: LTColors.text3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: LTColors.cyan,
      unselectedItemColor: LTColors.text3,
    ),
  );
}
