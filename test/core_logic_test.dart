import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_hood/config/constants.dart';
import 'package:gem_hood/config/team_codes.dart';
import 'package:gem_hood/models/league.dart';
import 'package:gem_hood/models/matchup.dart';
import 'package:gem_hood/models/nba_game.dart';
import 'package:gem_hood/models/player.dart';
import 'package:gem_hood/models/team.dart';
import 'package:gem_hood/models/trade.dart';
import 'package:gem_hood/providers/fantasy_provider.dart';
import 'package:gem_hood/providers/insights_provider.dart';
import 'package:gem_hood/services/league_config_service.dart';
import 'package:gem_hood/services/player_cache.dart';
import 'package:gem_hood/services/schedule_service.dart';
import 'package:gem_hood/services/sleeper_api.dart';
import 'package:gem_hood/services/trade_cache.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubSleeperApi extends SleeperApi {
  _StubSleeperApi({
    required this.stubLeague,
    required this.stubTeams,
    required this.stubMatchups,
    required this.stubPlayers,
  });

  final League stubLeague;
  final List<Team> stubTeams;
  final List<MatchupPair> stubMatchups;
  final Map<String, Player> stubPlayers;

  @override
  Future<int?> fetchCurrentNbaWeek() async => 1;

  @override
  Future<League> fetchLeague(String leagueId) async => stubLeague;

  @override
  Future<List<Team>> fetchTeams(String leagueId) async => stubTeams;

  @override
  Future<List<MatchupPair>> fetchMatchups({
    required String leagueId,
    required int week,
    required Map<int, Team> teamsByRosterId,
  }) async => stubMatchups;

  @override
  Future<Map<String, Player>> fetchFilteredPlayers(
    Set<String> playerIds,
  ) async => stubPlayers;

  @override
  Future<List<TradeTransaction>> fetchTrades({
    required String leagueId,
    required int week,
  }) async => const [];
}

class _NoopPlayerCache extends PlayerCache {
  @override
  Future<Map<String, Player>?> loadValidCache() async => const {};

  @override
  Future<void> saveCache(Map<String, Player> players) async {}
}

class _NoopTradeCache extends TradeCache {
  @override
  Future<List<TradeTransaction>?> loadWeekTrades(
    String leagueId,
    int week,
  ) async => const [];

  @override
  Future<void> saveWeekTrades(
    String leagueId,
    int week,
    List<TradeTransaction> trades,
  ) async {}
}

class _NoopScheduleService extends ScheduleService {
  @override
  Future<void> loadSchedule() async {}
}

