import 'package:material_ui/material_ui.dart';

import '../models/team.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'team_avatar.dart';

/// Một hàng trong bảng xếp hạng Standings; nhận [rank], [team], [isPriority], [onTap].
class StandingsRow extends StatelessWidget {
  const StandingsRow({
    super.key,
    required this.rank,
    required this.team,
    required this.isPriority,
    this.onTap,
  });

  final int rank;
  final Team team;
  final bool isPriority;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isPriority ? AppColors.accent : AppColors.border,
          width: isPriority ? AppSpacing.borderSelected : AppSpacing.borderThin,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              SizedBox(
                width: AppSpacing.rankColumnWidth,
                child: Text(
                  '$rank',
                  style: AppTextStyles.scoreMedium.copyWith(
                    color: rank == 1 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              TeamAvatar(
                avatar: team.avatar,
                teamName: team.teamName,
                size: AppSpacing.teamAvatarSmallSize,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      team.teamName,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      team.username,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: AppSpacing.recordColumnWidth,
                child: Text(
                  team.recordText,
                  style: AppTextStyles.scoreMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: AppSpacing.fptsColumnWidth,
                child: Text(
                  team.fpts.toStringAsFixed(2),
                  style: AppTextStyles.scoreMedium.copyWith(
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
