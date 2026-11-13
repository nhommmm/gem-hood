import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../l10n/strings.dart';
import '../models/league.dart';
import '../models/matchup.dart';
import '../models/nba_game.dart';
import '../models/player.dart';
import '../models/slot_player.dart';
import '../models/team.dart';
import '../models/trade.dart';
import '../services/league_config_service.dart';
import '../services/player_cache.dart';
import '../services/schedule_service.dart';
import '../services/sleeper_api.dart';
import '../services/trade_cache.dart';

/// Quản lý trạng thái toàn cục, logic nạp dữ liệu Sleeper và timer làm mới tự động.
class FantasyProvider extends ChangeNotifier {
  FantasyProvider({
    SleeperApi? api,
    PlayerCache? playerCache,
    TradeCache? tradeCache,
    ScheduleService? scheduleService,
    LeagueConfigService? configService,
    String? initialLeagueId,
    String? initialPriorityUsername,
  }) : _api = api ?? SleeperApi(),
       _playerCache = playerCache ?? PlayerCache(),
       _tradeCache = tradeCache ?? TradeCache(),
       _scheduleService = scheduleService ?? ScheduleService(),
       _configService = configService ?? LeagueConfigService(),
       _leagueId = (initialLeagueId ?? AppConstants.defaultLeagueId).trim(),
       _priorityUsername =
           (initialPriorityUsername ?? AppConstants.defaultPriorityUsername)
               .trim(),
       _hasResolvedInitialConfig = initialLeagueId != null,
       _needsSetup =
           initialLeagueId != null && initialLeagueId.trim().isEmpty;

  final SleeperApi _api;
  final PlayerCache _playerCache;
  final TradeCache _tradeCache;
  final ScheduleService _scheduleService;
  final LeagueConfigService _configService;

  String _leagueId;
  String _priorityUsername;
  bool _hasResolvedInitialConfig;
  bool _needsSetup;
  bool _isValidatingSetup = false;
  String? _setupError;

  League? _league;
  int _currentWeek = 1;
  int _selectedWeek = 1;
  List<Team> _teams = const [];
  Team? _selectedTeam;
  List<MatchupPair> _matchups = const [];
  MatchupPair? _selectedMatchup;
  Map<String, Player> _players = {};

  bool _isLoadingInitial = false;
  bool _isLoadingMatchups = false;
  bool _isLoadingTrades = false;
  bool _hasLoadedTrades = false;
  String? _initialError;
  String? _matchupsError;
  String? _tradesError;
  bool _filterPriorityTradesOnly = false;
  int _scheduleWeekOffset = 0;

  final Map<int, List<TradeTransaction>> _tradesByWeek = {};
  Timer? _matchupRefreshTimer;
  final Set<String> _sessionFetchedIds = <String>{};

  String get leagueId => _leagueId;
  String get priorityUsername => _priorityUsername;
  bool get needsSetup => _needsSetup;
  bool get hasConfiguredLeague => _leagueId.isNotEmpty;
  bool get isValidatingSetup => _isValidatingSetup;
  String? get setupError => _setupError;

  League? get league => _league;
  int get currentWeek => _currentWeek;
  int get selectedWeek => _selectedWeek;
  List<Team> get teams => _teams;
  Team? get selectedTeam => _selectedTeam;
  List<MatchupPair> get matchups => _matchups;
  MatchupPair? get selectedMatchup => _selectedMatchup;
  Map<String, Player> get players => _players;

  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMatchups => _isLoadingMatchups;
  bool get isLoadingTrades => _isLoadingTrades;
  String? get initialError => _initialError;
  String? get matchupsError => _matchupsError;
  String? get tradesError => _tradesError;
  bool get filterPriorityTradesOnly => _filterPriorityTradesOnly;

