import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trade.dart';

/// Quản lý cache cục bộ các giao dịch trade của những tuần đã qua trong SharedPreferences.
class TradeCache {
  static String _weekKey(String leagueId, int week) =>
      'sleeper_trades_${leagueId}_week_$week';

  /// Đọc danh sách trade đã cache cho [week] của [leagueId]; trả về null nếu chưa có.
  Future<List<TradeTransaction>?> loadWeekTrades(
    String leagueId,
    int week,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_weekKey(leagueId, week));
      if (rawJson == null || rawJson.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => TradeTransaction.fromJson(item, week: week))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Lưu danh sách trade của [week] vào SharedPreferences.
  Future<void> saveWeekTrades(
    String leagueId,
    int week,
    List<TradeTransaction> trades,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        trades.map((e) => e.toJson()).toList(growable: false),
      );
      await prefs.setString(_weekKey(leagueId, week), encoded);
    } catch (_) {
      // Bỏ qua lỗi ghi cache để không làm gián đoạn luồng chính.
    }
  }
}
