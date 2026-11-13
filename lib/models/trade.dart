import 'player.dart';
import 'team.dart';

/// Thông tin một lượt pick draft được trao đổi trong trade (thuần dữ liệu).
class TradeDraftPick {
  const TradeDraftPick({
    required this.season,
    required this.round,
    required this.originalRosterId,
    required this.previousOwnerId,
    required this.ownerId,
  });

  final String season;
  final int round;
  final int originalRosterId;
  final int previousOwnerId;
  final int ownerId;

  factory TradeDraftPick.fromJson(Map<String, dynamic> json) {
    return TradeDraftPick(
      season: (json['season'] ?? '').toString(),
      round: (json['round'] as num?)?.toInt() ?? 0,
      originalRosterId: (json['roster_id'] as num?)?.toInt() ?? 0,
      previousOwnerId: (json['previous_owner_id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'round': round,
      'roster_id': originalRosterId,
      'previous_owner_id': previousOwnerId,
      'owner_id': ownerId,
    };
  }
}

/// Giao dịch trade đã hoàn tất lấy từ Sleeper transactions API (thuần dữ liệu).
class TradeTransaction {
  const TradeTransaction({
    required this.transactionId,
    required this.week,
    required this.timestampMs,
    required this.rosterIds,
    required this.adds,
    required this.drops,
    required this.draftPicks,
  });

  final String transactionId;
  final int week;
  final int timestampMs;
  final List<int> rosterIds;

  /// Map player_id -> roster_id nhận cầu thủ.
  final Map<String, int> adds;

  /// Map player_id -> roster_id nhường cầu thủ.
  final Map<String, int> drops;

  final List<TradeDraftPick> draftPicks;

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  /// Danh sách tất cả player_id xuất hiện trong giao dịch.
  Set<String> get allPlayerIds => {...adds.keys, ...drops.keys};

  factory TradeTransaction.fromJson(
    Map<String, dynamic> json, {
    required int week,
  }) {
    final rawRosterIds = json['roster_ids'] as List<dynamic>? ?? const [];
    final rosterIds = rawRosterIds
        .whereType<num>()
        .map((e) => e.toInt())
        .toList(growable: false);

    final rawAdds = json['adds'] as Map<String, dynamic>? ?? const {};
    final adds = <String, int>{
      for (final entry in rawAdds.entries)
        if (entry.value is num) entry.key: (entry.value as num).toInt(),
    };

    final rawDrops = json['drops'] as Map<String, dynamic>? ?? const {};
    final drops = <String, int>{
      for (final entry in rawDrops.entries)
        if (entry.value is num) entry.key: (entry.value as num).toInt(),
    };

    final rawPicks = json['draft_picks'] as List<dynamic>? ?? const [];
    final draftPicks = rawPicks
        .whereType<Map<String, dynamic>>()
        .map(TradeDraftPick.fromJson)
        .toList(growable: false);

    final statusUpdated = (json['status_updated'] as num?)?.toInt();
    final created = (json['created'] as num?)?.toInt();
    final parsedLeg = (json['leg'] as num?)?.toInt();

    return TradeTransaction(
      transactionId: (json['transaction_id'] ?? '').toString(),
      week: parsedLeg != null && parsedLeg > 0 ? parsedLeg : week,
      timestampMs: statusUpdated ?? created ?? 0,
      rosterIds: rosterIds,
      adds: adds,
      drops: drops,
      draftPicks: draftPicks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'leg': week,
      'status_updated': timestampMs,
      'roster_ids': rosterIds,
      'adds': adds,
      'drops': drops,
      'draft_picks': draftPicks.map((e) => e.toJson()).toList(growable: false),
    };
  }
}

/// Chi tiết phần nhận và nhường của một đội trong một giao dịch trade (thuần dữ liệu).
class TradeSide {
  const TradeSide({
    required this.rosterId,
    this.team,
    required this.receivedPlayers,
    required this.sentPlayers,
    required this.receivedPicks,
    required this.sentPicks,
  });

  final int rosterId;
  final Team? team;
  final List<Player> receivedPlayers;
  final List<Player> sentPlayers;
  final List<TradeDraftPick> receivedPicks;
  final List<TradeDraftPick> sentPicks;
}

/// Model hoàn chỉnh truyền cho widget TradeCard hiển thị (thuần dữ liệu).
class TradeDisplay {
  const TradeDisplay({
    required this.transaction,
    required this.sides,
    required this.teamsByRosterId,
    required this.involvesPriorityTeam,
  });

  final TradeTransaction transaction;
  final List<TradeSide> sides;
  final Map<int, Team> teamsByRosterId;
  final bool involvesPriorityTeam;
}
