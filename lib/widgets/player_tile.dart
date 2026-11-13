import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/nba_game.dart';
import '../models/slot_player.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'injury_badge.dart';
import 'player_avatar.dart';

/// Một hàng hiển thị cầu thủ theo slot, ảnh, tên, vị trí/đội NBA, chấn thương và điểm tuần; nhận [slotPlayer] và [showPoints].
class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.slotPlayer,
    this.showPoints = false,
  });

  final SlotPlayer slotPlayer;
  final bool showPoints;

  @override
  Widget build(BuildContext context) {
    final player = slotPlayer.player;
    final isEmpty = slotPlayer.isEmptySlot;
    final displayName = isEmpty
        ? AppStrings.emptySlot
        : (player?.fullName ?? AppStrings.unknownPlayer);
    final posText = isEmpty
        ? AppStrings.unknownPosition
        : (player?.displayPosition ?? AppStrings.unknownPosition);
    final nbaTeam = isEmpty ? '' : (player?.team ?? AppStrings.freeAgentTeam);
    final subtitleText = isEmpty ? '' : '$posText • $nbaTeam';

    return Padding(
      padding: AppSpacing.compactListPadding,
      child: Row(
        children: [
          Container(
            width: AppSpacing.slotLabelWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: slotPlayer.isIr
                  ? AppColors.injurySevere.withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            alignment: Alignment.center,
            child: Text(
              slotPlayer.slotLabel,
              style: AppTextStyles.badge.copyWith(
                color: slotPlayer.isStarter
                    ? AppColors.accent
                    : (slotPlayer.isIr
                          ? AppColors.injurySevere
                          : AppColors.textSecondary),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PlayerAvatar(
            playerId: slotPlayer.playerId,
            fullName: displayName,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: isEmpty
                            ? AppTextStyles.bodyMuted
                            : AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isEmpty &&
                        player?.injuryStatus != null &&
                        player!.injuryStatus!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      InjuryBadge(status: player.injuryStatus),
                    ],
                  ],
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    subtitleText,
                    style: AppTextStyles.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!isEmpty && slotPlayer.weekSchedule != null) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  _PlayerWeekScheduleLine(schedule: slotPlayer.weekSchedule!),
                ],
              ],
            ),
          ),
          if (showPoints) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: AppSpacing.pointsColumnWidth,
              child: Text(
                (slotPlayer.points ?? 0.0).toStringAsFixed(2),
                style: AppTextStyles.scoreMedium,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerWeekScheduleLine extends StatelessWidget {
  const _PlayerWeekScheduleLine({required this.schedule});

  final PlayerWeekSchedule schedule;

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) {
      return const Text(
        AppStrings.scheduleNoGamesInWeek,
        style: AppTextStyles.bodyMuted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final pastStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textMuted,
      decoration: TextDecoration.lineThrough,
      decorationColor: AppColors.textMuted,
    );
    const activeStyle = AppTextStyles.caption;

    final spans = <InlineSpan>[];
    for (var i = 0; i < schedule.games.length; i++) {
      if (i > 0) {
        spans.add(const TextSpan(text: ' · ', style: activeStyle));
      }
      final game = schedule.games[i];
      spans.add(
        TextSpan(
          text: game.label,
          style: game.isPast ? pastStyle : activeStyle,
        ),
      );
    }
    spans.add(
      TextSpan(
        text: ' · ${schedule.count} ${AppStrings.scheduleWeekGamesSuffix}',
        style: activeStyle.copyWith(color: AppColors.accent),
      ),
    );

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
