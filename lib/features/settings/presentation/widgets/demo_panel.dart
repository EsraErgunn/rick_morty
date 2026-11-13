import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

/// Gizli demo paneli (SPEC D2, §2.9 AC2).
class DemoPanel extends StatelessWidget {
  const DemoPanel({required this.state, required this.feedback, super.key});

  final SettingsState state;
  final UiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SettingsBloc>();
    void send(SettingsEvent e) {
      feedback.tap();
      bloc.add(e);
    }

    return Card(
      key: const ValueKey('demo-panel'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsDemoTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => send(const DemoCoinsRequested()),
              child: Text(l10n.settingsDemoCoins),
            ),
            const SizedBox(height: AppSpacing.xs),
            FilledButton(
              onPressed: state.legendaryArmed
                  ? null
                  : () => send(const DemoLegendaryRequested()),
              child: Text(
                state.legendaryArmed
                    ? l10n.settingsDemoLegendaryArmed
                    : l10n.settingsDemoLegendary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: () => send(const DemoClosed()),
              child: Text(l10n.settingsDemoOff),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.coinsLabel(state.coins),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.paperMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
