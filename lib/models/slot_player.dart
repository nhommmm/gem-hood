import 'nba_game.dart';
import 'player.dart';

/// Kết hợp cầu thủ với vị trí slot (PG, SG, BN, IR...) và điểm số tuần nếu có.
class SlotPlayer {
  const SlotPlayer({
    required this.playerId,
    required this.slotLabel,
    this.player,
    this.points,
    this.isStarter = false,
    this.isIr = false,
    this.weekSchedule,
  });

  final String playerId;
  final String slotLabel;
  final Player? player;
  final double? points;
  final bool isStarter;
  final bool isIr;
  final PlayerWeekSchedule? weekSchedule;

  /// Có phải slot trống của Sleeper ('0') hay không.
  bool get isEmptySlot => playerId == '0' || playerId.isEmpty;
}
