import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Tập hợp toàn bộ TextStyle dùng trong ứng dụng.
abstract final class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.accent,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle scoreLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle scoreLargeWinner = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.win,
  );

  static const TextStyle scoreMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle badgeInverse = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.onAccent,
  );

  static const TextStyle avatarInitial = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
  );
}
