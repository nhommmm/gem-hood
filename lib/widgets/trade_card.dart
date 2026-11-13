import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/trade.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'player_avatar.dart';
import 'team_avatar.dart';

/// Thẻ hiển thị một giao dịch trade hoàn tất (các đội tham gia, cầu thủ nhận/nhường, draft picks, thời gian); nhận [trade].
class TradeCard extends StatelessWidget {
  const TradeCard({super.key, required this.trade});

  final TradeDisplay trade;

  @override
  Widget build(BuildContext context) {
    final tx = trade.transaction;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: trade.involvesPriorityTeam
              ? AppColors.accent
              : AppColors.border,
          width: trade.involvesPriorityTeam
              ? AppSpacing.borderSelected
              : AppSpacing.borderThin,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: AppSpacing.badgePadding,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${AppStrings.weekPrefix} ${tx.week}',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    _formatTimestamp(tx.timestamp),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < trade.sides.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
              ],
              _TradeSideSection(
                side: trade.sides[i],
                teamsByRosterId: trade.teamsByRosterId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _TradeSideSection extends StatelessWidget {
  const _TradeSideSection({
    required this.side,
    required this.teamsByRosterId,
  });

  final TradeSide side;
  final Map<int, Team> teamsByRosterId;

  @override
  Widget build(BuildContext context) {
    final teamName = side.team?.teamName ?? 'Roster ${side.rosterId}';
    final hasReceived =
        side.receivedPlayers.isNotEmpty || side.receivedPicks.isNotEmpty;
    final hasSent = side.sentPlayers.isNotEmpty || side.sentPicks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TeamAvatar(
              avatar: side.team?.avatar,
              teamName: teamName,
              size: AppSpacing.teamAvatarSmallSize,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                teamName,
                style: AppTextStyles.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasReceived && !hasSent)
          const Text(AppStrings.tradeEmptySide, style: AppTextStyles.bodyMuted),
        if (hasReceived) ...[
          _DirectionHeader(
            label: AppStrings.tradeReceivedLabel,
            color: AppColors.win,
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...side.receivedPlayers.map(
            (player) => _TradePlayerRow(player: player),
          ),
          ...side.receivedPicks.map(
            (pick) => _TradePickRow(
              pick: pick,
              teamsByRosterId: teamsByRosterId,
              isReceived: true,
            ),
          ),
        ],
        if (hasReceived && hasSent) const SizedBox(height: AppSpacing.sm),
        if (hasSent) ...[
          _DirectionHeader(
            label: AppStrings.tradeSentLabel,
            color: AppColors.loss,
            icon: Icons.remove_circle_outline,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...side.sentPlayers.map(
            (player) => _TradePlayerRow(player: player),
          ),
          ...side.sentPicks.map(
            (pick) => _TradePickRow(
              pick: pick,
              teamsByRosterId: teamsByRosterId,
              isReceived: false,
            ),
          ),
        ],
      ],
    );
  }
}

class _DirectionHeader extends StatelessWidget {
  const _DirectionHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSm, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.badge.copyWith(color: color),
        ),
      ],
    );
  }
}

class _TradePlayerRow extends StatelessWidget {
  const _TradePlayerRow({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final nbaTeam = player.team ?? AppStrings.freeAgentTeam;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          PlayerAvatar(
            playerId: player.playerId,
            fullName: player.fullName,
            size: AppSpacing.playerAvatarSmallSize,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              player.fullName,
              style: AppTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${player.displayPosition} • $nbaTeam',
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TradePickRow extends StatelessWidget {
  const _TradePickRow({
    required this.pick,
    required this.teamsByRosterId,
    required this.isReceived,
  });

  final TradeDraftPick pick;
  final Map<int, Team> teamsByRosterId;
  final bool isReceived;

  @override
  Widget build(BuildContext context) {
    final originTeam = teamsByRosterId[pick.originalRosterId]?.teamName ??
        'Roster ${pick.originalRosterId}';
    final pickLabel =
        '${pick.season} ${AppStrings.tradePickRoundPrefix} ${pick.round} (${AppStrings.tradePickOriginPrefix} $originTeam)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: AppSpacing.iconSm,
            color: isReceived ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              pickLabel,
              style: AppTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
