import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/fantasy_provider.dart';
import '../providers/insights_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bench_regret_card.dart';
import '../widgets/error_retry.dart';
import '../widgets/insight_starter_card.dart';
import '../widgets/lineup_efficiency_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/week_selector.dart';

/// Màn hình Insights phân tích hiệu suất starters, bench tiếc nuối và hiệu quả lineup theo tuần (chỉ ghép widget).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fantasy = context.watch<FantasyProvider>();
    final insights = context.watch<InsightsProvider>();

    if (fantasy.isLoadingInitial) {
      return const LoadingView();
    }

    if (fantasy.initialError != null && fantasy.league == null) {
      return ErrorRetry(
        message: fantasy.initialError!,
        onRetry: fantasy.loadInitial,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: WeekSelector(
            selectedWeek: fantasy.selectedWeek,
            maxWeek: fantasy.currentWeek,
            onWeekSelected: fantasy.selectWeek,
          ),
        ),
        Expanded(
          child: _InsightsBody(fantasy: fantasy, insights: insights),
        ),
      ],
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.fantasy, required this.insights});

  final FantasyProvider fantasy;
  final InsightsProvider insights;

  @override
  Widget build(BuildContext context) {
    if (fantasy.isLoadingMatchups) {
      return const LoadingView();
    }

    if (fantasy.matchupsError != null) {
      return ErrorRetry(
        message: fantasy.matchupsError!,
        onRetry: () => fantasy.refreshMatchups(),
      );
    }

    if (!insights.hasData) {
      return RefreshIndicator(
        onRefresh: fantasy.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          children: const [
            SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                AppStrings.insightsNoData,
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fantasy.refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        children: [
          LineupEfficiencyCard(efficiencies: insights.lineupEfficiencies),
          const SizedBox(height: AppSpacing.md),
          InsightStarterCard(
            title: AppStrings.insightsTopStartersTitle,
            items: insights.topStarters,
            scoreColor: AppColors.win,
          ),
          const SizedBox(height: AppSpacing.md),
          InsightStarterCard(
            title: AppStrings.insightsBottomStartersTitle,
            items: insights.bottomStarters,
            scoreColor: AppColors.loss,
            zeroPointStarters: insights.zeroPointStarters,
          ),
          const SizedBox(height: AppSpacing.md),
          BenchRegretCard(regrets: insights.benchRegrets),
        ],
      ),
    );
  }
}
