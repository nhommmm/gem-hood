import 'package:flutter_test/flutter_test.dart';
import 'package:gem_hood/config/constants.dart';
import 'package:gem_hood/l10n/strings.dart';
import 'package:gem_hood/main.dart';
import 'package:gem_hood/models/league.dart';
import 'package:gem_hood/models/matchup.dart';
import 'package:gem_hood/models/nba_game.dart';
import 'package:gem_hood/models/player.dart';
import 'package:gem_hood/models/team.dart';
import 'package:gem_hood/models/trade.dart';
import 'package:gem_hood/providers/fantasy_provider.dart';
import 'package:gem_hood/services/player_cache.dart';
import 'package:gem_hood/services/schedule_service.dart';
import 'package:gem_hood/services/sleeper_api.dart';
import 'package:gem_hood/services/trade_cache.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSleeperApi extends SleeperApi {
  @override
  Future<int?> fetchCurrentNbaWeek() async => 1;

  @override
  Future<League> fetchLeague(String leagueId) async {
    if (leagueId == 'invalid') {
      throw const SleeperApiException(AppStrings.setupLeagueNotFound);
    }
    return League(
      leagueId: leagueId,
      name: 'Sample Fantasy League',
      season: '2026',
      currentLeg: 1,
      rosterPositions: const ['PG', 'BN'],
    );
  }

  @override
  Future<List<Team>> fetchTeams(String leagueId) async => const [];

  @override
  Future<List<MatchupPair>> fetchMatchups({
    required String leagueId,
    required int week,
    required Map<int, Team> teamsByRosterId,
  }) async => const [];

  @override
  Future<List<TradeTransaction>> fetchTrades({
    required String leagueId,
    required int week,
  }) async => const [];

  @override
  Future<Map<String, Player>> fetchFilteredPlayers(
    Set<String> playerIds,
  ) async => const {};
}

class _FakePlayerCache extends PlayerCache {
  @override
  Future<Map<String, Player>?> loadValidCache() async => const {};

  @override
  Future<void> saveCache(Map<String, Player> players) async {}
}

class _FakeTradeCache extends TradeCache {
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

class _FakeScheduleService extends ScheduleService {
  @override
  Future<void> loadSchedule() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders main navigation tabs cleanly when league is set', (
    WidgetTester tester,
  ) async {
    final provider = FantasyProvider(
      api: _FakeSleeperApi(),
      playerCache: _FakePlayerCache(),
      tradeCache: _FakeTradeCache(),
      scheduleService: _FakeScheduleService(),
      initialLeagueId: 'sample_league_1',
    );

    await tester.pumpWidget(GemHoodApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tabMatchups), findsOneWidget);
    expect(find.text(AppStrings.tabTeams), findsOneWidget);
    expect(find.text(AppStrings.tabStandings), findsOneWidget);
    expect(find.text(AppStrings.tabTrades), findsOneWidget);
    expect(find.text(AppStrings.tabInsights), findsOneWidget);
    expect(find.text(AppStrings.changeLeagueLabel), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('First launch shows SetupScreen and validates League ID', (
    WidgetTester tester,
  ) async {
    final provider = FantasyProvider(
      api: _FakeSleeperApi(),
      playerCache: _FakePlayerCache(),
      tradeCache: _FakeTradeCache(),
      scheduleService: _FakeScheduleService(),
      initialLeagueId: '',
    );

    await tester.pumpWidget(GemHoodApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.setupTitle), findsOneWidget);
    expect(find.text(AppStrings.setupSubmitButton), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.tap(find.text(AppStrings.setupSubmitButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.setupLeagueNotFound), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'sample_league_2');
    await tester.tap(find.text(AppStrings.setupSubmitButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tabMatchups), findsOneWidget);
    expect(provider.leagueId, 'sample_league_2');
  });

  test('NbaGame assigns ET fantasy weeks and converts VN display times', () {
    final lakersSunEt = NbaGame.fromJson(const {
      'utc': '2026-11-15T21:00Z',
      'date': '2026-11-15',
      'home': 'PHX',
      'away': 'LAL',
    });
    expect(lakersSunEt.etDate, DateTime.utc(2026, 11, 15));
    expect(lakersSunEt.fantasyWeekStartEt, DateTime.utc(2026, 11, 9));
    final vnSunEt = lakersSunEt.displayDateTime(ScheduleTimezone.vietnam);
    expect(vnSunEt, DateTime.utc(2026, 11, 16, 4, 0));
    expect(vnSunEt.weekday, DateTime.monday);

    final lakersNextWedVn = NbaGame.fromJson(const {
      'utc': '2026-11-18T04:00Z',
      'date': '2026-11-17',
      'home': 'LAL',
      'away': 'CHA',
    });
    expect(lakersNextWedVn.etDate, DateTime.utc(2026, 11, 17));
    expect(lakersNextWedVn.fantasyWeekStartEt, DateTime.utc(2026, 11, 16));
    expect(
      lakersNextWedVn.displayDateTime(ScheduleTimezone.vietnam),
      DateTime.utc(2026, 11, 18, 11, 0),
    );
  });
}
