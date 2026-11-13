import 'package:material_ui/material_ui.dart';

/// Quy chuẩn khoảng cách, bo góc và kích thước ảnh/avatar toàn ứng dụng.
abstract final class AppSpacing {
  /// Khoảng cách cơ bản.
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  /// Bo góc.
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusPill = 999.0;

  /// Độ dày viền.
  static const double borderThin = 1.0;
  static const double borderSelected = 1.5;

  /// Kích thước ảnh / avatar.
  static const double playerAvatarSize = 40.0;
  static const double playerAvatarSmallSize = 28.0;
  static const double teamAvatarSize = 40.0;
  static const double teamAvatarSmallSize = 32.0;

  /// Kích thước icon.
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 44.0;

  /// Kích thước cột cố định để tránh overflow.
  static const double masterPaneWidth = 380.0;
  static const double slotLabelWidth = 46.0;
  static const double pointsColumnWidth = 60.0;
  static const double rankColumnWidth = 28.0;
  static const double recordColumnWidth = 58.0;
  static const double fptsColumnWidth = 76.0;

  /// EdgeInsets hay dùng.
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
  static const EdgeInsets compactListPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
}
