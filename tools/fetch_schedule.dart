import 'dart:convert';
import 'dart:io';

import 'package:gem_hood/config/team_codes.dart';

/// Standalone CLI script to download the NBA regular-season schedule (with UTC tip-off times)
/// into `assets/nba_schedule.json`.
///
/// Usage (run from the project root):
///   dart run tools/fetch_schedule.dart
///
/// How it works:
///   1. Tries the official NBA CDN (`scheduleLeagueV2.json`) first.
///   2. Falls back to ESPN Scoreboard API across the configured season window.
///   3. Converts UTC tip-offs to US Eastern (`America/New_York`, handling EDT/EST DST),
///      filters out `TBD` entries, deduplicates, sorts by UTC, and verifies all 30 team codes
///      against Sleeper's `/v1/players/nba` endpoint.
///
/// Last fetched `assets/nba_schedule.json`: 2026-11-13 (2026-27 NBA season).
Future<void> main() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);

  try {
    stdout.writeln('Đang thử nguồn (a): NBA CDN scheduleLeagueV2.json...');
    final nbaCdnGames = await _tryFetchNbaCdn(client);
    if (nbaCdnGames != null && nbaCdnGames.isNotEmpty) {
      await _saveAndVerify(client, nbaCdnGames, sourceName: 'NBA CDN');
      return;
    }

    stdout.writeln(
      'Nguồn (a) không khả dụng. Đang chuyển sang nguồn (b): ESPN Scoreboard API...',
    );

    // Mùa giải NBA 2026-27: từ 2026-10-20 đến 2027-04-15 (giờ Mỹ Eastern).
    final startDate = DateTime.utc(2026, 10, 20);
    final endDate = DateTime.utc(2027, 4, 15);
    final espnGames = await _tryFetchEspnRange(client, startDate, endDate);

    if (espnGames.isEmpty) {
      stderr.writeln(
        'LỖI: Cả hai nguồn NBA CDN và ESPN đều thất bại hoặc không có dữ liệu.',
      );
      exitCode = 1;
      return;
    }

    await _saveAndVerify(client, espnGames, sourceName: 'ESPN API');
  } finally {
    client.close(force: true);
  }
}

