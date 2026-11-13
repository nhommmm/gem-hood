import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Nhãn hiển thị trạng thái chấn thương của cầu thủ; nhận chuỗi [status] (ẩn nếu null/rỗng).
class InjuryBadge extends StatelessWidget {
  const InjuryBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = status?.trim();
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    final upper = value.toUpperCase();
    final isSevere =
        upper == 'OUT' ||
        upper == 'IR' ||
        upper == 'SUS' ||
        upper == 'OFS' ||
        upper == 'NA';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + AppSpacing.xs / 2,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: isSevere ? AppColors.injurySevere : AppColors.injuryMild,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        upper,
        style: AppTextStyles.badge.copyWith(color: AppColors.injuryText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
