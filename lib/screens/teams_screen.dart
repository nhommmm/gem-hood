import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/slot_player.dart';
import '../models/team.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_retry.dart';
import '../widgets/loading_view.dart';
import '../widgets/player_tile.dart';
import '../widgets/team_avatar.dart';
import '../widgets/team_card.dart';
import '../widgets/week_schedule_card.dart';

/// Màn hình danh sách các đội trong giải (ưu tiên username đã cấu hình lên đầu); nhận [onTeamTap].
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key, required this.onTeamTap});

  final ValueChanged<Team> onTeamTap;

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

    if (provider.teams.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          children: const [
            SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                AppStrings.noTeams,
                style: AppTextStyles.cardSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    final scheduleDays = provider.priorityTeamFantasyWeekSchedule;
    final scheduleOwnerName =
        provider.priorityTeam?.teamName ?? provider.teams.first.teamName;
    final hasScheduleHeader = scheduleDays.isNotEmpty;
    final totalItems = provider.teams.length + (hasScheduleHeader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: provider.refreshAll,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        itemCount: totalItems,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (hasScheduleHeader && index == 0) {
            return WeekScheduleCard(
              teamName: scheduleOwnerName,
              weekRangeLabel: provider.fantasyWeekRangeLabel,
              weekLabel: provider.scheduleWeekOffsetLabel,
              isCurrentWeek: provider.scheduleWeekOffset == 0,
              days: scheduleDays,
              onPreviousWeek: provider.previousScheduleWeek,
              onNextWeek: provider.nextScheduleWeek,
              onResetCurrentWeek: provider.resetScheduleWeekToCurrent,
            );
          }
          final teamIndex = hasScheduleHeader ? index - 1 : index;
          final team = provider.teams[teamIndex];
          final isSelected = provider.selectedTeam?.rosterId == team.rosterId;
          final isPriority = team.isOwnedBy(provider.priorityUsername);

          return TeamCard(
            team: team,
            isSelected: isSelected,
            isPriority: isPriority,
            onTap: () => onTeamTap(team),
          );
        },
      ),
    );
  }
}

/// Khung hiển thị chi tiết đội hình chia 3 nhóm Starters / Bench / IR; nhận [team] tùy chọn.
class TeamDetailView extends StatelessWidget {
  const TeamDetailView({super.key, this.team});

  final Team? team;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    final activeTeam = team ?? provider.selectedTeam;

    if (activeTeam == null) {
      return const Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            AppStrings.selectTeamHint,
            style: AppTextStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final starters = provider.buildTeamStarters(activeTeam);
    final bench = provider.buildTeamBench(activeTeam);
    final ir = provider.buildTeamIr(activeTeam);

    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Card(
          child: ListTile(
            leading: TeamAvatar(
              avatar: activeTeam.avatar,
              teamName: activeTeam.teamName,
            ),
            title: Text(
              activeTeam.teamName,
              style: AppTextStyles.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${activeTeam.username} • ${activeTeam.recordText}',
              style: AppTextStyles.cardSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              activeTeam.fpts.toStringAsFixed(2),
              style: AppTextStyles.scoreMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RosterSectionCard(
          title: AppStrings.sectionStarters,
          players: starters,
        ),
        const SizedBox(height: AppSpacing.md),
        _RosterSectionCard(
          title: AppStrings.sectionBench,
          players: bench,
        ),
        const SizedBox(height: AppSpacing.md),
        _RosterSectionCard(
          title: AppStrings.sectionIr,
          players: ir,
        ),
      ],
    );
  }
}

class _RosterSectionCard extends StatelessWidget {
  const _RosterSectionCard({required this.title, required this.players});

  final String title;
  final List<SlotPlayer> players;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(title, style: AppTextStyles.sectionHeader),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  AppStrings.noPlayersInGroup,
                  style: AppTextStyles.bodyMuted,
                ),
              )
            else
              ...players.map((sp) => PlayerTile(slotPlayer: sp)),
          ],
        ),
      ),
    );
  }
}

/// Trang chi tiết đội hình dùng khi chuyển trang trên màn hình nhỏ; nhận [rosterId].
class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({super.key, required this.rosterId});

  final int rosterId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    final matched = provider.teams.where((t) => t.rosterId == rosterId);
    final team = matched.isNotEmpty ? matched.first : provider.selectedTeam;

    return Scaffold(
      appBar: AppBar(
        title: Text(team?.teamName ?? AppStrings.teamDetailTitle),
      ),
      body: SafeArea(child: TeamDetailView(team: team)),
    );
  }
}
