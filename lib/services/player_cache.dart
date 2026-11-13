import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/player.dart';

/// Quản lý cache cục bộ danh sách cầu thủ NBA trong SharedPreferences (hết hạn sau 24h).
class PlayerCache {
  static const String _cacheDataKey = 'sleeper_nba_players_data_v1';
  static const String _cacheTimestampKey = 'sleeper_nba_players_ts_v1';

  /// Đọc cache cầu thủ còn hiệu lực (chưa quá [AppConstants.cacheDuration]).
  /// Trả về null nếu chưa có cache hoặc đã hết hạn.
  Future<Map<String, Player>?> loadValidCache() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampMs = prefs.getInt(_cacheTimestampKey);
    final rawJson = prefs.getString(_cacheDataKey);
    if (timestampMs == null || rawJson == null || rawJson.isEmpty) {
      return null;
    }

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    if (DateTime.now().difference(cachedAt) >= AppConstants.cacheDuration) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      return decoded.map(
        (id, value) => MapEntry(
          id,
          Player.fromJson(id, Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lưu danh sách cầu thủ đã lọc vào SharedPreferences kèm thời điểm hiện tại.
  Future<void> saveCache(Map<String, Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMap = <String, dynamic>{
      for (final entry in players.entries) entry.key: entry.value.toJson(),
    };
    await prefs.setString(_cacheDataKey, jsonEncode(encodedMap));
    await prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Xóa toàn bộ cache cầu thủ.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheDataKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
