import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../providers/insights_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'team_avatar.dart';

/// Thẻ hiển thị đội có lineup hiệu quả nhất tuần và bảng xếp hạng hiệu quả các đội; nhận [efficiencies].
class LineupEfficiencyCard extends StatelessWidget {
  const LineupEfficiencyCard({super.key, required this.efficiencies});

  final List<LineupEfficiency> efficiencies;

  @override
  Widget build(BuildContext context) {
    final best = efficiencies.isNotEmpty ? efficiencies.first : null;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.insightsLineupEfficiencyTitle,
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (best == null)
              const Text(
                AppStrings.insightsNoData,
                style: AppTextStyles.bodyMuted,
              )
            else ...[
              _BestEfficiencyBanner(item: best),
              if (efficiencies.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 1; i < efficiencies.length; i++) ...[
                  if (i > 1) const SizedBox(height: AppSpacing.xs),
                  _EfficiencyRow(rank: i + 1, item: efficiencies[i]),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BestEfficiencyBanner extends StatelessWidget {
  const _BestEfficiencyBanner({required this.item});

  final LineupEfficiency item;

  @override
  Widget build(BuildContext context) {
    final teamName = item.team?.teamName ?? AppStrings.unknownPlayer;
    final progress = (item.efficiencyPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.accent,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TeamAvatar(
                avatar: item.team?.avatar,
                teamName: teamName,
                size: AppSpacing.teamAvatarSmallSize,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${AppStrings.insightsActualOptimalLabel}: '
                      '${item.actualPoints.toStringAsFixed(2)} / ${item.optimalPoints.toStringAsFixed(2)}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: AppSpacing.badgePadding,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      AppStrings.insightsBestEfficiencyBadge,
                      style: AppTextStyles.badgeInverse,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${item.efficiencyPercent.toStringAsFixed(1)}%',
                    style: AppTextStyles.scoreMedium.copyWith(
                      color: AppColors.win,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.card,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EfficiencyRow extends StatelessWidget {
  const _EfficiencyRow({required this.rank, required this.item});

  final int rank;
  final LineupEfficiency item;

  @override
  Widget build(BuildContext context) {
    final teamName = item.team?.teamName ?? AppStrings.unknownPlayer;

    return Row(
      children: [
        SizedBox(
          width: AppSpacing.rankColumnWidth,
          child: Text('$rank', style: AppTextStyles.caption),
        ),
        Expanded(
          child: Text(
            teamName,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${item.actualPoints.toStringAsFixed(1)}/${item.optimalPoints.toStringAsFixed(1)}',
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: AppSpacing.recordColumnWidth,
          child: Text(
            '${item.efficiencyPercent.toStringAsFixed(1)}%',
            style: AppTextStyles.scoreMedium,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
