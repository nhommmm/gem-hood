/// Thông tin giải đấu Sleeper NBA (thuần dữ liệu, không phụ thuộc UI).
class League {
  const League({
    required this.leagueId,
    required this.name,
    required this.season,
    required this.currentLeg,
    required this.rosterPositions,
  });

  final String leagueId;
  final String name;
  final String season;
  final int currentLeg;
  final List<String> rosterPositions;

  /// Danh sách nhãn vị trí cho đội hình chính (loại bỏ các slot 'BN').
  List<String> get starterSlots =>
      rosterPositions.where((pos) => pos != 'BN').toList(growable: false);

  factory League.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>?;
    final rawLeg = settings?['leg'];
    final leg = rawLeg is num && rawLeg.toInt() > 0 ? rawLeg.toInt() : 1;

    final rawPositions = json['roster_positions'] as List<dynamic>? ?? const [];
    final positions = rawPositions.map((e) => e.toString()).toList();

    return League(
      leagueId: (json['league_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      season: (json['season'] ?? '').toString(),
      currentLeg: leg,
      rosterPositions: positions,
    );
  }
}
