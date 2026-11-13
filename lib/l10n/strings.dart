/// Toàn bộ chuỗi văn bản hiển thị trong ứng dụng để dễ chỉnh sửa hoặc đa ngôn ngữ.
abstract final class AppStrings {
  /// Tên ứng dụng.
  static const String appTitle = 'Gem Hood';
  static const String appShortTitle = 'Gem Hood';

  /// Tên 5 tab điều hướng chính.
  static const String tabMatchups = 'Matchups';
  static const String tabTeams = 'Teams';
  static const String tabStandings = 'Standings';
  static const String tabTrades = 'Trades';
  static const String tabInsights = 'Insights';

  /// Nhãn các nhóm đội hình.
  static const String sectionStarters = 'Starters';
  static const String sectionBench = 'Bench';
  static const String sectionIr = 'IR';

  /// Nhãn hiển thị ở tab Matchups.
  static const String weekPrefix = 'Tuần';
  static const String vsLabel = 'VS';
  static const String byeLabel = 'BYE';
  static const String selectMatchupHint = 'Chọn một cặp đấu để xem chi tiết';
  static const String noMatchups = 'Chưa có cặp đấu cho tuần này';
  static const String matchupDetailTitle = 'Chi tiết cặp đấu';
  static const String emptySlot = 'Trống';

  /// Nhãn hiển thị ở tab Teams.
  static const String selectTeamHint = 'Chọn một đội để xem đội hình';
  static const String noTeams = 'Không tìm thấy đội nào';
  static const String teamDetailTitle = 'Đội hình';
  static const String yourTeamBadge = 'Của bạn';
  static const String noPlayersInGroup = 'Không có cầu thủ';
  static const String freeAgentTeam = 'FA';
  static const String unknownPlayer = 'Cầu thủ';
  static const String unknownPosition = '--';

  /// Nhãn hiển thị ở tab Standings.
  static const String standingsRankHeader = '#';
  static const String standingsTeamHeader = 'Đội';
  static const String standingsRecordHeader = 'W-L';
  static const String standingsFptsHeader = 'FPTS';
  static const String noStandings = 'Chưa có bảng xếp hạng';

  /// Nhãn hiển thị ở tab Trades.
  static const String tradesFilterAll = 'Tất cả';
  static const String tradesFilterPriorityPrefix = 'Chỉ của';
  static const String tradeReceivedLabel = 'Nhận';
  static const String tradeSentLabel = 'Nhường';
  static const String tradePickRoundPrefix = 'Vòng';
  static const String tradePickOriginPrefix = 'từ';
  static const String noTrades = 'Chưa có giao dịch trade nào';
  static const String noPriorityTrades = 'Chưa có trade nào của đội này';
  static const String tradeEmptySide = 'Không có';

  /// Nhãn hiển thị ở tab Insights.
  static const String insightsTopStartersTitle = 'Top 5 Starters cao điểm';
  static const String insightsBottomStartersTitle = 'Top 5 Starters thấp điểm';
  static const String insightsZeroStartersNotePrefix = 'Bỏ qua';
  static const String insightsZeroStartersNoteSuffix =
      'starter 0.00 điểm (chấn thương / chưa đấu)';
  static const String insightsBenchRegretTitle = 'Bench tiếc nuối';
  static const String insightsBenchRegretEmpty =
      'Không có cầu thủ bench nào cao điểm hơn starter tuần này';
  static const String insightsMissedPrefix = 'Bỏ lỡ';
  static const String insightsOverStarterPrefix = 'cao hơn';
  static const String insightsLineupEfficiencyTitle =
      'Lineup hiệu quả nhất tuần';
  static const String insightsBestEfficiencyBadge = 'Hiệu quả #1';
  static const String insightsActualOptimalLabel = 'Thực tế / Tối đa';
  static const String insightsNoData = 'Chưa có dữ liệu phân tích cho tuần này';

  /// Nhãn hiển thị lịch đấu cầu thủ theo tuần fantasy.
  static const String scheduleSectionTitle = 'Lịch tuần fantasy';
  static const String scheduleWeekRangePrefix = 'Tuần fantasy:';
  static const String scheduleTimezoneShortVietnam = 'giờ VN';
  static const String scheduleTimezoneShortEastern = 'giờ Mỹ ET';
  static const String scheduleThisWeek = 'Tuần này';
  static const String scheduleNextWeek = 'Tuần sau';
  static const String schedulePrevWeek = 'Tuần trước';
  static const String scheduleNoGamesInWeek = 'Không có trận tuần này';
  static const String scheduleWeekGamesSuffix = 'trận tuần này';
  static const List<String> scheduleWeekdaysShort = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];
  static const List<String> scheduleWeekdaysFull = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'CN',
  ];

  /// Trạng thái tải dữ liệu và thông báo lỗi.
  static const String loadingMessage = 'Đang tải dữ liệu Sleeper...';
  static const String errorGeneric = 'Không thể tải dữ liệu. Vui lòng thử lại.';
  static const String errorNetwork = 'Lỗi kết nối mạng tới Sleeper API.';
  static const String errorServer = 'Máy chủ Sleeper phản hồi lỗi.';
  static const String errorParse = 'Dữ liệu trả về không đúng định dạng.';
  static const String retryButton = 'Thử lại';
  static const String refreshTooltip = 'Làm mới';

  /// Màn hình Setup & đổi league.
  static const String setupTitle = 'Thiết lập giải đấu';
  static const String setupSubtitle =
      'Nhập Sleeper League ID để xem matchup, đội hình, bảng xếp hạng và lịch đấu NBA.';
  static const String setupLeagueIdLabel = 'League ID (bắt buộc)';
  static const String setupLeagueIdHint = 'Ví dụ: 1234567890123456789';
  static const String setupLeagueIdHelp =
      'Lấy từ đường dẫn giải trên Sleeper: sleeper.com/leagues/<league_id>';
  static const String setupUsernameLabel = 'Sleeper username ưu tiên (tùy chọn)';
  static const String setupUsernameHint = 'Để trống nếu không cần ghim đội';
  static const String setupSubmitButton = 'Vào giải đấu';
  static const String setupValidatingButton = 'Đang kiểm tra...';
  static const String setupCancelButton = 'Hủy';
  static const String setupLeagueIdRequired = 'Vui lòng nhập Sleeper League ID.';
  static const String setupLeagueNotFound =
      'Không tìm thấy giải đấu với League ID này. Vui lòng kiểm tra lại.';
  static const String changeLeagueLabel = 'Đổi league';
}
