import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Dựng ThemeData chính thức từ AppColors, AppTextStyles và AppSpacing.
abstract final class AppTheme {
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      error: AppColors.loss,
      onError: AppColors.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appTitle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(
            color: AppColors.border,
            width: AppSpacing.borderThin,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSpacing.borderThin,
        space: AppSpacing.borderThin,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.card,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.surfaceElevated,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.buttonLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.caption,
        secondaryLabelStyle: AppTextStyles.badge.copyWith(
          color: AppColors.onPrimary,
        ),
        side: const BorderSide(
          color: AppColors.border,
          width: AppSpacing.borderThin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
      ),
    );
  }
}
