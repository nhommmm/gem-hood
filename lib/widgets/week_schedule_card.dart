import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../models/nba_game.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Bảng tóm tắt lịch tuần fantasy của đội người dùng (7 cột Thứ 3 → Thứ 2, kèm chuyển tuần); nhận [teamName], [weekRangeLabel], [weekLabel], [isCurrentWeek], [days], [onPreviousWeek], [onNextWeek], [onResetCurrentWeek].
class WeekScheduleCard extends StatelessWidget {
  const WeekScheduleCard({
    super.key,
    required this.teamName,
    required this.weekRangeLabel,
    required this.weekLabel,
    required this.isCurrentWeek,
    required this.days,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onResetCurrentWeek,
  });

  final String teamName;
  final String weekRangeLabel;
  final String weekLabel;
  final bool isCurrentWeek;
  final List<ScheduleDayCount> days;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onResetCurrentWeek;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.scheduleSectionTitle,
                    style: AppTextStyles.sectionHeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onPreviousWeek,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_left, size: AppSpacing.iconMd),
                ),
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: isCurrentWeek ? null : onResetCurrentWeek,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    padding: AppSpacing.badgePadding,
                    decoration: BoxDecoration(
                      color: isCurrentWeek
                          ? AppColors.primary
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      weekLabel,
                      style: isCurrentWeek
                          ? AppTextStyles.badge.copyWith(
                              color: AppColors.onPrimary,
                            )
                          : AppTextStyles.badge,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: onNextWeek,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.chevron_right,
                    size: AppSpacing.iconMd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              weekRangeLabel,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            Text(
              teamName,
              style: AppTextStyles.cardSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _DayCountCell(item: days[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCountCell extends StatelessWidget {
  const _DayCountCell({required this.item});

  final ScheduleDayCount item;

  @override
  Widget build(BuildContext context) {
    final weekday = AppStrings.scheduleWeekdaysShort[item.date.weekday - 1];
    final dateLabel = '${item.date.day}/${item.date.month}';
    final count = item.playerCount;
    final countColor = count >= 8
        ? AppColors.accent
        : (count <= 3 ? AppColors.injuryMild : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weekday,
            style: AppTextStyles.badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            dateLabel,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count',
            style: AppTextStyles.scoreMedium.copyWith(color: countColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