void main() {
  group('Team FPTS parsing', () {
    test('combines whole and decimal fpts / fpts_against accurately', () {
      final team = Team.fromRosterAndUser(
        rosterJson: {
          'roster_id': 3,
          'owner_id': 'user_3',
          'settings': {
            'wins': 5,
            'losses': 2,
            'ties': 1,
            'fpts': 1425,
            'fpts_decimal': 67,
            'fpts_against': 1310,
            'fpts_against_decimal': 5,
          },
          'players': ['p1', 'p2'],
          'starters': ['p1'],
        },
        userJson: {
          'user_id': 'user_3',
          'display_name': 'sample_manager',
          'metadata': {'team_name': 'Hoops Squad'},
        },
      );

      expect(team.fpts, closeTo(1425.67, 1e-9));
      expect(team.fptsAgainst, closeTo(1310.05, 1e-9));
      expect(team.recordText, '5-2-1');
      expect(team.teamName, 'Hoops Squad');
      expect(team.isOwnedBy('SAMPLE_MANAGER'), isTrue);
      expect(team.isOwnedBy(''), isFalse);
    });
  });

  group('SleeperApi matchup grouping & league validation', () {
    test('groups rosters by matchup_id, ignores null bye, and sorts pairs', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/league/league_42/matchups/3');
        return http.Response(
          jsonEncode([
            {
              'roster_id': 4,
              'matchup_id': 2,
              'points': 110.5,
              'starters': ['p4'],
              'starters_points': [110.5],
              'players': ['p4'],
              'players_points': {'p4': 110.5},
            },
            {
              'roster_id': 1,
              'matchup_id': 1,
              'points': 125.0,
              'starters': ['p1'],
              'starters_points': [125.0],
              'players': ['p1'],
              'players_points': {'p1': 125.0},
            },
            {
              'roster_id': 9,
              'matchup_id': null,
              'points': 0.0,
              'starters': [],
              'starters_points': [],
              'players': [],
              'players_points': {},
            },
            {
              'roster_id': 2,
              'matchup_id': 1,
              'points': 98.25,
              'starters': ['p2'],
              'starters_points': [98.25],
              'players': ['p2'],
              'players_points': {'p2': 98.25},
            },
          ]),
          200,
        );
      });

      final api = SleeperApi(client: mockClient);
      final teamsById = <int, Team>{
        1: const Team(
          rosterId: 1,
          ownerId: 'u1',
          username: 'alpha',
          teamName: 'Alpha',
          wins: 1,
          losses: 0,
          ties: 0,
          fpts: 125.0,
          fptsAgainst: 98.25,
          players: ['p1'],
          starters: ['p1'],
          reserve: [],
          taxi: [],
        ),
        2: const Team(
          rosterId: 2,
          ownerId: 'u2',
          username: 'beta',
          teamName: 'Beta',
          wins: 0,
          losses: 1,
          ties: 0,
          fpts: 98.25,
          fptsAgainst: 125.0,
          players: ['p2'],
          starters: ['p2'],
          reserve: [],
          taxi: [],
        ),
      };

      final pairs = await api.fetchMatchups(
        leagueId: 'league_42',
        week: 3,
        teamsByRosterId: teamsById,
      );

      expect(pairs.length, 2);
      expect(pairs[0].matchupId, 1);
      expect(pairs[0].home.rosterId, 1);
      expect(pairs[0].home.team?.teamName, 'Alpha');
      expect(pairs[0].away?.rosterId, 2);
      expect(pairs[0].away?.team?.teamName, 'Beta');
      expect(pairs[1].matchupId, 2);
      expect(pairs[1].home.rosterId, 4);
      expect(pairs[1].away, isNull);
    });

    test('fetchLeague rejects null or 404 Sleeper responses', () async {
      final nullApi = SleeperApi(
        client: MockClient((_) async => http.Response('null', 200)),
      );
      await expectLater(
        () => nullApi.fetchLeague('999999'),
        throwsA(isA<SleeperApiException>()),
      );

      final notFoundApi = SleeperApi(
        client: MockClient((_) async => http.Response('Not Found', 404)),
      );
      await expectLater(
        () => notFoundApi.fetchLeague('999999'),
        throwsA(
          isA<SleeperApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });

  group('InsightsProvider bench regret computation', () {
    test('detects bench players outscoring lowest starter and sorts by missed points', () async {
      const teamA = Team(
        rosterId: 1,
        ownerId: 'u1',
        username: 'manager_a',
        teamName: 'Team A',
        wins: 1,
        losses: 0,
        ties: 0,
        fpts: 100.0,
        fptsAgainst: 80.0,
        players: ['s1', 's2', 'b1', 'b2'],
        starters: ['s1', 's2'],
        reserve: [],
        taxi: [],
      );

      const matchupA = MatchupTeam(
        rosterId: 1,
        matchupId: 1,
        points: 50.0,
        starters: ['s1', 's2'],
        startersPoints: [35.0, 15.0],
        players: ['s1', 's2', 'b1', 'b2'],
        playersPoints: {
          's1': 35.0,
          's2': 15.0,
          'b1': 28.5,
          'b2': 12.0,
        },
        team: teamA,
      );

      final players = {
        's1': const Player(
          playerId: 's1',
          fullName: 'Starter One',
          position: 'PG',
          fantasyPositions: ['PG'],
        ),
        's2': const Player(
          playerId: 's2',
          fullName: 'Starter Two',
          position: 'SG',
          fantasyPositions: ['SG'],
        ),
        'b1': const Player(
          playerId: 'b1',
          fullName: 'Bench Star',
          position: 'SG',
          fantasyPositions: ['SG'],
        ),
        'b2': const Player(
          playerId: 'b2',
          fullName: 'Bench Low',
          position: 'PF',
          fantasyPositions: ['PF'],
        ),
      };

      final fantasy = FantasyProvider(
        api: _StubSleeperApi(
          stubLeague: const League(
            leagueId: 'sample_1',
            name: 'Sample League',
            season: '2026',
            currentLeg: 1,
            rosterPositions: ['PG', 'SG', 'BN'],
          ),
          stubTeams: const [teamA],
          stubMatchups: const [MatchupPair(matchupId: 1, home: matchupA)],
          stubPlayers: players,
        ),
        playerCache: _NoopPlayerCache(),
        tradeCache: _NoopTradeCache(),
        scheduleService: _NoopScheduleService(),
        initialLeagueId: 'sample_1',
      );

      await fantasy.loadInitial();
      final insights = InsightsProvider.fromFantasy(fantasy, null);

      expect(insights.benchRegrets.length, 1);
      final regret = insights.benchRegrets.first;
      expect(regret.benchPlayer.playerId, 'b1');
      expect(regret.lowestStarter.playerId, 's2');
      expect(regret.missedPoints, closeTo(13.5, 1e-9));
      expect(insights.lineupEfficiencies.single.optimalPoints, closeTo(63.5, 1e-9));
    });
  });

  group('NbaGame Eastern fantasy week assignment', () {
    test('assigns late UTC tip-offs to correct Eastern date & Monday week start', () {
      // 2026-11-02T01:30Z is 2026-11-01 20:30 EST (Sunday) -> week started Mon 2026-10-26.
      final sundayNightEt = NbaGame.fromJson(const {
        'utc': '2026-11-02T01:30:00Z',
        'date': '2026-11-01',
        'home': 'NY',
        'away': 'BOS',
      });
      expect(sundayNightEt.etDate, DateTime.utc(2026, 11, 1));
      expect(sundayNightEt.fantasyWeekStartEt, DateTime.utc(2026, 10, 26));
      expect(sundayNightEt.homeTeam, 'NYK');
      expect(
        sundayNightEt.displayDateTime(ScheduleTimezone.vietnam),
        DateTime.utc(2026, 11, 2, 8, 30),
      );
    });
  });

  group('TeamCodes normalization', () {
    test('normalizes external schedule codes to Sleeper codes and rejects TBD', () {
      expect(TeamCodes.normalize('gs'), 'GSW');
      expect(TeamCodes.normalize('NO'), 'NOP');
      expect(TeamCodes.normalize('ny'), 'NYK');
      expect(TeamCodes.normalize('SA'), 'SAS');
      expect(TeamCodes.normalize('pho'), 'PHX');
      expect(TeamCodes.normalize('WSH'), 'WAS');
      expect(TeamCodes.normalize('UTAH'), 'UTA');
      expect(TeamCodes.normalize('BRK'), 'BKN');
      expect(TeamCodes.normalize('CHO'), 'CHA');
      expect(TeamCodes.normalize('LAL'), 'LAL');

      expect(TeamCodes.isValidTeam('GS'), isTrue);
      expect(TeamCodes.isValidTeam('TBD'), isFalse);
      expect(TeamCodes.isValidTeam(''), isFalse);
      expect(TeamCodes.allSleeperTeams.length, 30);
    });
  });

  group('LeagueConfigService URL params & SharedPreferences', () {
    test('parses ?league= and ?user= from URI and falls back to saved prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LeagueConfigService();

      final fromQuery = service.parseFromUri(
        Uri.parse('https://example.netlify.app/?league=987654&user=demo_user'),
      );
      expect(fromQuery, isNotNull);
      expect(fromQuery!.leagueId, '987654');
      expect(fromQuery.priorityUsername, 'demo_user');

      final fromHash = service.parseFromUri(
        Uri.parse('https://example.netlify.app/#/?league=111222'),
      );
      expect(fromHash, isNotNull);
      expect(fromHash!.leagueId, '111222');
      expect(fromHash.priorityUsername, '');

      await service.saveConfig(
        const LeagueConfig(leagueId: '555666', priorityUsername: 'hoops_fan'),
      );
      final loadedFromPrefs = await service.loadInitialConfig(
        baseUri: Uri.parse('https://example.netlify.app/'),
      );
      expect(loadedFromPrefs.leagueId, '555666');
      expect(loadedFromPrefs.priorityUsername, 'hoops_fan');

      final overriddenByUrl = await service.loadInitialConfig(
        baseUri: Uri.parse('https://example.netlify.app/?league=777888'),
      );
      expect(overriddenByUrl.leagueId, '777888');
      expect(overriddenByUrl.priorityUsername, '');
    });
  });
}