  /// Đội thuộc về [priorityUsername] (nếu đã cấu hình và tìm thấy).
  Team? get priorityTeam {
    if (_priorityUsername.isEmpty) {
      return null;
    }
    for (final team in _teams) {
      if (team.isOwnedBy(_priorityUsername)) {
        return team;
      }
    }
    return null;
  }

  /// Danh sách trade đã tổng hợp, sắp xếp mới nhất lên đầu và áp dụng bộ lọc.
  List<TradeDisplay> get visibleTrades {
    final byId = <String, TradeTransaction>{};
    for (final weekTrades in _tradesByWeek.values) {
      for (final trade in weekTrades) {
        if (trade.transactionId.isNotEmpty) {
          byId[trade.transactionId] = trade;
        }
      }
    }

    final sorted = byId.values.toList()
      ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

    final teamsByRosterId = _mapTeamsByRosterId(_teams);
    final priorityRosterId = priorityTeam?.rosterId;

    final filtered = _filterPriorityTradesOnly
        ? (priorityRosterId == null
              ? const <TradeTransaction>[]
              : sorted
                    .where((t) => t.rosterIds.contains(priorityRosterId))
                    .toList(growable: false))
        : sorted;

    return filtered
        .map((trade) => _buildTradeDisplay(trade, teamsByRosterId, priorityRosterId))
        .toList(growable: false);
  }

  /// Bảng xếp hạng sắp xếp theo Wins giảm dần, sau đó FPTS giảm dần.
  List<Team> get standings {
    final copy = List<Team>.from(_teams);
    copy.sort((a, b) {
      final winCompare = b.wins.compareTo(a.wins);
      if (winCompare != 0) {
        return winCompare;
      }
      return b.fpts.compareTo(a.fpts);
    });
    return copy;
  }

  /// Độ lệch tuần fantasy đang xem ở phần lịch (0 = tuần này, 1 = tuần sau, -1 = tuần trước).
  int get scheduleWeekOffset => _scheduleWeekOffset;

  /// Ngày Thứ 2 (ET) bắt đầu tuần fantasy đang xem ở phần lịch.
  DateTime get selectedFantasyWeekStartEt => _scheduleService
      .currentFantasyWeekStartEt()
      .add(Duration(days: _scheduleWeekOffset * 7));

  /// Nhãn ngắn của nút tuần lịch đấu (Tuần này / Tuần sau / Tuần trước).
  String get scheduleWeekOffsetLabel {
    if (_scheduleWeekOffset == 0) {
      return AppStrings.scheduleThisWeek;
    }
    if (_scheduleWeekOffset == 1) {
      return AppStrings.scheduleNextWeek;
    }
    if (_scheduleWeekOffset == -1) {
      return AppStrings.schedulePrevWeek;
    }
    final sign = _scheduleWeekOffset > 0 ? '+' : '';
    return '$sign$_scheduleWeekOffset';
  }

  /// Dòng mô tả khoảng ngày tuần fantasy theo múi giờ hiển thị (VD: Thứ 3 10/11 – Thứ 2 16/11 (giờ VN)).
  String get fantasyWeekRangeLabel {
    final days = _scheduleService.displayDaysForFantasyWeek(
      selectedFantasyWeekStartEt,
    );
    final first = days.first;
    final last = days.last;
    final firstWd = AppStrings.scheduleWeekdaysFull[first.weekday - 1];
    final lastWd = AppStrings.scheduleWeekdaysFull[last.weekday - 1];
    final firstDate =
        '${first.day.toString().padLeft(2, '0')}/${first.month.toString().padLeft(2, '0')}';
    final lastDate =
        '${last.day.toString().padLeft(2, '0')}/${last.month.toString().padLeft(2, '0')}';
    final tzShort = AppConstants.scheduleTimezone == ScheduleTimezone.vietnam
        ? AppStrings.scheduleTimezoneShortVietnam
        : AppStrings.scheduleTimezoneShortEastern;
    return '${AppStrings.scheduleWeekRangePrefix} $firstWd $firstDate – $lastWd $lastDate ($tzShort)';
  }

