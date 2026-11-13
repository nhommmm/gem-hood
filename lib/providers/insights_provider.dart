import 'dart:collection';

import '../models/matchup.dart';
import '../models/player.dart';
import '../models/slot_player.dart';
import '../models/team.dart';
import 'fantasy_provider.dart';

/// Kết quả hiệu suất của một cầu thủ starter kèm đội đã start cầu thủ đó.
class StarterPerformance {
  const StarterPerformance({required this.slotPlayer, this.team});

  final SlotPlayer slotPlayer;
  final Team? team;

  double get points => slotPlayer.points ?? 0.0;
}

/// Thông tin cầu thủ dự bị có điểm cao hơn starter thấp nhất cùng đội.
class BenchRegret {
  const BenchRegret({
    this.team,
    required this.benchPlayer,
    required this.lowestStarter,
    required this.missedPoints,
  });

  final Team? team;
  final SlotPlayer benchPlayer;
  final SlotPlayer lowestStarter;
  final double missedPoints;
}

/// Hiệu quả xếp đội hình của một đội trong tuần (điểm starters thực tế vs tối ưu).
class LineupEfficiency {
  const LineupEfficiency({
    this.team,
    required this.actualPoints,
    required this.optimalPoints,
    required this.efficiencyPercent,
  });

  final Team? team;
  final double actualPoints;
  final double optimalPoints;
  final double efficiencyPercent;
}

/// Provider tính toán các chỉ số Insights từ dữ liệu matchups của tuần đang chọn.
class InsightsProvider {
  const InsightsProvider._({
    required this.week,
    required this.matchupsRef,
    required this.playerCount,
    required this.topStarters,
    required this.bottomStarters,
    required this.zeroPointStarters,
    required this.benchRegrets,
    required this.lineupEfficiencies,
  });

  const InsightsProvider.empty()
    : week = 0,
      matchupsRef = const [],
      playerCount = 0,
      topStarters = const [],
      bottomStarters = const [],
      zeroPointStarters = const [],
      benchRegrets = const [],
      lineupEfficiencies = const [];

  static const int _topLimit = 5;

  final int week;
  final List<MatchupPair> matchupsRef;
  final int playerCount;

  final List<StarterPerformance> topStarters;
  final List<StarterPerformance> bottomStarters;
  final List<StarterPerformance> zeroPointStarters;
  final List<BenchRegret> benchRegrets;
  final List<LineupEfficiency> lineupEfficiencies;

  LineupEfficiency? get bestLineup =>
      lineupEfficiencies.isNotEmpty ? lineupEfficiencies.first : null;

  bool get hasData =>
      topStarters.isNotEmpty ||
      bottomStarters.isNotEmpty ||
      zeroPointStarters.isNotEmpty ||
      lineupEfficiencies.isNotEmpty;

