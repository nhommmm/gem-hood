import 'dart:convert';

import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../config/team_codes.dart';
import '../models/nba_game.dart';

/// Dịch vụ đọc lịch thi đấu NBA tĩnh từ assets/nba_schedule.json (không gọi mạng).
class ScheduleService {
  List<NbaGame> _games = const [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Đọc và parse lịch từ [AppConstants.scheduleAssetPath] (chỉ đọc 1 lần).
  Future<void> loadSchedule() async {
    if (_isLoaded) {
      return;
    }
    try {
      final rawJson = await rootBundle.loadString(AppConstants.scheduleAssetPath);
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      _games = decoded
          .whereType<Map<String, dynamic>>()
          .map(NbaGame.fromJson)
          .where(
            (g) =>
                TeamCodes.isValidTeam(g.homeTeam) &&
                TeamCodes.isValidTeam(g.awayTeam),
          )
          .toList(growable: false);
    } catch (_) {
      _games = const [];
    } finally {
      _isLoaded = true;
    }
  }

  /// Trả về ngày Thứ 2 (date-only) bắt đầu tuần fantasy hiện tại theo giờ Mỹ Eastern.
  DateTime currentFantasyWeekStartEt([DateTime? nowUtc]) {
    final eastern = NbaGame.toUsEastern((nowUtc ?? DateTime.now()).toUtc());
    final etDateOnly = DateTime.utc(eastern.year, eastern.month, eastern.day);
    return etDateOnly.subtract(Duration(days: etDateOnly.weekday - 1));
  }

  /// Danh sách 7 ngày hiển thị của một tuần fantasy [weekStartEt].
  /// Theo giờ VN: Thứ 3 (weekStartEt + 1) → Thứ 2 tuần sau (weekStartEt + 7).
  /// Theo giờ ET: Thứ 2 (weekStartEt) → Chủ nhật (weekStartEt + 6).
  List<DateTime> displayDaysForFantasyWeek(
    DateTime weekStartEt, [
    ScheduleTimezone timezone = AppConstants.scheduleTimezone,
  ]) {
    final startOffset = timezone == ScheduleTimezone.vietnam ? 1 : 0;
    return List<DateTime>.generate(
      AppConstants.schedulePreviewDays,
      (i) => weekStartEt.add(Duration(days: startOffset + i)),
      growable: false,
    );
  }

  /// Trả về toàn bộ trận của [teamCode] trong tuần fantasy [weekStartEt] (sắp xếp theo giờ UTC).
  List<NbaGame> getGamesForTeamInFantasyWeek({
    required String teamCode,
    required DateTime weekStartEt,
  }) {
    if (!_isLoaded || teamCode.trim().isEmpty) {
      return const [];
    }
    final normalized = TeamCodes.normalize(teamCode);
    final matches = _games
        .where(
          (game) =>
              game.involves(normalized) &&
              game.fantasyWeekStartEt == weekStartEt,
        )
        .toList();
    matches.sort((a, b) => a.startUtc.compareTo(b.startUtc));
    return matches;
  }
}