  /// Chuyển sang tuần fantasy trước đó.
  void previousScheduleWeek() {
    _scheduleWeekOffset--;
    notifyListeners();
  }

  /// Chuyển sang tuần fantasy kế tiếp.
  void nextScheduleWeek() {
    _scheduleWeekOffset++;
    notifyListeners();
  }

  /// Quay lại tuần fantasy hiện tại.
  void resetScheduleWeekToCurrent() {
    if (_scheduleWeekOffset == 0) {
      return;
    }
    _scheduleWeekOffset = 0;
    notifyListeners();
  }

  /// Bảng 7 cột (Thứ 3 → Thứ 2 giờ VN) đếm số cầu thủ không thuộc IR có trận trong tuần fantasy đang chọn.
  List<ScheduleDayCount> get priorityTeamFantasyWeekSchedule {
    final targetTeam =
        priorityTeam ?? (_teams.isNotEmpty ? _teams.first : null);
    if (targetTeam == null || !_scheduleService.isLoaded) {
      return const [];
    }

    final irSet = targetTeam.reserve.toSet();
    final activeIds = targetTeam.players
        .where((id) => id.isNotEmpty && id != '0' && !irSet.contains(id))
        .toList(growable: false);

    final weekStartEt = selectedFantasyWeekStartEt;
    final displayDays = _scheduleService.displayDaysForFantasyWeek(weekStartEt);

    // Gom các trận thuộc tuần fantasy đang chọn theo ngày hiển thị (VN/ET) của giờ bắt đầu
    // để số đếm từng cột khớp chính xác với danh sách trận của từng cầu thủ.
    final countsByDay = <DateTime, int>{
      for (final day in displayDays) day: 0,
    };

    for (final id in activeIds) {
      final nbaTeam = _players[id]?.team;
      if (nbaTeam == null || nbaTeam.isEmpty) {
        continue;
      }
      final teamGames = _scheduleService.getGamesForTeamInFantasyWeek(
        teamCode: nbaTeam,
        weekStartEt: weekStartEt,
      );
      final playedDisplayDates = <DateTime>{
        for (final g in teamGames) g.displayDate(AppConstants.scheduleTimezone),
      };
      for (final d in playedDisplayDates) {
        if (countsByDay.containsKey(d)) {
          countsByDay[d] = countsByDay[d]! + 1;
        }
      }
    }

    return displayDays
        .map((day) => ScheduleDayCount(date: day, playerCount: countsByDay[day] ?? 0))
        .toList(growable: false);
  }

  /// Xóa thông báo lỗi trên màn Setup.
  void clearSetupError() {
    if (_setupError == null) {
      return;
    }
    _setupError = null;
    notifyListeners();
  }

  /// Kiểm tra League ID qua /v1/league/{id}, lưu cấu hình và nạp dữ liệu giải đấu.
  Future<bool> submitLeagueSetup({
    required String leagueId,
    String priorityUsername = '',
    Uri? baseUri,
  }) async {
    final trimmedLeagueId = leagueId.trim();
    final trimmedUsername = priorityUsername.trim();
    if (trimmedLeagueId.isEmpty) {
      _setupError = AppStrings.setupLeagueIdRequired;
      notifyListeners();
      return false;
    }

    _isValidatingSetup = true;
    _setupError = null;
    notifyListeners();

    try {
      final validatedLeague = await _api.fetchLeague(trimmedLeagueId);
      final resolvedId = validatedLeague.leagueId.isNotEmpty
          ? validatedLeague.leagueId
          : trimmedLeagueId;

      await _configService.saveConfig(
        LeagueConfig(
          leagueId: resolvedId,
          priorityUsername: trimmedUsername,
        ),
      );

      final isLeagueChanged = resolvedId != _leagueId;
      _leagueId = resolvedId;
      _priorityUsername = trimmedUsername;
      _hasResolvedInitialConfig = true;
      _needsSetup = false;

      if (isLeagueChanged) {
        _teams = const [];
        _selectedTeam = null;
        _matchups = const [];
        _selectedMatchup = null;
        _tradesByWeek.clear();
        _hasLoadedTrades = false;
        _tradesError = null;
        _matchupsError = null;
        _initialError = null;
        _filterPriorityTradesOnly = false;
      }

      _league = validatedLeague;
      await _loadLeagueResources(
        validatedLeague,
        resetSelectedWeek: isLeagueChanged || _teams.isEmpty,
      );
      return true;
    } on SleeperApiException catch (e) {
      _setupError = e.message;
      return false;
    } catch (_) {
      _setupError = AppStrings.errorGeneric;
      return false;
    } finally {
      _isValidatingSetup = false;
      notifyListeners();
    }
  }

