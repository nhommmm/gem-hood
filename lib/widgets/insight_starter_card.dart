import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../providers/insights_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'player_avatar.dart';

/// Thẻ hiển thị Top 5 starter cao/thấp điểm nhất tuần kèm ghi chú cầu thủ 0 điểm; nhận [title], [items], [scoreColor], [zeroPointStarters].
class InsightStarterCard extends StatelessWidget {
  const InsightStarterCard({
    super.key,
    required this.title,
    required this.items,
    required this.scoreColor,
    this.zeroPointStarters = const [],
  });

  final String title;
  final List<StarterPerformance> items;
  final Color scoreColor;
  final List<StarterPerformance> zeroPointStarters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.sectionHeader),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              const Text(
                AppStrings.noPlayersInGroup,
                style: AppTextStyles.bodyMuted,
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _StarterInsightRow(
                  rank: i + 1,
                  item: items[i],
                  scoreColor: scoreColor,
                ),
              ],
            if (zeroPointStarters.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${AppStrings.insightsZeroStartersNotePrefix} ${zeroPointStarters.length} ${AppStrings.insightsZeroStartersNoteSuffix}: '
                '${zeroPointStarters.map((e) => e.slotPlayer.player?.fullName ?? AppStrings.unknownPlayer).join(', ')}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarterInsightRow extends StatelessWidget {
  const _StarterInsightRow({
    required this.rank,
    required this.item,
    required this.scoreColor,
  });

  final int rank;
  final StarterPerformance item;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    final playerName =
        item.slotPlayer.player?.fullName ?? AppStrings.unknownPlayer;
    final teamName = item.team?.teamName ?? AppStrings.unknownPlayer;

    return Row(
      children: [
        SizedBox(
          width: AppSpacing.rankColumnWidth,
          child: Text('$rank', style: AppTextStyles.cardSubtitle),
        ),
        PlayerAvatar(
          playerId: item.slotPlayer.playerId,
          fullName: playerName,
          size: AppSpacing.playerAvatarSmallSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerName,
                style: AppTextStyles.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.slotPlayer.slotLabel} • $teamName',
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          item.points.toStringAsFixed(2),
          style: AppTextStyles.scoreMedium.copyWith(color: scoreColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
