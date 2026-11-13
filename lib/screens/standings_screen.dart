import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/team.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_retry.dart';
import '../widgets/loading_view.dart';
import '../widgets/standings_row.dart';

/// Màn hình bảng xếp hạng sắp xếp Wins giảm dần rồi FPTS giảm dần; nhận callback [onTeamTap] tùy chọn.
class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key, this.onTeamTap});

  final ValueChanged<Team>? onTeamTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();

    if (provider.isLoadingInitial) {
      return const LoadingView();
    }

    if (provider.initialError != null && provider.teams.isEmpty) {
      return ErrorRetry(
        message: provider.initialError!,
        onRetry: provider.loadInitial,
      );
    }

    final standings = provider.standings;

    if (standings.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          children: const [
            SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                AppStrings.noStandings,
                style: AppTextStyles.cardSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSpacing.rankColumnWidth,
                child: Text(
                  AppStrings.standingsRankHeader,
                  style: AppTextStyles.caption,
                ),
              ),
              Expanded(
                child: Text(
                  AppStrings.standingsTeamHeader,
                  style: AppTextStyles.caption,
                ),
              ),
              SizedBox(
                width: AppSpacing.recordColumnWidth,
                child: Text(
                  AppStrings.standingsRecordHeader,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: AppSpacing.fptsColumnWidth,
                child: Text(
                  AppStrings.standingsFptsHeader,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshAll,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              itemCount: standings.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final team = standings[index];
                final isPriority = team.isOwnedBy(provider.priorityUsername);
                return StandingsRow(
                  rank: index + 1,
                  team: team,
                  isPriority: isPriority,
                  onTap: onTeamTap != null ? () => onTeamTap!(team) : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
