import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../l10n/strings.dart';
import '../models/league.dart';
import '../models/matchup.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/trade.dart';

/// Ngoại lệ chuẩn hóa khi gọi Sleeper API thất bại.
class SleeperApiException implements Exception {
  const SleeperApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class _PlayerParseArgs {
  const _PlayerParseArgs(this.rawJson, this.targetIds);

  final String rawJson;
  final Set<String> targetIds;
}

/// Hàm top-level chạy trong isolate (compute) để lọc và parse file NBA players nặng.
Map<String, Player> _parseFilteredPlayers(_PlayerParseArgs args) {
  final decoded = jsonDecode(args.rawJson) as Map<String, dynamic>;
  final result = <String, Player>{};

  for (final id in args.targetIds) {
    final rawPlayer = decoded[id];
    if (rawPlayer is Map<String, dynamic>) {
      result[id] = Player.fromJson(id, rawPlayer);
    }
  }
  return result;
}

/// Dịch vụ gọi Sleeper API (read-only, không chứa code UI).
class SleeperApi {
  SleeperApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _defaultTimeout = Duration(seconds: 20);
  static const Duration _playersTimeout = Duration(seconds: 60);

  /// Lấy tuần hiện tại của NBA từ /state/nba (ưu tiên leg, fallback week).
  Future<int?> fetchCurrentNbaWeek() async {
    final data = await _getJson('/state/nba') as Map<String, dynamic>;
    final rawLeg = data['leg'];
    if (rawLeg is num && rawLeg.toInt() > 0) {
      return rawLeg.toInt();
    }
    final rawWeek = data['week'];
    if (rawWeek is num && rawWeek.toInt() > 0) {
      return rawWeek.toInt();
    }
    return null;
  }

  /// Lấy thông tin giải đấu (roster_positions, settings...).
  Future<League> fetchLeague(String leagueId) async {
    final trimmedId = leagueId.trim();
    if (trimmedId.isEmpty) {
      throw const SleeperApiException(AppStrings.setupLeagueIdRequired);
    }
    final data = await _getJson('/league/$trimmedId');
    if (data is! Map<String, dynamic>) {
      throw const SleeperApiException(AppStrings.setupLeagueNotFound);
    }
    final league = League.fromJson(data);
    if (league.leagueId.isEmpty) {
      throw const SleeperApiException(AppStrings.setupLeagueNotFound);
    }
    return league;
  }

  /// Lấy và ghép danh sách đội từ /users và /rosters.
  Future<List<Team>> fetchTeams(String leagueId) async {
    final responses = await Future.wait<dynamic>([
      _getJson('/league/$leagueId/users'),
      _getJson('/league/$leagueId/rosters'),
    ]);

    final rawUsers = responses[0] as List<dynamic>;
    final rawRosters = responses[1] as List<dynamic>;

    final usersById = <String, Map<String, dynamic>>{};
    for (final item in rawUsers) {
      if (item is Map<String, dynamic>) {
        final userId = item['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          usersById[userId] = item;
        }
      }
    }

    final teams = <Team>[];
    for (final item in rawRosters) {
      if (item is Map<String, dynamic>) {
        final ownerId = item['owner_id']?.toString();
        final userJson = ownerId != null ? usersById[ownerId] : null;
        teams.add(Team.fromRosterAndUser(rosterJson: item, userJson: userJson));
      }
    }
    return teams;
  }

  /// Lấy các cặp đấu của [week], bỏ qua matchup_id null và nhóm theo cặp.
  Future<List<MatchupPair>> fetchMatchups({
    required String leagueId,
    required int week,
    required Map<int, Team> teamsByRosterId,
  }) async {
    final rawList =
        await _getJson('/league/$leagueId/matchups/$week') as List<dynamic>;

    final grouped = <int, List<MatchupTeam>>{};
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final rawMatchupId = item['matchup_id'];
      if (rawMatchupId is! num) {
        continue;
      }
      final matchupId = rawMatchupId.toInt();
      final parsed = MatchupTeam.fromJson(item);
      final resolved = parsed.withTeam(teamsByRosterId[parsed.rosterId]);
      grouped.putIfAbsent(matchupId, () => []).add(resolved);
    }

    final sortedIds = grouped.keys.toList()..sort();
    final pairs = <MatchupPair>[];
    for (final id in sortedIds) {
      final list = grouped[id]!;
      if (list.isEmpty) {
        continue;
      }
      pairs.add(
        MatchupPair(
          matchupId: id,
          home: list[0],
          away: list.length > 1 ? list[1] : null,
        ),
      );
    }
    return pairs;
  }

  /// Lấy danh sách trade đã hoàn tất trong [week] từ /transactions/{week}.
  Future<List<TradeTransaction>> fetchTrades({
    required String leagueId,
    required int week,
  }) async {
    final rawList =
        await _getJson('/league/$leagueId/transactions/$week') as List<dynamic>;

    final trades = <TradeTransaction>[];
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      if (item['type'] == 'trade' && item['status'] == 'complete') {
        trades.add(TradeTransaction.fromJson(item, week: week));
      }
    }
    return trades;
  }

  /// Tải /players/nba và dùng compute() chỉ giữ lại thông tin của [playerIds].
  Future<Map<String, Player>> fetchFilteredPlayers(
    Set<String> playerIds,
  ) async {
    if (playerIds.isEmpty) {
      return const {};
    }
    final rawText = await _getRawText('/players/nba', timeout: _playersTimeout);
    return compute(_parseFilteredPlayers, _PlayerParseArgs(rawText, playerIds));
  }

  Future<dynamic> _getJson(String path) async {
    final body = await _getRawText(path, timeout: _defaultTimeout);
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const SleeperApiException(AppStrings.errorParse);
    }
  }

  Future<String> _getRawText(String path, {required Duration timeout}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode == 404) {
        throw const SleeperApiException(
          AppStrings.setupLeagueNotFound,
          statusCode: 404,
        );
      }
      if (response.statusCode != 200) {
        throw SleeperApiException(
          '${AppStrings.errorServer} (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      return utf8.decode(response.bodyBytes);
    } on SleeperApiException {
      rethrow;
    } on SocketException {
      throw const SleeperApiException(AppStrings.errorNetwork);
    } on TimeoutException {
      throw const SleeperApiException(AppStrings.errorNetwork);
    } on http.ClientException {
      throw const SleeperApiException(AppStrings.errorNetwork);
    }
  }

  void dispose() {
    _client.close();
  }
}
