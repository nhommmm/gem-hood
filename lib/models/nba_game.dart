import '../config/constants.dart';
import '../config/team_codes.dart';

/// Một trận đấu NBA từ assets/nba_schedule.json (thuần dữ liệu, không import UI).
class NbaGame {
  const NbaGame({
    required this.startUtc,
    required this.etDate,
    required this.homeTeam,
    required this.awayTeam,
  });

  /// Thời điểm bắt đầu trận đấu theo UTC.
  final DateTime startUtc;

  /// Ngày thi đấu theo giờ Mỹ Eastern (date-only UTC YYYY-MM-DD, đã xử lý DST).
  final DateTime etDate;

  /// Mã đội chủ nhà đã chuẩn hóa theo Sleeper.
  final String homeTeam;

  /// Mã đội khách đã chuẩn hóa theo Sleeper.
  final String awayTeam;

  factory NbaGame.fromJson(Map<String, dynamic> json) {
    final utcRaw = (json['utc'] ?? '').toString().trim();
    DateTime? parsedUtc = utcRaw.isNotEmpty ? DateTime.tryParse(utcRaw)?.toUtc() : null;

    if (parsedUtc == null) {
      final dateStr = (json['date'] ?? '').toString().trim();
      final parts = dateStr.split('-');
      final year = parts.length == 3 ? int.tryParse(parts[0]) ?? 2026 : 2026;
      final month = parts.length == 3 ? int.tryParse(parts[1]) ?? 1 : 1;
      final day = parts.length == 3 ? int.tryParse(parts[2]) ?? 1 : 1;
      // Fallback 19:00 EST = 00:00 UTC hôm sau nếu thiếu trường utc.
      parsedUtc = DateTime.utc(year, month, day, 24);
    }

    final easternDt = toUsEastern(parsedUtc);
    final etDateOnly = DateTime.utc(
      easternDt.year,
      easternDt.month,
      easternDt.day,
    );

    return NbaGame(
      startUtc: parsedUtc,
      etDate: etDateOnly,
      homeTeam: TeamCodes.normalize((json['home'] ?? '').toString()),
      awayTeam: TeamCodes.normalize((json['away'] ?? '').toString()),
    );
  }

  /// Ngày Thứ 2 bắt đầu tuần fantasy Sleeper (theo giờ Mỹ Eastern).
  DateTime get fantasyWeekStartEt =>
      etDate.subtract(Duration(days: etDate.weekday - 1));

  /// Đổi giờ bắt đầu trận đấu sang múi giờ cấu hình trong [AppConstants.scheduleTimezone].
  DateTime displayDateTime(ScheduleTimezone timezone) {
    switch (timezone) {
      case ScheduleTimezone.vietnam:
        return startUtc.add(AppConstants.vietnamUtcOffset);
      case ScheduleTimezone.usEastern:
        return toUsEastern(startUtc);
    }
  }

  /// Ngày hiển thị (date-only) theo múi giờ cấu hình.
  DateTime displayDate(ScheduleTimezone timezone) {
    final dt = displayDateTime(timezone);
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  /// Trận đấu đã bắt đầu/diễn ra tính đến [nowUtc] hay chưa.
  bool hasStarted(DateTime nowUtc) => !nowUtc.isBefore(startUtc);

  /// Kiểm tra trận đấu có sự góp mặt của [teamCode] hay không.
  bool involves(String teamCode) {
    final normalized = TeamCodes.normalize(teamCode);
    return homeTeam == normalized || awayTeam == normalized;
  }

  /// Trả về true nếu [teamCode] đá sân nhà.
  bool isHome(String teamCode) => homeTeam == TeamCodes.normalize(teamCode);

  /// Trả về mã đội đối thủ của [teamCode].
  String opponentOf(String teamCode) {
    final normalized = TeamCodes.normalize(teamCode);
    return homeTeam == normalized ? awayTeam : homeTeam;
  }

  /// Chuyển thời điểm UTC sang America/New_York (xử lý đổi giờ mùa hè EDT/EST).
  static DateTime toUsEastern(DateTime utc) {
    final u = utc.toUtc();
    final year = u.year;
    // Chủ nhật thứ 2 của tháng 3 (2:00 AM EST = 07:00 UTC).
    final marchFirst = DateTime.utc(year, 3, 1);
    final firstSundayOffset = (DateTime.sunday - marchFirst.weekday) % 7;
    final dstStart = DateTime.utc(year, 3, 1 + firstSundayOffset + 7, 7);

    // Chủ nhật đầu tiên của tháng 11 (2:00 AM EDT = 06:00 UTC).
    final novFirst = DateTime.utc(year, 11, 1);
    final novSundayOffset = (DateTime.sunday - novFirst.weekday) % 7;
    final dstEnd = DateTime.utc(year, 11, 1 + novSundayOffset, 6);

    final isDst = !u.isBefore(dstStart) && u.isBefore(dstEnd);
    return u.add(
      isDst ? AppConstants.easternDstOffset : AppConstants.easternStdOffset,
    );
  }
}

/// Một trận đấu đã định dạng cho dòng lịch của cầu thủ (thuần dữ liệu).
class PlayerScheduledGame {
  const PlayerScheduledGame({
    required this.label,
    required this.isPast,
  });

  final String label;
  final bool isPast;
}

/// Lịch thi đấu trong tuần fantasy đang chọn của một cầu thủ (thuần dữ liệu).
class PlayerWeekSchedule {
  const PlayerWeekSchedule({required this.games});

  final List<PlayerScheduledGame> games;

  int get count => games.length;
  bool get isEmpty => games.isEmpty;
}

/// Số lượng cầu thủ của đội có trận đấu trong một ngày cụ thể (thuần dữ liệu).
class ScheduleDayCount {
  const ScheduleDayCount({
    required this.date,
    required this.playerCount,
  });

  final DateTime date;
  final int playerCount;
}
