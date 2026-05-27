import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand-locked colors and theme builders for JoinIn.
///
/// The brand palette (primary green + secondary blue + gradient) stays the same
/// across light and dark themes so the app keeps a recognisable identity. All
/// surface and text colors are resolved through [Theme.of] / [ColorScheme] so
/// they swap cleanly when the user flips the light/dark toggle.
class AppTheme {
  AppTheme._();

  // ---- Brand palette (identical in both themes) ---------------------------
  static const Color primaryAccent = Color(0xFF00FF87); // Electric Green
  static const Color secondaryAccent = Color(0xFF00B4D8); // Bright Blue
  static const Color danger = Color(0xFFFF4D6D);

  /// The signature green→blue gradient. Used for hero CTAs and headers.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Dark palette -------------------------------------------------------
  static const Color _darkBackground = Color(0xFF0D1117);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkSurfaceElevated = Color(0xFF21262D);
  static const Color _darkOnSurface = Color(0xFFF0F6FC);
  static const Color _darkOnSurfaceMuted = Color(0xFF8B949E);
  static const Color _darkOutline = Color(0xFF30363D);

  // ---- Light palette ------------------------------------------------------
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceElevated = Color(0xFFEFF3F8);
  static const Color _lightOnSurface = Color(0xFF0D1117);
  static const Color _lightOnSurfaceMuted = Color(0xFF566270);
  static const Color _lightOutline = Color(0xFFE3E8EF);

  // ---- Legacy aliases (kept so existing const callsites still compile) ----
  // These are the *dark-theme* tokens. New code should prefer the
  // context-aware helpers on [AppColorsX] which swap with the theme. Existing
  // dark-only callsites continue to render exactly as they did before; the
  // migration to context-aware colors is being done screen by screen.
  static const Color darkBackground = _darkBackground;
  static const Color cardDark = _darkSurface;
  static const Color cardDarkElevated = _darkSurfaceElevated;
  static const Color textLight = _darkOnSurface;
  static const Color textMuted = _darkOnSurfaceMuted;

  // ---- Theme builders -----------------------------------------------------
  // Cached so `MaterialApp` doesn't rebuild the whole ThemeData (including
  // expensive GoogleFonts text themes) on every frame of the theme animation.
  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    surfaceElevated: _darkSurfaceElevated,
    onSurface: _darkOnSurface,
    onSurfaceMuted: _darkOnSurfaceMuted,
    outline: _darkOutline,
  );

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: _lightBackground,
    surface: _lightSurface,
    surfaceElevated: _lightSurfaceElevated,
    onSurface: _lightOnSurface,
    onSurfaceMuted: _lightOnSurfaceMuted,
    outline: _lightOutline,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceElevated,
    required Color onSurface,
    required Color onSurfaceMuted,
    required Color outline,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryAccent,
      onPrimary: _darkBackground,
      secondary: secondaryAccent,
      onSecondary: _darkBackground,
      error: danger,
      onError: Colors.white,
      surface: background,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: surfaceElevated,
      onSurfaceVariant: onSurfaceMuted,
      outline: outline,
      outlineVariant: outline,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: onSurface, displayColor: onSurface)
        .copyWith(
          displayLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: onSurface,
            letterSpacing: -0.5,
          ),
          headlineLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: onSurface,
            letterSpacing: -0.5,
          ),
          titleLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          labelMedium: GoogleFonts.firaCode(
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
        );

    return base.copyWith(
      brightness: brightness,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryAccent,
        unselectedItemColor: onSurfaceMuted,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 15),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBackgroundColor: surfaceElevated,
        showDragHandle: true,
        dragHandleColor: onSurfaceMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: onSurfaceMuted),
        labelStyle: TextStyle(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAccent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryAccent,
        labelStyle: GoogleFonts.inter(
            color: onSurface, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.inter(
            color: _darkBackground, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: outline),
        ),
        side: BorderSide(color: outline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: _darkBackground,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: primaryAccent.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryAccent,
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryAccent,
        linearTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(onSurface),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryAccent;
          return outline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

/// Lightweight ergonomics so screens can read theme-aware colors without
/// repeating `Theme.of(context).colorScheme.x`.
extension AppColorsX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  ThemeData get th => Theme.of(this);
  TextTheme get tt => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Gradient hero color: the brand gradient on dark mode, a softer wash on
  /// light mode so backgrounds don't feel neon-bright.
  LinearGradient get heroGradient => isDark
      ? AppTheme.primaryGradient
      : const LinearGradient(
          colors: [Color(0xFF7CFFC4), Color(0xFF6BD0E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  /// Color appropriate for text drawn over the brand gradient.
  Color get onGradient => AppTheme.darkBackground;
}
