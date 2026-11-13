import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

/// Cấu hình giải đấu hiện tại của người dùng (League ID và username ưu tiên).
class LeagueConfig {
  const LeagueConfig({
    this.leagueId = AppConstants.defaultLeagueId,
    this.priorityUsername = AppConstants.defaultPriorityUsername,
  });

  final String leagueId;
  final String priorityUsername;

  bool get hasLeagueId => leagueId.trim().isNotEmpty;
}

/// Quản lý đọc/lưu cấu hình League ID & username qua URL (?league=&user=) và SharedPreferences.
class LeagueConfigService {
  static const String _leagueIdKey = 'gem_hood_league_id_v1';
  static const String _priorityUsernameKey = 'gem_hood_priority_username_v1';

  /// Tách tham số `league` và `user` từ URL (hỗ trợ cả query chuẩn lẫn fragment query).
  LeagueConfig? parseFromUri(Uri uri) {
    var leagueParam = uri.queryParameters['league']?.trim() ?? '';
    var userParam = uri.queryParameters['user']?.trim() ?? '';

    if (leagueParam.isEmpty && uri.fragment.contains('?')) {
      final queryPart = uri.fragment.substring(uri.fragment.indexOf('?') + 1);
      final fragmentParams = Uri.splitQueryString(queryPart);
      leagueParam = fragmentParams['league']?.trim() ?? '';
      if (userParam.isEmpty) {
        userParam = fragmentParams['user']?.trim() ?? '';
      }
    }

    if (leagueParam.isEmpty) {
      return null;
    }

    return LeagueConfig(
      leagueId: leagueParam,
      priorityUsername: userParam,
    );
  }

  /// Đọc cấu hình khởi động: ưu tiên tham số URL (`?league=ID&user=username`),
  /// sau đó mới đọc từ `SharedPreferences`.
  Future<LeagueConfig> loadInitialConfig({Uri? baseUri}) async {
    final fromUri = parseFromUri(baseUri ?? Uri.base);
    if (fromUri != null) {
      return fromUri;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLeagueId = prefs.getString(_leagueIdKey)?.trim() ?? '';
      final savedUsername = prefs.getString(_priorityUsernameKey)?.trim() ?? '';
      if (savedLeagueId.isEmpty) {
        return const LeagueConfig();
      }
      return LeagueConfig(
        leagueId: savedLeagueId,
        priorityUsername: savedUsername,
      );
    } catch (_) {
      return const LeagueConfig();
    }
  }

  /// Lưu League ID và username ưu tiên vào `SharedPreferences`.
  Future<void> saveConfig(LeagueConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_leagueIdKey, config.leagueId.trim());
      await prefs.setString(
        _priorityUsernameKey,
        config.priorityUsername.trim(),
      );
    } catch (_) {
      // Bỏ qua lỗi ghi storage cục bộ để không chặn luồng người dùng.
    }
  }

  /// Xóa cấu hình đã lưu trong `SharedPreferences`.
  Future<void> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_leagueIdKey);
      await prefs.remove(_priorityUsernameKey);
    } catch (_) {
      // Bỏ qua lỗi xóa storage cục bộ.
    }
  }
}
