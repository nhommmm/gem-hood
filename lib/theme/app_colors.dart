import 'package:material_ui/material_ui.dart';

/// Bảng màu toàn cục của ứng dụng (Dark mode).
abstract final class AppColors {
  /// Màu nền chính.
  static const Color background = Color(0xFF181C28);

  /// Màu nền thẻ Card.
  static const Color card = Color(0xFF222634);

  /// Màu nền phụ cho chip, slot badge hoặc avatar fallback.
  static const Color surfaceElevated = Color(0xFF2C3144);

  /// Màu viền và đường phân cách.
  static const Color border = Color(0xFF343A4F);

  /// Màu nhấn chính (cam).
  static const Color primary = Color(0xFFFF6B00);

  /// Màu nhấn phụ (xanh ngọc).
  static const Color accent = Color(0xFF00E5BF);

  /// Màu chữ chính.
  static const Color textPrimary = Color(0xFFF4F6FA);

  /// Màu chữ phụ.
  static const Color textSecondary = Color(0xFF9AA3B8);

  /// Màu chữ mờ.
  static const Color textMuted = Color(0xFF6D768E);

  /// Màu chữ trên nền cam/accent.
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onAccent = Color(0xFF0F172A);

  /// Màu thắng / thua.
  static const Color win = Color(0xFF00E5BF);
  static const Color loss = Color(0xFFFF5252);
  static const Color neutral = Color(0xFF9AA3B8);

  /// Màu trạng thái chấn thương.
  static const Color injurySevere = Color(0xFFFF5252); // Out, IR, SUS
  static const Color injuryMild = Color(0xFFFFB020); // DTD, Q, Doubtful
  static const Color injuryText = Color(0xFFFFFFFF);

  /// Màu nền trong suốt.
  static const Color transparent = Colors.transparent;
}