  /// Khởi tạo toàn bộ dữ liệu ban đầu cho ứng dụng.
  Future<void> loadInitial({Uri? baseUri}) async {
    if (_isLoadingInitial) {
      return;
    }
    _isLoadingInitial = true;
    _initialError = null;
    notifyListeners();

    try {
      if (!_hasResolvedInitialConfig) {
        final config = await _configService.loadInitialConfig(baseUri: baseUri);
        _leagueId = config.leagueId.trim();
        _priorityUsername = config.priorityUsername.trim();
        _hasResolvedInitialConfig = true;
      }

      if (_leagueId.isEmpty) {
        _needsSetup = true;
        return;
      }
      _needsSetup = false;

      final league = await _api.fetchLeague(_leagueId);
      _league = league;
      await _loadLeagueResources(league, resetSelectedWeek: true);
    } on SleeperApiException catch (e) {
      _initialError = e.message;
    } catch (_) {
      _initialError = AppStrings.errorGeneric;
    } finally {
      _isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> _loadLeagueResources(
    League league, {
    required bool resetSelectedWeek,
  }) async {
    final results = await Future.wait<dynamic>([
      _safeFetchCurrentWeek(),
      _api.fetchTeams(_leagueId),
      _scheduleService.loadSchedule(),
    ]);

    final stateWeek = results[0] as int?;
    final rawTeams = results[1] as List<Team>;

    _currentWeek = stateWeek ?? league.currentLeg;
    if (_currentWeek < 1) {
      _currentWeek = 1;
    }
    if (resetSelectedWeek || _selectedWeek > _currentWeek) {
      _selectedWeek = _currentWeek;
    }

    _teams = _sortTeamsWithPriority(rawTeams);
    _syncSelectedTeam();

    final teamsByRosterId = _mapTeamsByRosterId(_teams);
    _matchups = await _api.fetchMatchups(
      leagueId: _leagueId,
      week: _selectedWeek,
      teamsByRosterId: teamsByRosterId,
    );
    _syncSelectedMatchup();
    _initialError = null;
    _matchupsError = null;

    await _ensurePlayersLoaded(_collectAllPlayerIds());
  }

  /// Làm mới toàn bộ dữ liệu (dùng cho pull-to-refresh).
  Future<void> refreshAll() async {
    if (_leagueId.isEmpty || _league == null) {
      await loadInitial();
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _safeFetchCurrentWeek(),
        _api.fetchLeague(_leagueId),
        _api.fetchTeams(_leagueId),
      ]);

      final stateWeek = results[0] as int?;
      final league = results[1] as League;
      final rawTeams = results[2] as List<Team>;

      _league = league;
      _currentWeek = stateWeek ?? league.currentLeg;
      if (_currentWeek < 1) {
        _currentWeek = 1;
      }
      if (_selectedWeek > _currentWeek) {
        _selectedWeek = _currentWeek;
      }

      _teams = _sortTeamsWithPriority(rawTeams);
      _syncSelectedTeam();

      final teamsByRosterId = _mapTeamsByRosterId(_teams);
      _matchups = await _api.fetchMatchups(
        leagueId: _leagueId,
        week: _selectedWeek,
        teamsByRosterId: teamsByRosterId,
      );
      _syncSelectedMatchup();
      _matchupsError = null;
      _initialError = null;

      await _ensurePlayersLoaded(_collectAllPlayerIds());
      if (_hasLoadedTrades) {
        await loadTrades(isRefresh: true);
      }
      notifyListeners();
    } on SleeperApiException catch (e) {
      _matchupsError = e.message;
      notifyListeners();
    } catch (_) {
      _matchupsError = AppStrings.errorGeneric;
      notifyListeners();
    }
  }

