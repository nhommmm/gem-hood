import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Hiển thị thông báo lỗi kèm nút thử lại; nhận [message] và callback [onRetry].
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.loss,
              size: AppSpacing.iconLg,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: AppSpacing.iconSm),
              label: const Text(AppStrings.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
