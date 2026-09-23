import 'package:flutter/material.dart';

class AppColors {
  // ---------- PRIMARY ----------
  static const Color primary = Color(0xFF0056D2);
  static const Color primaryDark = Color(0xFF003D96);

  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryDark = Color.fromARGB(255, 56, 192, 255);

  // ---------- LIGHT ----------
  static const Color backgroundLight = Color(0xFFF8FAFC); 
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color.fromARGB(255, 178, 183, 192);

  static const Color textPrimaryLight = Color(0xFF0F172A); 
  static const Color textSecondaryLight = Color.fromARGB(255, 60, 60, 60);

  // ---------- DARK ----------
  static const Color backgroundDark = Color(0xFF0B1220); 
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);

  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ---------- STATUS ----------
  static const Color statusLow = Color(0xFFDC2626); 
  static const Color statusWarning = Color(0xFFF59E0B); 
  static const Color statusGood = Color(0xFF059669);
  static const Color statusOptimal = Color(0xFF065F46);
}

class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.statusLow,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
      shadow: Colors.black54,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ---------- TEXT ----------
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
          color: AppColors.textPrimaryLight,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimaryLight),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryLight,
        ),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
      ),

      // ---------- APP BAR ----------
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),

      // ---------- CARD ----------
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 4,
        shadowColor: colorScheme.shadow,
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderLight, width: 0.6),
        ),
      ),

      // ---------- CHIP ----------
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        disabledColor: AppColors.borderLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: StadiumBorder(
          side: const BorderSide(color: AppColors.borderLight),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ---------- FAB ----------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
      ),

      // ---------- BOTTOM NAV ----------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 6,
      ),

      // ---------- BOTTOM SHEET ----------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ---------- INPUT ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
        prefixIconColor: AppColors.textSecondaryLight,
      ),

      // ---------- DIVIDER ----------
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 0.7,
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.surfaceDark,
      error: AppColors.statusLow,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
      shadow: Colors.white54,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ---------- TEXT ----------
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimaryDark),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimaryDark),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
      ),

      // ---------- CARD ----------
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderDark, width: 0.6),
        ),
        shadowColor: colorScheme.shadow,
      ),

      // ---------- CHIP ----------
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        disabledColor: AppColors.borderDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),

      // ---------- FAB ----------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 3,
      ),

      // ---------- BOTTOM SHEET ----------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ---------- INPUT ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIconColor: AppColors.textSecondaryDark,
      ),

      // ---------- DIVIDER ----------
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.7,
      ),

      // ---------- BOTTOM NAV ----------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: Color.fromARGB(255, 56, 192, 255),
        unselectedItemColor: AppColors.borderLight,
        type: BottomNavigationBarType.fixed,
        elevation: 6,
      ),

      // ---------- APP BAR ----------
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
    );
  }

  static InputDecoration inputDecoration({
    required String hint,
    bool alignLabelWithHint = true,
    Icon? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      errorStyle: const TextStyle(height: 0),
      hintStyle: TextStyle(color: Color(0xFF8E9199)),
      prefixIcon: prefixIcon,
      errorBorder: borderHelper(radius: 16, color: Colors.red),
      focusedErrorBorder: borderHelper(radius: 16, color: Colors.red),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  static OutlineInputBorder borderHelper({
    required double radius,
    required Color color,
    double width = 1.0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static BoxDecoration bottomSheetDecor(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Color(0xFFF8FAFC),
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    );
  }
}
