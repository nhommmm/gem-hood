/// Thông tin cơ bản của một cầu thủ NBA từ Sleeper (thuần dữ liệu).
class Player {
  const Player({
    required this.playerId,
    required this.fullName,
    required this.position,
    required this.fantasyPositions,
    this.team,
    this.injuryStatus,
  });

  final String playerId;
  final String fullName;
  final String position;
  final List<String> fantasyPositions;
  final String? team;
  final String? injuryStatus;

  /// Chuỗi vị trí hiển thị gọn (ưu tiên fantasyPositions, fallback position).
  String get displayPosition {
    if (fantasyPositions.isNotEmpty) {
      return fantasyPositions.join('/');
    }
    return position;
  }

  factory Player.fromJson(String id, Map<String, dynamic> json) {
    final rawFantasy = json['fantasy_positions'] as List<dynamic>? ?? const [];
    final fantasyPositions = rawFantasy
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final rawPosition = (json['position'] ?? '').toString();
    final position = rawPosition.isNotEmpty
        ? rawPosition
        : (fantasyPositions.isNotEmpty ? fantasyPositions.first : '--');

    final rawFullName = (json['full_name'] ?? '').toString().trim();
    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final fallbackName = '$firstName $lastName'.trim();
    final fullName = rawFullName.isNotEmpty
        ? rawFullName
        : (fallbackName.isNotEmpty ? fallbackName : 'ID $id');

    final rawTeam = json['team']?.toString().trim();
    final rawInjury = json['injury_status']?.toString().trim();

    return Player(
      playerId: id,
      fullName: fullName,
      position: position,
      fantasyPositions: fantasyPositions,
      team: (rawTeam != null && rawTeam.isNotEmpty) ? rawTeam : null,
      injuryStatus: (rawInjury != null && rawInjury.isNotEmpty)
          ? rawInjury
          : null,
    );
  }

  /// Tạo bản thể mặc định khi không tìm thấy playerId trong dữ liệu NBA.
  factory Player.unknown(String id) {
    return Player(
      playerId: id,
      fullName: 'ID $id',
      position: '--',
      fantasyPositions: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'position': position,
      'fantasy_positions': fantasyPositions,
      'team': team,
      'injury_status': injuryStatus,
    };
  }
}
