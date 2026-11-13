import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/matchup.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'team_avatar.dart';

/// Thẻ hiển thị một cặp đấu gồm 2 đội và tổng điểm; nhận [pair], [isSelected], [onTap].
class MatchupCard extends StatelessWidget {
  const MatchupCard({
    super.key,
    required this.pair,
    required this.isSelected,
    required this.onTap,
  });

  final MatchupPair pair;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final home = pair.home;
    final away = pair.away;
    final homePoints = home.points;
    final awayPoints = away?.points ?? 0.0;
    final homeLeading = away != null && homePoints > awayPoints;
    final awayLeading = away != null && awayPoints > homePoints;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected
              ? AppSpacing.borderSelected
              : AppSpacing.borderThin,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MatchupTeamSummaryRow(
                teamName: home.team?.teamName ?? 'Roster ${home.rosterId}',
                recordText: home.team?.recordText ?? '',
                avatar: home.team?.avatar,
                points: homePoints,
                isLeading: homeLeading,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              if (away != null)
                _MatchupTeamSummaryRow(
                  teamName: away.team?.teamName ?? 'Roster ${away.rosterId}',
                  recordText: away.team?.recordText ?? '',
                  avatar: away.team?.avatar,
                  points: awayPoints,
                  isLeading: awayLeading,
                )
              else
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.byeLabel,
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchupTeamSummaryRow extends StatelessWidget {
  const _MatchupTeamSummaryRow({
    required this.teamName,
    required this.recordText,
    required this.avatar,
    required this.points,
    required this.isLeading,
  });

  final String teamName;
  final String recordText;
  final String? avatar;
  final double points;
  final bool isLeading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamAvatar(
          avatar: avatar,
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
              if (recordText.isNotEmpty)
                Text(
                  recordText,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          points.toStringAsFixed(2),
          style: isLeading
              ? AppTextStyles.scoreLargeWinner
              : AppTextStyles.scoreLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
