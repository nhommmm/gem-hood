import 'team.dart';

/// Dữ liệu một đội trong một tuần thi đấu cụ thể (thuần dữ liệu).
class MatchupTeam {
  const MatchupTeam({
    required this.rosterId,
    required this.matchupId,
    required this.points,
    required this.starters,
    required this.startersPoints,
    required this.players,
    required this.playersPoints,
    this.team,
  });

  final int rosterId;
  final int matchupId;
  final double points;
  final List<String> starters;
  final List<double> startersPoints;
  final List<String> players;
  final Map<String, double> playersPoints;
  final Team? team;

  /// Danh sách cầu thủ dự bị trong tuần (players trừ starters).
  List<String> get benchPlayers {
    final starterSet = starters.toSet();
    return players
        .where((id) => !starterSet.contains(id))
        .toList(growable: false);
  }

  /// Trả về bản sao gắn thêm thông tin [Team].
  MatchupTeam withTeam(Team? resolvedTeam) {
    return MatchupTeam(
      rosterId: rosterId,
      matchupId: matchupId,
      points: points,
      starters: starters,
      startersPoints: startersPoints,
      players: players,
      playersPoints: playersPoints,
      team: resolvedTeam,
    );
  }

  factory MatchupTeam.fromJson(Map<String, dynamic> json) {
    final rawStarters = json['starters'] as List<dynamic>? ?? const [];
    final starters = rawStarters
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList(growable: false);

    final rawStarterPoints =
        json['starters_points'] as List<dynamic>? ?? const [];
    final startersPoints = rawStarterPoints
        .map((e) => (e is num) ? e.toDouble() : 0.0)
        .toList(growable: false);

    final rawPlayers = json['players'] as List<dynamic>? ?? const [];
    final players = rawPlayers
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList(growable: false);

    final rawPlayersPoints =
        json['players_points'] as Map<String, dynamic>? ?? const {};
    final playersPoints = <String, double>{
      for (final entry in rawPlayersPoints.entries)
        entry.key: (entry.value is num) ? (entry.value as num).toDouble() : 0.0,
    };

    return MatchupTeam(
      rosterId: (json['roster_id'] as num?)?.toInt() ?? 0,
      matchupId: (json['matchup_id'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      starters: starters,
      startersPoints: startersPoints,
      players: players,
      playersPoints: playersPoints,
    );
  }
}

/// Một cặp đấu gồm 2 đội có cùng matchup_id trong tuần.
class MatchupPair {
  const MatchupPair({
    required this.matchupId,
    required this.home,
    this.away,
  });

  final int matchupId;
  final MatchupTeam home;
  final MatchupTeam? away;
}
