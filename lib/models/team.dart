/// Thông tin một đội trong giải, ghép từ roster và user của Sleeper (thuần dữ liệu).
class Team {
  const Team({
    required this.rosterId,
    required this.ownerId,
    required this.username,
    required this.teamName,
    this.avatar,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.fpts,
    required this.fptsAgainst,
    required this.players,
    required this.starters,
    required this.reserve,
    required this.taxi,
  });

  final int rosterId;
  final String ownerId;
  final String username;
  final String teamName;
  final String? avatar;
  final int wins;
  final int losses;
  final int ties;
  final double fpts;
  final double fptsAgainst;
  final List<String> players;
  final List<String> starters;
  final List<String> reserve;
  final List<String> taxi;

  /// Kiểm tra đội này có thuộc [priorityUsername] hay không.
  bool isOwnedBy(String priorityUsername) {
    final target = priorityUsername.trim();
    if (target.isEmpty) {
      return false;
    }
    return username.toLowerCase() == target.toLowerCase();
  }

  /// Danh sách player_id dự bị (players trừ starters và reserve/taxi).
  List<String> get benchPlayers {
    final excluded = <String>{...starters, ...reserve, ...taxi};
    return players.where((id) => !excluded.contains(id)).toList(growable: false);
  }

  /// Chuỗi thành tích thắng - thua (kèm hòa nếu có).
  String get recordText => ties > 0 ? '$wins-$losses-$ties' : '$wins-$losses';

  /// Ghép dữ liệu từ một roster JSON và user JSON tương ứng (user có thể null).
  factory Team.fromRosterAndUser({
    required Map<String, dynamic> rosterJson,
    Map<String, dynamic>? userJson,
  }) {
    final rosterId = (rosterJson['roster_id'] as num?)?.toInt() ?? 0;
    final ownerId = (rosterJson['owner_id'] ?? '').toString();

    final displayName = (userJson?['display_name'] ?? '').toString().trim();
    final userMetadata = userJson?['metadata'] as Map<String, dynamic>?;
    final rawTeamName = (userMetadata?['team_name'] ?? '').toString().trim();
    final teamName = rawTeamName.isNotEmpty
        ? rawTeamName
        : (displayName.isNotEmpty ? displayName : 'Team $rosterId');

    final rawAvatar = userJson?['avatar']?.toString().trim();
    final avatar = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? rawAvatar
        : null;

    final settings = rosterJson['settings'] as Map<String, dynamic>? ?? const {};
    final wins = (settings['wins'] as num?)?.toInt() ?? 0;
    final losses = (settings['losses'] as num?)?.toInt() ?? 0;
    final ties = (settings['ties'] as num?)?.toInt() ?? 0;

    final fptsWhole = (settings['fpts'] as num?)?.toDouble() ?? 0.0;
    final fptsDec = (settings['fpts_decimal'] as num?)?.toDouble() ?? 0.0;
    final fpts = fptsWhole + fptsDec / 100.0;

    final fptsAgainstWhole =
        (settings['fpts_against'] as num?)?.toDouble() ?? 0.0;
    final fptsAgainstDec =
        (settings['fpts_against_decimal'] as num?)?.toDouble() ?? 0.0;
    final fptsAgainst = fptsAgainstWhole + fptsAgainstDec / 100.0;

    return Team(
      rosterId: rosterId,
      ownerId: ownerId,
      username: displayName,
      teamName: teamName,
      avatar: avatar,
      wins: wins,
      losses: losses,
      ties: ties,
      fpts: fpts,
      fptsAgainst: fptsAgainst,
      players: _parseStringList(rosterJson['players']),
      starters: _parseStringList(rosterJson['starters']),
      reserve: _parseStringList(rosterJson['reserve']),
      taxi: _parseStringList(rosterJson['taxi']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
