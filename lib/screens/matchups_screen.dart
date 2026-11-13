import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/matchup.dart';
import '../models/slot_player.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_retry.dart';
import '../widgets/loading_view.dart';
import '../widgets/matchup_card.dart';
import '../widgets/matchup_detail.dart';
import '../widgets/week_selector.dart';

/// Màn hình danh sách các cặp đấu theo tuần (chỉ ghép widget); nhận [onPairTap].
class MatchupsScreen extends StatelessWidget {
  const MatchupsScreen({super.key, required this.onPairTap});

  final ValueChanged<MatchupPair> onPairTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();

    if (provider.isLoadingInitial) {
      return const LoadingView();
    }

    if (provider.initialError != null && provider.league == null) {
      return ErrorRetry(
        message: provider.initialError!,
        onRetry: provider.loadInitial,
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
            selectedWeek: provider.selectedWeek,
            maxWeek: provider.currentWeek,
            onWeekSelected: provider.selectWeek,
          ),
        ),
        Expanded(
          child: _MatchupsBody(provider: provider, onPairTap: onPairTap),
        ),
      ],
    );
  }
}

class _MatchupsBody extends StatelessWidget {
  const _MatchupsBody({required this.provider, required this.onPairTap});

  final FantasyProvider provider;
  final ValueChanged<MatchupPair> onPairTap;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMatchups) {
      return const LoadingView();
    }

    if (provider.matchupsError != null) {
      return ErrorRetry(
        message: provider.matchupsError!,
        onRetry: () => provider.refreshMatchups(),
      );
    }

    if (provider.matchups.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          children: const [
            SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                AppStrings.noMatchups,
                style: AppTextStyles.cardSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refreshAll,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        itemCount: provider.matchups.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final pair = provider.matchups[index];
          final isSelected =
              provider.selectedMatchup?.matchupId == pair.matchupId;
          return MatchupCard(
            pair: pair,
            isSelected: isSelected,
            onTap: () => onPairTap(pair),
          );
        },
      ),
    );
  }
}

/// Khung hiển thị chi tiết cặp đấu đang chọn từ [FantasyProvider]; không nhận tham số bắt buộc.
class MatchupDetailView extends StatelessWidget {
  const MatchupDetailView({super.key, this.pair});

  final MatchupPair? pair;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    final activePair = pair ?? provider.selectedMatchup;

    if (activePair == null) {
      return const Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            AppStrings.selectMatchupHint,
            style: AppTextStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final homeStarters = provider.buildMatchupStarters(activePair.home);
    final homeBench = provider.buildMatchupBench(activePair.home);
    final awayStarters = activePair.away != null
        ? provider.buildMatchupStarters(activePair.away!)
        : const <SlotPlayer>[];
    final awayBench = activePair.away != null
        ? provider.buildMatchupBench(activePair.away!)
        : const <SlotPlayer>[];

    return MatchupDetail(
      pair: activePair,
      homeStarters: homeStarters,
      homeBench: homeBench,
      awayStarters: awayStarters,
      awayBench: awayBench,
    );
  }
}

/// Trang chi tiết cặp đấu dùng khi chuyển trang trên màn hình nhỏ; nhận [matchupId].
class MatchupDetailPage extends StatelessWidget {
  const MatchupDetailPage({super.key, required this.matchupId});

  final int matchupId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    final matched = provider.matchups.where((m) => m.matchupId == matchupId);
    final pair = matched.isNotEmpty ? matched.first : provider.selectedMatchup;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.matchupDetailTitle} • ${AppStrings.weekPrefix} ${provider.selectedWeek}',
        ),
      ),
      body: SafeArea(child: MatchupDetailView(pair: pair)),
    );
  }
}