  /// Đổi tuần đang xem ở tab Matchups (giới hạn từ 1 đến [currentWeek]).
  Future<void> selectWeek(int week) async {
    final clamped = week.clamp(1, _currentWeek);
    if (clamped == _selectedWeek && _matchupsError == null) {
      return;
    }
    _selectedWeek = clamped;
    _selectedMatchup = null;
    await refreshMatchups();
  }

  /// Nạp lại danh sách cặp đấu cho tuần đang chọn.
  Future<void> refreshMatchups({bool silent = false}) async {
    if (_leagueId.isEmpty || _league == null) {
      if (!silent) {
        await loadInitial();
      }
      return;
    }

    if (!silent) {
      _isLoadingMatchups = true;
      _matchupsError = null;
      notifyListeners();
    }

    try {
      final teamsByRosterId = _mapTeamsByRosterId(_teams);
      _matchups = await _api.fetchMatchups(
        leagueId: _leagueId,
        week: _selectedWeek,
        teamsByRosterId: teamsByRosterId,
      );
      _syncSelectedMatchup();
      _matchupsError = null;
      await _ensurePlayersLoaded(_collectAllPlayerIds());
    } on SleeperApiException catch (e) {
      if (!silent) {
        _matchupsError = e.message;
      }
    } catch (_) {
      if (!silent) {
        _matchupsError = AppStrings.errorGeneric;
      }
    } finally {
      if (!silent) {
        _isLoadingMatchups = false;
      }
      notifyListeners();
    }
  }

  /// Chọn một cặp đấu để xem chi tiết (Master-Detail hoặc điều hướng).
  void selectMatchup(MatchupPair? pair) {
    _selectedMatchup = pair;
    notifyListeners();
  }

  /// Chọn một đội để xem đội hình chi tiết.
  void selectTeam(Team? team) {
    _selectedTeam = team;
    notifyListeners();
  }

  /// Bật timer tự động làm mới mỗi 60 giây khi đang ở tab Matchups.
  void startMatchupsAutoRefresh() {
    if (_matchupRefreshTimer != null) {
      return;
    }
    _matchupRefreshTimer = Timer.periodic(
      AppConstants.refreshInterval,
      (_) => refreshMatchups(silent: true),
    );
  }

  /// Hủy timer tự động làm mới khi rời màn hình Matchups.
  void stopMatchupsAutoRefresh() {
    _matchupRefreshTimer?.cancel();
    _matchupRefreshTimer = null;
  }

  /// Nạp danh sách trade lần đầu khi mở tab Trades (nếu chưa nạp).
  Future<void> ensureTradesLoaded() async {
    if (_hasLoadedTrades || _isLoadingTrades) {
      return;
    }
    await loadTrades();
  }