  /// Tính toán lại Insights từ [fantasy], tái sử dụng [previous] nếu dữ liệu nguồn chưa đổi.
  static InsightsProvider fromFantasy(
    FantasyProvider fantasy,
    InsightsProvider? previous,
  ) {
    final matchups = fantasy.matchups;
    final players = fantasy.players;
    final starterSlots = fantasy.league?.starterSlots ?? const <String>[];
    final currentWeek = fantasy.selectedWeek;

    if (previous != null &&
        identical(previous.matchupsRef, matchups) &&
        previous.week == currentWeek &&
        previous.playerCount == players.length) {
      return previous;
    }

    if (matchups.isEmpty) {
      return InsightsProvider._(
        week: currentWeek,
        matchupsRef: matchups,
        playerCount: players.length,
        topStarters: const [],
        bottomStarters: const [],
        zeroPointStarters: const [],
        benchRegrets: const [],
        lineupEfficiencies: const [],
      );
    }

    final allTeams = <MatchupTeam>[
      for (final pair in matchups) ...[
        pair.home,
        if (pair.away != null) pair.away!,
      ],
    ];

    final allStarters = <StarterPerformance>[];
    final regrets = <BenchRegret>[];
    final efficiencies = <LineupEfficiency>[];

    for (final matchupTeam in allTeams) {
      final starters = fantasy
          .buildMatchupStarters(matchupTeam)
          .where((sp) => !sp.isEmptySlot)
          .toList(growable: false);

      for (final sp in starters) {
        allStarters.add(
          StarterPerformance(slotPlayer: sp, team: matchupTeam.team),
        );
      }

      if (starters.isNotEmpty) {
        final lowestStarter = starters.reduce(
          (a, b) => (a.points ?? 0.0) <= (b.points ?? 0.0) ? a : b,
        );
        final lowestPts = lowestStarter.points ?? 0.0;

        final bench = fantasy
            .buildMatchupBench(matchupTeam)
            .where((sp) => !sp.isEmptySlot);

        for (final benchSp in bench) {
          final benchPts = benchSp.points ?? 0.0;
          if (benchPts > lowestPts) {
            regrets.add(
              BenchRegret(
                team: matchupTeam.team,
                benchPlayer: benchSp,
                lowestStarter: lowestStarter,
                missedPoints: benchPts - lowestPts,
              ),
            );
          }
        }
      }

      final actualPoints = starters.fold<double>(
        0.0,
        (sum, sp) => sum + (sp.points ?? 0.0),
      );
      final optimalRaw = _computeOptimalLineupPoints(
        matchupTeam: matchupTeam,
        starterSlots: starterSlots,
        players: players,
      );
      final optimalPoints = optimalRaw < actualPoints
          ? actualPoints
          : optimalRaw;
      final efficiencyPercent = optimalPoints > 0
          ? (actualPoints / optimalPoints) * 100.0
          : 100.0;

      efficiencies.add(
        LineupEfficiency(
          team: matchupTeam.team,
          actualPoints: actualPoints,
          optimalPoints: optimalPoints,
          efficiencyPercent: efficiencyPercent,
        ),
      );
    }

    final sortedHigh = List<StarterPerformance>.from(allStarters)
      ..sort((a, b) => b.points.compareTo(a.points));
    final topStarters = sortedHigh.take(_topLimit).toList(growable: false);

    final zeroStarters = allStarters
        .where((s) => s.points == 0.0)
        .toList(growable: false);
    final nonZeroStarters =
        allStarters.where((s) => s.points != 0.0).toList()
          ..sort((a, b) => a.points.compareTo(b.points));
    final bottomStarters = nonZeroStarters
        .take(_topLimit)
        .toList(growable: false);

    regrets.sort((a, b) => b.missedPoints.compareTo(a.missedPoints));

    efficiencies.sort((a, b) {
      final effCmp = b.efficiencyPercent.compareTo(a.efficiencyPercent);
      if (effCmp != 0) {
        return effCmp;
      }
      return b.actualPoints.compareTo(a.actualPoints);
    });

    return InsightsProvider._(
      week: currentWeek,
      matchupsRef: matchups,
      playerCount: players.length,
      topStarters: topStarters,
      bottomStarters: bottomStarters,
      zeroPointStarters: zeroStarters,
      benchRegrets: regrets,
      lineupEfficiencies: efficiencies,
    );
  }

