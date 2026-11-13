import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Thanh chọn tuần thi đấu (từ 1 đến [maxWeek]); nhận [selectedWeek], [maxWeek], [onWeekSelected].
class WeekSelector extends StatelessWidget {
  const WeekSelector({
    super.key,
    required this.selectedWeek,
    required this.maxWeek,
    required this.onWeekSelected,
  });

  final int selectedWeek;
  final int maxWeek;
  final ValueChanged<int> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final weeks = List<int>.generate(maxWeek < 1 ? 1 : maxWeek, (i) => i + 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: selectedWeek > 1
                  ? () => onWeekSelected(selectedWeek - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: weeks.contains(selectedWeek) ? selectedWeek : weeks.last,
                dropdownColor: AppColors.card,
                style: AppTextStyles.cardTitle,
                iconEnabledColor: AppColors.primary,
                items: weeks
                    .map(
                      (week) => DropdownMenuItem<int>(
                        value: week,
                        child: Text(
                          '${AppStrings.weekPrefix} $week',
                          style: AppTextStyles.cardTitle,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onWeekSelected(value);
                  }
                },
              ),
            ),
            IconButton(
              onPressed: selectedWeek < maxWeek
                  ? () => onWeekSelected(selectedWeek + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