  /// Tải toàn bộ trade từ tuần 1 đến [currentWeek] song song, có cache các tuần đã qua.
  Future<void> loadTrades({bool isRefresh = false}) async {
    if (_league == null) {
      await loadInitial();
      if (_league == null) {
        return;
      }
    }

    if (!isRefresh) {
      _isLoadingTrades = true;
      _tradesError = null;
      notifyListeners();
    }

    try {
      final weeksToFetch = <int>[];
      final cacheFutures = <Future<void>>[];

      for (var week = 1; week <= _currentWeek; week++) {
        if (week < _currentWeek) {
          if (_tradesByWeek.containsKey(week)) {
            continue;
          }
          final targetWeek = week;
          cacheFutures.add(() async {
            final cached = await _tradeCache.loadWeekTrades(
              _leagueId,
              targetWeek,
            );
            if (cached != null) {
              _tradesByWeek[targetWeek] = cached;
            } else {
              weeksToFetch.add(targetWeek);
            }
          }());
        } else {
          weeksToFetch.add(week);
        }
      }

      if (cacheFutures.isNotEmpty) {
        await Future.wait(cacheFutures);
      }

      weeksToFetch.sort();
      if (weeksToFetch.isNotEmpty) {
        final fetchedLists = await Future.wait(
          weeksToFetch.map(
            (week) => _api.fetchTrades(
              leagueId: _leagueId,
              week: week,
            ),
          ),
        );

        final saveFutures = <Future<void>>[];
        for (var i = 0; i < weeksToFetch.length; i++) {
          final week = weeksToFetch[i];
          final list = fetchedLists[i];
          _tradesByWeek[week] = list;
          if (week < _currentWeek) {
            saveFutures.add(
              _tradeCache.saveWeekTrades(_leagueId, week, list),
            );
          }
        }
        if (saveFutures.isNotEmpty) {
          await Future.wait(saveFutures);
        }
      }

      final tradePlayerIds = <String>{};
      for (final weekTrades in _tradesByWeek.values) {
        for (final trade in weekTrades) {
          tradePlayerIds.addAll(trade.allPlayerIds);
        }
      }
      tradePlayerIds.removeWhere((id) => id.isEmpty || id == '0');
      await _ensurePlayersLoaded(tradePlayerIds);

      _hasLoadedTrades = true;
      _tradesError = null;
    } on SleeperApiException catch (e) {
      _tradesError = e.message;
    } catch (_) {
      _tradesError = AppStrings.errorGeneric;
    } finally {
      _isLoadingTrades = false;
      notifyListeners();
    }
  }

  /// Đổi bộ lọc hiển thị tất cả trade hoặc chỉ trade của [priorityUsername].
  void setTradesFilterPriorityOnly(bool value) {
    if (_filterPriorityTradesOnly == value) {
      return;
    }
    _filterPriorityTradesOnly = value;
    notifyListeners();
  }

  /// Tạo danh sách Starters của một [team] kèm nhãn slot từ League.
  List<SlotPlayer> buildTeamStarters(Team team) {
    final slots = _league?.starterSlots ?? const <String>[];
    final result = <SlotPlayer>[];
    for (var i = 0; i < team.starters.length; i++) {
      final id = team.starters[i];
      final slotLabel = i < slots.length ? slots[i] : 'UTIL';
      result.add(
        SlotPlayer(
          playerId: id,
          slotLabel: slotLabel,
          player: _players[id],
          isStarter: true,
          weekSchedule: _buildPlayerWeekSchedule(id),
        ),
      );
    }
    return result;
  }

  /// Tạo danh sách Bench của một [team].
  List<SlotPlayer> buildTeamBench(Team team) {
    return team.benchPlayers
        .map(
          (id) => SlotPlayer(
            playerId: id,
            slotLabel: AppStrings.sectionBench,
            player: _players[id],
            weekSchedule: _buildPlayerWeekSchedule(id),
          ),
        )
        .toList(growable: false);
  }

  /// Tạo danh sách IR (Reserve) của một [team].
  List<SlotPlayer> buildTeamIr(Team team) {
    return team.reserve
        .map(
          (id) => SlotPlayer(
            playerId: id,
            slotLabel: AppStrings.sectionIr,
            player: _players[id],
            isIr: true,
            weekSchedule: _buildPlayerWeekSchedule(id),
          ),
        )
        .toList(growable: false);
  }

