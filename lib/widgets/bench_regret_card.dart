import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../providers/insights_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'player_avatar.dart';

/// Thẻ hiển thị danh sách cầu thủ Bench ghi điểm cao hơn starter thấp nhất cùng đội; nhận [regrets].
class BenchRegretCard extends StatelessWidget {
  const BenchRegretCard({super.key, required this.regrets});

  final List<BenchRegret> regrets;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.insightsBenchRegretTitle,
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (regrets.isEmpty)
              const Text(
                AppStrings.insightsBenchRegretEmpty,
                style: AppTextStyles.bodyMuted,
              )
            else
              for (var i = 0; i < regrets.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _BenchRegretRow(regret: regrets[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _BenchRegretRow extends StatelessWidget {
  const _BenchRegretRow({required this.regret});

  final BenchRegret regret;

  @override
  Widget build(BuildContext context) {
    final benchName =
        regret.benchPlayer.player?.fullName ?? AppStrings.unknownPlayer;
    final benchPts = (regret.benchPlayer.points ?? 0.0).toStringAsFixed(2);
    final starterName =
        regret.lowestStarter.player?.fullName ?? AppStrings.unknownPlayer;
    final starterPts = (regret.lowestStarter.points ?? 0.0).toStringAsFixed(2);
    final teamName = regret.team?.teamName ?? AppStrings.unknownPlayer;

    return Row(
      children: [
        PlayerAvatar(
          playerId: regret.benchPlayer.playerId,
          fullName: benchName,
          size: AppSpacing.playerAvatarSmallSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$benchName ($benchPts)',
                style: AppTextStyles.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$teamName • ${AppStrings.insightsOverStarterPrefix} $starterName ($starterPts)',
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: AppSpacing.badgePadding,
          decoration: BoxDecoration(
            color: AppColors.injuryMild.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            '${AppStrings.insightsMissedPrefix} +${regret.missedPoints.toStringAsFixed(2)}',
            style: AppTextStyles.badge.copyWith(color: AppColors.injuryMild),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
