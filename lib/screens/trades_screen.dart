import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_retry.dart';
import '../widgets/loading_view.dart';
import '../widgets/trade_card.dart';

/// Màn hình lịch sử các giao dịch trade của giải kèm bộ lọc (chỉ ghép widget).
class TradesScreen extends StatelessWidget {
  const TradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();

    if (provider.isLoadingInitial ||
        (provider.isLoadingTrades && provider.visibleTrades.isEmpty)) {
      return const LoadingView();
    }

    if (provider.initialError != null && provider.league == null) {
      return ErrorRetry(
        message: provider.initialError!,
        onRetry: provider.loadInitial,
      );
    }

    if (provider.tradesError != null && provider.visibleTrades.isEmpty) {
      return ErrorRetry(
        message: provider.tradesError!,
        onRetry: () => provider.loadTrades(),
      );
    }

    final trades = provider.visibleTrades;
    final hasPriorityUser = provider.priorityUsername.isNotEmpty;
    final emptyMessage = provider.filterPriorityTradesOnly
        ? AppStrings.noPriorityTrades
        : AppStrings.noTrades;

    return Column(
      children: [
        if (hasPriorityUser)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text(AppStrings.tradesFilterAll),
                  selected: !provider.filterPriorityTradesOnly,
                  onSelected: (_) =>
                      provider.setTradesFilterPriorityOnly(false),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: ChoiceChip(
                    label: Text(
                      '${AppStrings.tradesFilterPriorityPrefix} ${provider.priorityUsername}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: provider.filterPriorityTradesOnly,
                    onSelected: (_) =>
                        provider.setTradesFilterPriorityOnly(true),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadTrades(isRefresh: true),
            child: trades.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Text(
                          emptyMessage,
                          style: AppTextStyles.cardSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    itemCount: trades.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) =>
                        TradeCard(trade: trades[index]),
                  ),
          ),
        ),
      ],
    );
  }
}