  /// Tạo danh sách Starters trong tuần của một [matchupTeam] kèm điểm.
  List<SlotPlayer> buildMatchupStarters(MatchupTeam matchupTeam) {
    final slots = _league?.starterSlots ?? const <String>[];
    final result = <SlotPlayer>[];
    for (var i = 0; i < matchupTeam.starters.length; i++) {
      final id = matchupTeam.starters[i];
      final slotLabel = i < slots.length ? slots[i] : 'UTIL';
      final pts = i < matchupTeam.startersPoints.length
          ? matchupTeam.startersPoints[i]
          : (matchupTeam.playersPoints[id] ?? 0.0);
      result.add(
        SlotPlayer(
          playerId: id,
          slotLabel: slotLabel,
          player: _players[id],
          points: pts,
          isStarter: true,
          weekSchedule: _buildPlayerWeekSchedule(id),
        ),
      );
    }
    return result;
  }

  /// Tạo danh sách Bench trong tuần của một [matchupTeam] kèm điểm.
  List<SlotPlayer> buildMatchupBench(MatchupTeam matchupTeam) {
    return matchupTeam.benchPlayers
        .map(
          (id) => SlotPlayer(
            playerId: id,
            slotLabel: 'BN',
            player: _players[id],
            points: matchupTeam.playersPoints[id] ?? 0.0,
            weekSchedule: _buildPlayerWeekSchedule(id),
          ),
        )
        .toList(growable: false);
  }

