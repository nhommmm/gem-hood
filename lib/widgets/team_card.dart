import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/team.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'team_avatar.dart';

/// Thẻ hiển thị tóm tắt một đội trong danh sách Teams; nhận [team], [isSelected], [isPriority], [onTap].
class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.isSelected,
    required this.isPriority,
    required this.onTap,
  });

  final Team team;
  final bool isSelected;
  final bool isPriority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      child: ListTile(
        onTap: onTap,
        leading: TeamAvatar(avatar: team.avatar, teamName: team.teamName),
        title: Row(
          children: [
            Flexible(
              child: Text(
                team.teamName,
                style: AppTextStyles.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPriority) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + AppSpacing.xs / 2,
                  vertical: AppSpacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  AppStrings.yourTeamBadge,
                  style: AppTextStyles.badgeInverse,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${team.username} • ${team.recordText}',
          style: AppTextStyles.cardSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          team.fpts.toStringAsFixed(1),
          style: AppTextStyles.scoreMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