  /// Tính tổng điểm tối ưu theo [starterSlots] bằng thuật toán Min-Cost Max-Flow.
  static double _computeOptimalLineupPoints({
    required MatchupTeam matchupTeam,
    required List<String> starterSlots,
    required Map<String, Player> players,
  }) {
    if (starterSlots.isEmpty || matchupTeam.players.isEmpty) {
      return matchupTeam.points;
    }

    final candidateIds = matchupTeam.players
        .where((id) => id.isNotEmpty && id != '0')
        .toSet()
        .toList(growable: false);

    if (candidateIds.isEmpty) {
      return matchupTeam.points;
    }

    final slotCount = starterSlots.length;
    final playerCount = candidateIds.length;
    final source = 0;
    final sink = 1 + slotCount + playerCount;
    final totalNodes = sink + 1;

    final graph = List<List<_FlowEdge>>.generate(
      totalNodes,
      (_) => <_FlowEdge>[],
    );

    void addEdge(int from, int to, int cap, double cost) {
      final fwd = _FlowEdge(
        to: to,
        rev: graph[to].length,
        cap: cap,
        cost: cost,
      );
      final bwd = _FlowEdge(
        to: from,
        rev: graph[from].length,
        cap: 0,
        cost: -cost,
      );
      graph[from].add(fwd);
      graph[to].add(bwd);
    }

    for (var s = 0; s < slotCount; s++) {
      addEdge(source, 1 + s, 1, 0.0);
    }

    for (var p = 0; p < playerCount; p++) {
      final playerId = candidateIds[p];
      final player = players[playerId];
      final pts = matchupTeam.playersPoints[playerId] ?? 0.0;
      final playerNode = 1 + slotCount + p;

      addEdge(playerNode, sink, 1, 0.0);

      for (var s = 0; s < slotCount; s++) {
        if (_isPlayerEligibleForSlot(player, starterSlots[s])) {
          addEdge(1 + s, playerNode, 1, -pts);
        }
      }
    }

    var totalCost = 0.0;
    const inf = 1e18;
    const eps = 1e-9;

    while (true) {
      final dist = List<double>.filled(totalNodes, inf);
      final prevNode = List<int>.filled(totalNodes, -1);
      final prevEdge = List<int>.filled(totalNodes, -1);
      final inQueue = List<bool>.filled(totalNodes, false);
      final queue = Queue<int>();

      dist[source] = 0.0;
      queue.add(source);
      inQueue[source] = true;

      while (queue.isNotEmpty) {
        final u = queue.removeFirst();
        inQueue[u] = false;
        for (var i = 0; i < graph[u].length; i++) {
          final edge = graph[u][i];
          if (edge.cap > 0 && dist[u] + edge.cost + eps < dist[edge.to]) {
            dist[edge.to] = dist[u] + edge.cost;
            prevNode[edge.to] = u;
            prevEdge[edge.to] = i;
            if (!inQueue[edge.to]) {
              queue.add(edge.to);
              inQueue[edge.to] = true;
            }
          }
        }
      }

      if (prevNode[sink] == -1) {
        break;
      }

      totalCost += dist[sink];
      var cur = sink;
      while (cur != source) {
        final p = prevNode[cur];
        final idx = prevEdge[cur];
        final edge = graph[p][idx];
        edge.cap -= 1;
        graph[cur][edge.rev].cap += 1;
        cur = p;
      }
    }

    return -totalCost;
  }

  static bool _isPlayerEligibleForSlot(Player? player, String slot) {
    final normalizedSlot = slot.toUpperCase();
    if (normalizedSlot == 'UTIL' ||
        normalizedSlot == 'FLEX' ||
        normalizedSlot == 'BN') {
      return true;
    }

    if (player == null) {
      return false;
    }

    final positions = <String>{
      for (final pos in player.fantasyPositions) pos.toUpperCase(),
      if (player.position != '--' && player.position.isNotEmpty)
        player.position.toUpperCase(),
    };

    if (positions.isEmpty) {
      return false;
    }

    switch (normalizedSlot) {
      case 'G':
        return positions.contains('PG') ||
            positions.contains('SG') ||
            positions.contains('G');
      case 'F':
        return positions.contains('SF') ||
            positions.contains('PF') ||
            positions.contains('F');
      default:
        return positions.contains(normalizedSlot);
    }
  }
}

class _FlowEdge {
  _FlowEdge({
    required this.to,
    required this.rev,
    required this.cap,
    required this.cost,
  });

  final int to;
  final int rev;
  int cap;
  final double cost;
}