  PlayerWeekSchedule? _buildPlayerWeekSchedule(String playerId) {
    if (!_scheduleService.isLoaded || playerId.isEmpty || playerId == '0') {
      return null;
    }
    final nbaTeam = _players[playerId]?.team;
    if (nbaTeam == null || nbaTeam.isEmpty) {
      return const PlayerWeekSchedule(games: []);
    }

    final weekStartEt = selectedFantasyWeekStartEt;
    final games = _scheduleService.getGamesForTeamInFantasyWeek(
      teamCode: nbaTeam,
      weekStartEt: weekStartEt,
    );

    if (games.isEmpty) {
      return const PlayerWeekSchedule(games: []);
    }

    final nowUtc = DateTime.now().toUtc();
    final scheduledGames = games.map((game) {
      final dt = game.displayDateTime(AppConstants.scheduleTimezone);
      final weekday = AppStrings.scheduleWeekdaysShort[dt.weekday - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final prefix = game.isHome(nbaTeam) ? 'vs' : '@';
      final opp = game.opponentOf(nbaTeam);
      return PlayerScheduledGame(
        label: '$weekday $day/$month $hour:$minute $prefix $opp',
        isPast: game.hasStarted(nowUtc),
      );
    }).toList(growable: false);

    return PlayerWeekSchedule(games: scheduledGames);
  }

  TradeDisplay _buildTradeDisplay(
    TradeTransaction trade,
    Map<int, Team> teamsByRosterId,
    int? priorityRosterId,
  ) {
    final participatingIds = <int>[
      ...trade.rosterIds,
      for (final id in trade.adds.values)
        if (!trade.rosterIds.contains(id)) id,
      for (final id in trade.drops.values)
        if (!trade.rosterIds.contains(id)) id,
    ];

    final sides = participatingIds.map((rosterId) {
      final receivedPlayers = <Player>[];
      for (final entry in trade.adds.entries) {
        if (entry.value == rosterId) {
          receivedPlayers.add(
            _players[entry.key] ?? Player.unknown(entry.key),
          );
        }
      }

      final sentPlayers = <Player>[];
      for (final entry in trade.drops.entries) {
        if (entry.value == rosterId) {
          sentPlayers.add(
            _players[entry.key] ?? Player.unknown(entry.key),
          );
        }
      }

      final receivedPicks = trade.draftPicks
          .where((p) => p.ownerId == rosterId)
          .toList(growable: false);
      final sentPicks = trade.draftPicks
          .where((p) => p.previousOwnerId == rosterId)
          .toList(growable: false);

      return TradeSide(
        rosterId: rosterId,
        team: teamsByRosterId[rosterId],
        receivedPlayers: receivedPlayers,
        sentPlayers: sentPlayers,
        receivedPicks: receivedPicks,
        sentPicks: sentPicks,
      );
    }).toList(growable: false);

    return TradeDisplay(
      transaction: trade,
      sides: sides,
      teamsByRosterId: teamsByRosterId,
      involvesPriorityTeam:
          priorityRosterId != null &&
          participatingIds.contains(priorityRosterId),
    );
  }

  Future<int?> _safeFetchCurrentWeek() async {
    try {
      return await _api.fetchCurrentNbaWeek();
    } catch (_) {
      return null;
    }
  }

  List<Team> _sortTeamsWithPriority(List<Team> rawTeams) {
    final sorted = List<Team>.from(rawTeams);
    sorted.sort((a, b) {
      if (_priorityUsername.isNotEmpty) {
        final aPriority = a.isOwnedBy(_priorityUsername);
        final bPriority = b.isOwnedBy(_priorityUsername);
        if (aPriority && !bPriority) {
          return -1;
        }
        if (!aPriority && bPriority) {
          return 1;
        }
      }
      return a.rosterId.compareTo(b.rosterId);
    });
    return sorted;
  }

  Map<int, Team> _mapTeamsByRosterId(List<Team> teams) {
    return <int, Team>{for (final team in teams) team.rosterId: team};
  }

  void _syncSelectedTeam() {
    if (_teams.isEmpty) {
      _selectedTeam = null;
      return;
    }
    if (_selectedTeam == null) {
      _selectedTeam = _teams.first;
      return;
    }
    final match = _teams.where((t) => t.rosterId == _selectedTeam!.rosterId);
    _selectedTeam = match.isNotEmpty ? match.first : _teams.first;
  }

  void _syncSelectedMatchup() {
    if (_matchups.isEmpty) {
      _selectedMatchup = null;
      return;
    }
    if (_selectedMatchup == null) {
      return;
    }
    final match = _matchups.where(
      (m) => m.matchupId == _selectedMatchup!.matchupId,
    );
    _selectedMatchup = match.isNotEmpty ? match.first : null;
  }

  Set<String> _collectAllPlayerIds() {
    final ids = <String>{};
    for (final team in _teams) {
      ids.addAll(team.players);
      ids.addAll(team.starters);
      ids.addAll(team.reserve);
      ids.addAll(team.taxi);
    }
    for (final pair in _matchups) {
      ids.addAll(pair.home.players);
      ids.addAll(pair.home.starters);
      if (pair.away != null) {
        ids.addAll(pair.away!.players);
        ids.addAll(pair.away!.starters);
      }
    }
    ids.removeWhere((id) => id.isEmpty || id == '0');
    return ids;
  }

  Future<void> _ensurePlayersLoaded(Set<String> neededIds) async {
    if (neededIds.isEmpty) {
      return;
    }

    if (_players.isEmpty) {
      final cached = await _playerCache.loadValidCache();
      if (cached != null) {
        _players = Map<String, Player>.from(cached);
      }
    }

    final missingIds = neededIds
        .where(
          (id) =>
              !_players.containsKey(id) && !_sessionFetchedIds.contains(id),
        )
        .toSet();

    if (missingIds.isEmpty) {
      return;
    }

    final mergedNeeded = <String>{..._players.keys, ...neededIds};
    final fetched = await _api.fetchFilteredPlayers(mergedNeeded);
    _sessionFetchedIds.addAll(mergedNeeded);

    if (fetched.isNotEmpty) {
      _players = {..._players, ...fetched};
      await _playerCache.saveCache(_players);
    }
  }

  @override
  void dispose() {
    stopMatchupsAutoRefresh();
    _api.dispose();
    super.dispose();
  }
}
