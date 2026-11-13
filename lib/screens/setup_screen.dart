import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/fantasy_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Màn hình thiết lập / đổi Sleeper League ID và username ưu tiên.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.canCancel = false});

  final bool canCancel;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _leagueIdController;
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FantasyProvider>();
    _leagueIdController = TextEditingController(text: provider.leagueId);
    _usernameController = TextEditingController(
      text: provider.priorityUsername,
    );
    provider.clearSetupError();
  }

  @override
  void dispose() {
    _leagueIdController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final provider = context.read<FantasyProvider>();
    final ok = await provider.submitLeagueSetup(
      leagueId: _leagueIdController.text,
      priorityUsername: _usernameController.text,
    );
    if (!mounted) {
      return;
    }
    if (ok && widget.canCancel) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FantasyProvider>();
    final isValidating = provider.isValidatingSetup;
    final setupError = provider.setupError;

    return Scaffold(
      appBar: widget.canCancel
          ? AppBar(title: const Text(AppStrings.changeLeagueLabel))
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.sports_basketball,
                            size: AppSpacing.iconLg,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          AppStrings.appTitle,
                          style: AppTextStyles.scoreLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          AppStrings.setupTitle,
                          style: AppTextStyles.sectionHeader,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          AppStrings.setupSubtitle,
                          style: AppTextStyles.cardSubtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _leagueIdController,
                          enabled: !isValidating,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => provider.clearSetupError(),
                          decoration: const InputDecoration(
                            labelText: AppStrings.setupLeagueIdLabel,
                            hintText: AppStrings.setupLeagueIdHint,
                            helperText: AppStrings.setupLeagueIdHelp,
                            helperMaxLines: 2,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.setupLeagueIdRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _usernameController,
                          enabled: !isValidating,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              isValidating ? null : _submit(),
                          onChanged: (_) => provider.clearSetupError(),
                          decoration: const InputDecoration(
                            labelText: AppStrings.setupUsernameLabel,
                            hintText: AppStrings.setupUsernameHint,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (setupError != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: AppSpacing.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.loss.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              border: Border.all(color: AppColors.loss),
                            ),
                            child: Text(
                              setupError,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.loss,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton(
                          onPressed: isValidating ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: isValidating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: AppSpacing.iconSm,
                                      height: AppSpacing.iconSm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    Text(AppStrings.setupValidatingButton),
                                  ],
                                )
                              : const Text(AppStrings.setupSubmitButton),
                        ),
                        if (widget.canCancel) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: isValidating
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text(AppStrings.setupCancelButton),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
