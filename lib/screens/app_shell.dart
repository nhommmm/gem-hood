import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../l10n/strings.dart';
import '../models/matchup.dart';
import '../models/team.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_spacing.dart';
import 'insights_screen.dart';
import 'matchups_screen.dart';
import 'setup_screen.dart';
import 'standings_screen.dart';
import 'teams_screen.dart';
import 'trades_screen.dart';

/// Khung điều hướng chính của ứng dụng, chứa logic responsive (NavigationRail vs BottomNavigationBar).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<FantasyProvider>();
      provider.loadInitial();
      if (_selectedIndex == 0) {
        provider.startMatchupsAutoRefresh();
      }
    });
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }
    final provider = context.read<FantasyProvider>();
    if (index == 0) {
      provider.startMatchupsAutoRefresh();
    } else {
      provider.stopMatchupsAutoRefresh();
    }
    if (index == 3) {
      provider.ensureTradesLoaded();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleMatchupTap(MatchupPair pair, bool isWide) {
    final provider = context.read<FantasyProvider>();
    provider.selectMatchup(pair);
    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MatchupDetailPage(matchupId: pair.matchupId),
        ),
      );
    }
  }

  void _handleTeamTap(Team team, bool isWide) {
    final provider = context.read<FantasyProvider>();
    provider.selectTeam(team);
    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeamDetailPage(rosterId: team.rosterId),
        ),
      );
    }
  }

  void _handleStandingsTeamTap(Team team, bool isWide) {
    final provider = context.read<FantasyProvider>();
    provider.selectTeam(team);
    if (isWide) {
      _onDestinationSelected(1);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeamDetailPage(rosterId: team.rosterId),
        ),
      );
    }
  }

  void _openChangeLeague() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SetupScreen(canCancel: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    if (provider.needsSetup) {
      return const SetupScreen(canCancel: false);
    }

    final title = provider.league?.name.isNotEmpty == true
        ? '${AppStrings.appShortTitle} • ${provider.league!.name}'
        : AppStrings.appTitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > AppConstants.desktopBreakpoint;

        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              TextButton.icon(
                onPressed: _openChangeLeague,
                icon: const Icon(Icons.swap_horiz, size: AppSpacing.iconSm),
                label: const Text(AppStrings.changeLeagueLabel),
              ),
              IconButton(
                onPressed: provider.refreshAll,
                tooltip: AppStrings.refreshTooltip,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onDestinationSelected,
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.sports_basketball_outlined),
                            selectedIcon: Icon(Icons.sports_basketball),
                            label: Text(AppStrings.tabMatchups),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.groups_outlined),
                            selectedIcon: Icon(Icons.groups),
                            label: Text(AppStrings.tabTeams),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.leaderboard_outlined),
                            selectedIcon: Icon(Icons.leaderboard),
                            label: Text(AppStrings.tabStandings),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.swap_horiz_outlined),
                            selectedIcon: Icon(Icons.swap_horiz),
                            label: Text(AppStrings.tabTrades),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.insights_outlined),
                            selectedIcon: Icon(Icons.insights),
                            label: Text(AppStrings.tabInsights),
                          ),
                        ],
                      ),
                      const VerticalDivider(width: AppSpacing.borderThin),
                      Expanded(child: _buildBody(isWide: true)),
                    ],
                  )
                : _buildBody(isWide: false),
          ),
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onDestinationSelected,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.sports_basketball),
                      label: AppStrings.tabMatchups,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.groups),
                      label: AppStrings.tabTeams,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.leaderboard),
                      label: AppStrings.tabStandings,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.swap_horiz),
                      label: AppStrings.tabTrades,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.insights),
                      label: AppStrings.tabInsights,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBody({required bool isWide}) {
    switch (_selectedIndex) {
      case 0:
        final listPane = MatchupsScreen(
          onPairTap: (pair) => _handleMatchupTap(pair, isWide),
        );
        if (!isWide) {
          return listPane;
        }
        return Row(
          children: [
            SizedBox(width: AppSpacing.masterPaneWidth, child: listPane),
            const VerticalDivider(width: AppSpacing.borderThin),
            const Expanded(child: MatchupDetailView()),
          ],
        );
      case 1:
        final listPane = TeamsScreen(
          onTeamTap: (team) => _handleTeamTap(team, isWide),
        );
        if (!isWide) {
          return listPane;
        }
        return Row(
          children: [
            SizedBox(width: AppSpacing.masterPaneWidth, child: listPane),
            const VerticalDivider(width: AppSpacing.borderThin),
            const Expanded(child: TeamDetailView()),
          ],
        );
      case 2:
        return StandingsScreen(
          onTeamTap: (team) => _handleStandingsTeamTap(team, isWide),
        );
      case 3:
        return const TradesScreen();
      case 4:
      default:
        return const InsightsScreen();
    }
  }
}
