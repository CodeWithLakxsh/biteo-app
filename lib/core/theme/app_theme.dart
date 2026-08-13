// =============================================================
// lib/core/theme/app_theme.dart
// THE single source of truth for every color, style, and spacing
// in the Biteo app. Never hardcode a hex value anywhere else.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Biteo's Gourmet Color Palette.
/// Every value here maps directly to our approved design schema.
abstract class AppColors {
  // ── Primary: Electric Coral ─────────────────────────────
  static const Color electricCoral = Color(0xFFFF6B6B);
  static const Color coralLight    = Color(0xFFFF9191);
  static const Color coralDark     = Color(0xFFE05252);
  static const Color coralSurface  = Color(0xFFFFF0F0); // tinted backgrounds

  // ── Neutrals ────────────────────────────────────────────
  static const Color warmOffWhite  = Color(0xFFFBFBFB);
  static const Color deepCharcoal  = Color(0xFF1A1A1A);
  static const Color charcoalMid   = Color(0xFF3D3D3D);
  static const Color mutedGrey     = Color(0xFF8A8A8A);
  static const Color softGrey      = Color(0xFFB8B8B8);
  static const Color dividerGrey   = Color(0xFFEEEEEE);
  static const Color backgroundGrey= Color(0xFFF5F5F5);
  static const Color cardWhite     = Color(0xFFFFFFFF);

  // ── Semantic ────────────────────────────────────────────
  static const Color success       = Color(0xFF27AE60);
  static const Color successLight  = Color(0xFFEBF9F1);
  static const Color warning       = Color(0xFFF39C12);
  static const Color error         = Color(0xFFE74C3C);
  static const Color errorLight    = Color(0xFFFDEDEB);

  // ── Food Domain ─────────────────────────────────────────
  static const Color vegGreen      = Color(0xFF2ECC71);  // veg indicator
  static const Color nonVegMaroon  = Color(0xFFC0392B);  // non-veg indicator

  // ── UI Support Additions (To fix Home Screen errors) ────
  static const Color background     = warmOffWhite; 
  static const Color cardBackground = cardWhite;    
  static const Color grey100        = Color(0xFFF1F3F5);
  static const Color grey200        = Color(0xFFE9ECEF);
  static const Color grey300        = Color(0xFFDEE2E6);
  static const Color grey400        = Color(0xFFCED4DA);
  static const Color grey500        = Color(0xFFADB5BD);
  static const Color grey600        = Color(0xFF868E96);
  static const Color grey700        = Color(0xFF495057);
}

/// All text styles use Poppins, fetched via google_fonts.
/// Named with the Material 3 type scale convention.
abstract class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 34, fontWeight: FontWeight.w800,
    color: AppColors.deepCharcoal, height: 1.15, letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.deepCharcoal, height: 1.2,
  );

  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.deepCharcoal,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.deepCharcoal,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.deepCharcoal,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.deepCharcoal,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.charcoalMid,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.mutedGrey,
  );

  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.cardWhite, letterSpacing: 0.3,
  );

  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.mutedGrey,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w400,
    color: AppColors.mutedGrey, letterSpacing: 0.2,
  );

  // ── Typography Support (Added for Home Feed components) ──
  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.deepCharcoal,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.deepCharcoal,
  );
}

/// The root ThemeData object. Passed into MaterialApp.router's `theme`.
class AppTheme {
  AppTheme._(); // Private constructor — never instantiated.

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary:    AppColors.electricCoral,
        onPrimary:  AppColors.cardWhite,
        secondary:  AppColors.deepCharcoal,
        onSecondary:AppColors.cardWhite,
        surface:    AppColors.warmOffWhite,
        onSurface:  AppColors.deepCharcoal,
        error:      AppColors.error,
        onError:    AppColors.cardWhite,
      ),
      scaffoldBackgroundColor: AppColors.warmOffWhite,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // ── AppBar ──────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmOffWhite,
        foregroundColor: AppColors.deepCharcoal,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.dividerGrey,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.deepCharcoal,
        ),
        iconTheme: const IconThemeData(color: AppColors.deepCharcoal, size: 22),
      ),

      // ── ElevatedButton (primary CTA) ────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricCoral,
          foregroundColor: AppColors.cardWhite,
          disabledBackgroundColor: AppColors.coralLight.withOpacity(0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton (secondary CTA) ──────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricCoral,
          side: const BorderSide(color: AppColors.electricCoral, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ──────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricCoral,
          textStyle: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration (TextFormField) ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electricCoral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.softGrey, fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.mutedGrey,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11, color: AppColors.error,
        ),
      ),

      // ── Card ────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.dividerGrey, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ── BottomSheet ─────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
      ),

      // ── SnackBar ────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepCharcoal,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 13, color: AppColors.cardWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
      ),

      // ── Divider ─────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerGrey,
        thickness: 1,
        space: 1,
      ),
    );
  }
}