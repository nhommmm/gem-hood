/// Bảng quy đổi mã viết tắt đội NBA giữa các nguồn lịch (ESPN/NBA CDN) và Sleeper.
abstract final class TeamCodes {
  /// Map từ mã viết tắt nguồn ngoài -> mã chuẩn của Sleeper (30 đội NBA).
  static const Map<String, String> scheduleToSleeper = {
    'GS': 'GSW',
    'NO': 'NOP',
    'NY': 'NYK',
    'SA': 'SAS',
    'PHO': 'PHX',
    'WSH': 'WAS',
    'UTAH': 'UTA',
    'BRK': 'BKN',
    'CHO': 'CHA',
  };

  /// Danh sách đầy đủ 30 mã đội NBA chuẩn trên Sleeper.
  static const Set<String> allSleeperTeams = {
    'ATL',
    'BKN',
    'BOS',
    'CHA',
    'CHI',
    'CLE',
    'DAL',
    'DEN',
    'DET',
    'GSW',
    'HOU',
    'IND',
    'LAC',
    'LAL',
    'MEM',
    'MIA',
    'MIL',
    'MIN',
    'NOP',
    'NYK',
    'OKC',
    'ORL',
    'PHI',
    'PHX',
    'POR',
    'SAC',
    'SAS',
    'TOR',
    'UTA',
    'WAS',
  };

  /// Chuẩn hóa mã đội từ nguồn lịch hoặc Sleeper về mã chuẩn Sleeper.
  static String normalize(String code) {
    final upper = code.trim().toUpperCase();
    return scheduleToSleeper[upper] ?? upper;
  }

  /// Kiểm tra xem mã đội có hợp lệ (không phải TBD/rỗng) hay không.
  static bool isValidTeam(String code) {
    final normalized = normalize(code);
    return normalized.isNotEmpty && normalized != 'TBD';
  }
}
