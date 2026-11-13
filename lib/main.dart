import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'providers/fantasy_provider.dart';
import 'providers/insights_provider.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GemHoodApp());
}

/// Widget gốc khởi tạo MultiProvider (FantasyProvider + InsightsProvider) và ThemeData cho toàn ứng dụng.
class GemHoodApp extends StatelessWidget {
  const GemHoodApp({super.key, this.provider});

  final FantasyProvider? provider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FantasyProvider>(
          create: (_) => provider ?? FantasyProvider(),
        ),
        ProxyProvider<FantasyProvider, InsightsProvider>(
          create: (_) => const InsightsProvider.empty(),
          update: (_, fantasy, previous) =>
              InsightsProvider.fromFantasy(fantasy, previous),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}
