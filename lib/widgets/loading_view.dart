import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Hiển thị vòng xoay đang tải ở giữa màn hình; nhận thông điệp tùy chọn [message].
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? AppStrings.loadingMessage,
              style: AppTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
