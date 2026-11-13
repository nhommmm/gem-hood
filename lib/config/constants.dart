/// Múi giờ hiển thị ngày thi đấu NBA trong app.
enum ScheduleTimezone {
  /// Giờ Việt Nam (UTC+7): trận buổi tối Mỹ (ET) diễn ra vào sáng hôm sau tại VN (+1 ngày).
  vietnam,

  /// Giờ Mỹ miền Đông (US Eastern): khớp trực tiếp ngày ghi trong assets/nba_schedule.json.
  usEastern,
}

/// Hằng số cấu hình toàn cục của ứng dụng Gem Hood.
abstract final class AppConstants {
  /// Giá trị mặc định rỗng; người dùng nhập League ID và username qua màn Setup hoặc URL.
  static const String defaultLeagueId = '';
  static const String defaultPriorityUsername = '';

  /// Chu kỳ tự động làm mới dữ liệu ở tab Matchups.
  static const Duration refreshInterval = Duration(seconds: 60);

  /// Thời gian lưu cache danh sách cầu thủ NBA trong SharedPreferences.
  static const Duration cacheDuration = Duration(hours: 24);

  /// Đường dẫn file asset lịch thi đấu NBA tĩnh (chạy offline trong app).
  static const String scheduleAssetPath = 'assets/nba_schedule.json';

  /// Số ngày trong một tuần fantasy.
  static const int schedulePreviewDays = 7;

  /// Độ lệch múi giờ Việt Nam (UTC+7) và giờ Mỹ Eastern (EST UTC-5 / EDT UTC-4).
  static const Duration vietnamUtcOffset = Duration(hours: 7);
  static const Duration easternStdOffset = Duration(hours: -5);
  static const Duration easternDstOffset = Duration(hours: -4);

  /// Múi giờ hiển thị lịch đấu hiện tại của app: Giờ Việt Nam (UTC+7).
  /// Lưu ý: Tuần fantasy Sleeper luôn tính Thứ 2 → Chủ nhật theo giờ Mỹ Eastern (America/New_York),
  /// nên khi hiển thị theo giờ Việt Nam một tuần fantasy sẽ trải từ Thứ 3 → Thứ 2 tuần sau.
  /// Đổi thành [ScheduleTimezone.usEastern] nếu muốn hiển thị theo ngày/giờ Mỹ ET.
  static const ScheduleTimezone scheduleTimezone = ScheduleTimezone.vietnam;

  /// URL gốc của Sleeper API.
  static const String apiBaseUrl = 'https://api.sleeper.app/v1';

  /// URL gốc của Sleeper CDN cho ảnh cầu thủ NBA và avatar người dùng.
  static const String cdnBaseUrl = 'https://sleepercdn.com';

  /// Breakpoint chuyển đổi giữa BottomNavigationBar (mobile) và NavigationRail + Master-Detail (desktop).
  static const double desktopBreakpoint = 800.0;

  /// Tạo URL ảnh đại diện cầu thủ NBA từ [playerId].
  static String playerThumbUrl(String playerId) =>
      '$cdnBaseUrl/content/nba/players/thumb/$playerId.jpg';

  /// Tạo URL avatar người dùng Sleeper từ [avatar] (trả về null nếu rỗng).
  static String? userAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return null;
    }
    return '$cdnBaseUrl/avatars/thumbs/$avatar';
  }
}