/// Đổi UTC sang giờ America/New_York (xử lý DST: EDT UTC-4, EST UTC-5).
DateTime _toUsEastern(DateTime utc) {
  final u = utc.toUtc();
  final year = u.year;
  final marchFirst = DateTime.utc(year, 3, 1);
  final firstSundayOffset = (DateTime.sunday - marchFirst.weekday) % 7;
  final dstStart = DateTime.utc(year, 3, 1 + firstSundayOffset + 7, 7);

  final novFirst = DateTime.utc(year, 11, 1);
  final novSundayOffset = (DateTime.sunday - novFirst.weekday) % 7;
  final dstEnd = DateTime.utc(year, 11, 1 + novSundayOffset, 6);

  final isDst = !u.isBefore(dstStart) && u.isBefore(dstEnd);
  return u.subtract(Duration(hours: isDst ? 4 : 5));
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _fmtVnDateTime(DateTime utc) {
  final vn = utc.toUtc().add(const Duration(hours: 7));
  const weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
  final wd = weekdays[vn.weekday - 1];
  final hh = vn.hour.toString().padLeft(2, '0');
  final mm = vn.minute.toString().padLeft(2, '0');
  final dd = vn.day.toString().padLeft(2, '0');
  final mo = vn.month.toString().padLeft(2, '0');
  return '$hh:$mm $wd $dd/$mo';
}

Future<List<Map<String, String>>?> _tryFetchNbaCdn(HttpClient client) async {
  try {
    final uri = Uri.parse(
      'https://cdn.nba.com/static/json/staticData/scheduleLeagueV2.json',
    );
    final req = await client.getUrl(uri);
    req.headers.set('User-Agent', 'Mozilla/5.0');
    req.headers.set('Referer', 'https://www.nba.com/');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      stdout.writeln('NBA CDN trả về HTTP ${res.statusCode}');
      return null;
    }
    final body = await res.transform(utf8.decoder).join();
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final leagueSchedule =
        jsonMap['leagueSchedule'] as Map<String, dynamic>? ?? const {};
    final gameDates =
        leagueSchedule['gameDates'] as List<dynamic>? ?? const [];

    final games = <Map<String, String>>[];
    for (final dayEntry in gameDates) {
      if (dayEntry is! Map<String, dynamic>) continue;
      final rawGames = dayEntry['games'] as List<dynamic>? ?? const [];
      for (final g in rawGames) {
        if (g is! Map<String, dynamic>) continue;
        final utcRaw = (g['gameDateTimeUTC'] ?? '').toString().trim();
        if (utcRaw.isEmpty) continue;
        final utcDt = DateTime.tryParse(utcRaw)?.toUtc();
        if (utcDt == null) continue;
        final etDate = _fmtDate(_toUsEastern(utcDt));
        final home = ((g['homeTeam'] as Map<String, dynamic>?)?['teamTricode'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        final away = ((g['awayTeam'] as Map<String, dynamic>?)?['teamTricode'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        if (home.isNotEmpty && away.isNotEmpty) {
          games.add({
            'utc': utcDt.toIso8601String(),
            'date': etDate,
            'home': home,
            'away': away,
          });
        }
      }
    }
    return games;
  } catch (e) {
    stdout.writeln('NBA CDN lỗi: $e');
    return null;
  }
}

Future<List<Map<String, String>>> _tryFetchEspnRange(
  HttpClient client,
  DateTime startDate,
  DateTime endDate,
) async {
  final dates = <DateTime>[];
  for (var d = startDate;
      !d.isAfter(endDate);
      d = d.add(const Duration(days: 1))) {
    dates.add(d);
  }

  final games = <Map<String, String>>[];
  const batchSize = 16;

  for (var i = 0; i < dates.length; i += batchSize) {
    final batch = dates.sublist(
      i,
      i + batchSize > dates.length ? dates.length : i + batchSize,
    );
    final batchResults = await Future.wait(
      batch.map((d) => _fetchEspnDay(client, d)),
    );
    for (final dayGames in batchResults) {
      games.addAll(dayGames);
    }
    stdout.write(
      '\rĐã tải ${i + batch.length}/${dates.length} ngày từ ESPN (${games.length} trận)...',
    );
  }
  stdout.writeln('');
  return games;
}

Future<List<Map<String, String>>> _fetchEspnDay(
  HttpClient client,
  DateTime date,
) async {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final yyyymmdd = '$y$m$d';

  try {
    final uri = Uri.parse(
      'https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard?dates=$yyyymmdd',
    );
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      return const [];
    }
    final body = await res.transform(utf8.decoder).join();
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final events = jsonMap['events'] as List<dynamic>? ?? const [];

    final dayGames = <Map<String, String>>[];
    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;
      final utcRaw = (event['date'] ?? '').toString().trim();
      final utcDt = DateTime.tryParse(utcRaw)?.toUtc();
      if (utcDt == null) continue;
      final etDate = _fmtDate(_toUsEastern(utcDt));

      final competitions = event['competitions'] as List<dynamic>? ?? const [];
      if (competitions.isEmpty) continue;
      final comp = competitions.first as Map<String, dynamic>;
      final competitors = comp['competitors'] as List<dynamic>? ?? const [];

      String home = '';
      String away = '';
      for (final c in competitors) {
        if (c is! Map<String, dynamic>) continue;
        final side = (c['homeAway'] ?? '').toString();
        final team = c['team'] as Map<String, dynamic>? ?? const {};
        final abbr = (team['abbreviation'] ?? '').toString().trim().toUpperCase();
        if (side == 'home') {
          home = abbr;
        } else if (side == 'away') {
          away = abbr;
        }
      }
      if (home.isNotEmpty && away.isNotEmpty) {
        dayGames.add({
          'utc': utcDt.toIso8601String(),
          'date': etDate,
          'home': home,
          'away': away,
        });
      }
    }
    return dayGames;
  } catch (_) {
    return const [];
  }
}

Future<void> _saveAndVerify(
  HttpClient client,
  List<Map<String, String>> games, {
  required String sourceName,
}) async {
  // Khử trùng lặp, bỏ TBD và sắp xếp theo giờ UTC tăng dần.
  final seen = <String>{};
  final deduped = <Map<String, String>>[];
  for (final g in games) {
    final home = g['home']!;
    final away = g['away']!;
    if (!TeamCodes.isValidTeam(home) || !TeamCodes.isValidTeam(away)) {
      continue;
    }
    final key = '${g['date']}_${home}_$away';
    if (seen.add(key)) {
      deduped.add(g);
    }
  }
  deduped.sort((a, b) => a['utc']!.compareTo(b['utc']!));

  final outDir = Directory('assets');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final file = File('assets/nba_schedule.json');
  await file.writeAsString(jsonEncode(deduped));
  stdout.writeln(
    'THÀNH CÔNG: Đã lưu ${deduped.length} trận từ nguồn [$sourceName] vào assets/nba_schedule.json',
  );

  _verifyScheduleIntegrity(deduped);
  await _verifyWithSleeper(client, deduped);
}

void _verifyScheduleIntegrity(List<Map<String, String>> games) {
  // 1. Kiểm tra không đội nào có 2 trận cùng ngày Eastern.
  final teamEtGames = <String, int>{};
  final duplicates = <String>[];
  var outsideTueToMonVn = 0;

  for (final g in games) {
    final etDate = g['date']!;
    final utcDt = DateTime.parse(g['utc']!).toUtc();
    final etDt = _toUsEastern(utcDt);
    final etWeekStart = DateTime.utc(etDt.year, etDt.month, etDt.day)
        .subtract(Duration(days: etDt.weekday - 1));
    final vnDt = utcDt.add(const Duration(hours: 7));
    final vnDateOnly = DateTime.utc(vnDt.year, vnDt.month, vnDt.day);
    final vnDiff = vnDateOnly.difference(etWeekStart).inDays;
    if (vnDiff < 1 || vnDiff > 7) {
      outsideTueToMonVn++;
    }

    final home = TeamCodes.normalize(g['home']!);
    final away = TeamCodes.normalize(g['away']!);
    for (final team in [home, away]) {
      final key = '${team}_$etDate';
      teamEtGames[key] = (teamEtGames[key] ?? 0) + 1;
      if (teamEtGames[key]! > 1) {
        duplicates.add('$team @ $etDate');
      }
    }
  }

  stdout.writeln(
    'Kiểm tra trùng trận cùng ngày Eastern: ${duplicates.isEmpty ? "KHÔNG CÓ (OK)" : duplicates.join(', ')}',
  );
  stdout.writeln(
    'Trận rơi ngoài khung Thứ 3 → Thứ 2 (VN) trong tuần fantasy: $outsideTueToMonVn',
  );

  // 2. In tuần hiện tại & tuần sau cho LAL, TOR, NYK, GSW.
  final nowEt = _toUsEastern(DateTime.now().toUtc());
  final thisWeekStart = DateTime.utc(nowEt.year, nowEt.month, nowEt.day)
      .subtract(Duration(days: nowEt.weekday - 1));
  final nextWeekStart = thisWeekStart.add(const Duration(days: 7));

  for (final label in [
    ('TUẦN HIỆN TẠI', thisWeekStart),
    ('TUẦN SAU', nextWeekStart),
  ]) {
    final weekEnd = label.$2.add(const Duration(days: 6));
    stdout.writeln(
      '\n--- ${label.$1} (${_fmtDate(label.$2)} .. ${_fmtDate(weekEnd)} ET) ---',
    );
    for (final target in ['LAL', 'TOR', 'NYK', 'GSW']) {
      final matched = games.where((g) {
        final home = TeamCodes.normalize(g['home']!);
        final away = TeamCodes.normalize(g['away']!);
        if (home != target && away != target) return false;
        final d = DateTime.parse('${g['date']}T00:00:00Z');
        return !d.isBefore(label.$2) && !d.isAfter(weekEnd);
      }).toList();

      stdout.writeln('  $target (${matched.length} trận):');
      for (final g in matched) {
        final home = TeamCodes.normalize(g['home']!);
        final away = TeamCodes.normalize(g['away']!);
        final vsText = home == target ? 'vs $away' : '@ $home';
        final utcDt = DateTime.parse(g['utc']!);
        stdout.writeln(
          '    - ET: ${g['date']} | VN: ${_fmtVnDateTime(utcDt)} | $vsText',
        );
      }
    }
  }
}

Future<void> _verifyWithSleeper(
  HttpClient client,
  List<Map<String, String>> games,
) async {
  final normalizedScheduleTeams = <String>{};
  for (final g in games) {
    normalizedScheduleTeams.add(TeamCodes.normalize(g['home']!));
    normalizedScheduleTeams.add(TeamCodes.normalize(g['away']!));
  }

  try {
    final uri = Uri.parse('https://api.sleeper.app/v1/players/nba');
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      stdout.writeln('Không tải được Sleeper players/nba để đối chiếu.');
      return;
    }
    final body = await res.transform(utf8.decoder).join();
    final players = jsonDecode(body) as Map<String, dynamic>;
    final sleeperTeams = <String>{};
    for (final value in players.values) {
      if (value is Map<String, dynamic>) {
        final t = value['team']?.toString().trim().toUpperCase();
        if (t != null && t.isNotEmpty) {
          sleeperTeams.add(t);
        }
      }
    }
    final unmatched = sleeperTeams
        .where((t) => !normalizedScheduleTeams.contains(TeamCodes.normalize(t)))
        .toList()
      ..sort();
    stdout.writeln(
      '\nĐối chiếu Sleeper (${sleeperTeams.length} đội): ${unmatched.isEmpty ? "30/30 KHỚP HOÀN TOÀN" : "Chưa khớp: ${unmatched.join(', ')}"}',
    );
  } catch (e) {
    stdout.writeln('Lỗi đối chiếu Sleeper: $e');
  }
}
