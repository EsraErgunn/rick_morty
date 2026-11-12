import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/audio/audio_assets.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../core/storage/player_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/demo_panel.dart';

/// Settings (SPEC §2.9, §4.9). Expects a [SettingsBloc] above it.
/// [extra] is a slot for more rows (image download, plan T36).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.audio,
    required this.haptics,
    required this.feedback,
    required this.version,
    this.extra,
    super.key,
  });

  final AudioService audio;
  final HapticsService haptics;
  final UiFeedback feedback;
  final String version;
  final Widget? extra;

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SettingsBloc>();
    feedback.tap();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            key: const ValueKey('reset-confirm'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsResetConfirm),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(const ProgressResetConfirmed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SettingsBloc>();
    return MultiBlocListener(
      listeners: [
        // Apply first: the toggle sound/haptic then follow the new setting.
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (a, b) => a.settings != b.settings,
          listener: (context, state) {
            unawaited(audio.applySettings(state.settings));
            haptics.applySettings(state.settings);
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (a, b) => a.demoUnlockedTick != b.demoUnlockedTick,
          listener: (context, state) {
            unawaited(audio.play(Sfx.portalOpen));
            unawaited(haptics.play(HapticMoment.portalOpen));
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (a, b) => a.resetTick != b.resetTick,
          listener: (context, state) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.settingsResetDone))),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final s = state.settings;
          void toggle(bool v, PlayerSettingsChange change) {
            final next = change(v);
            // Apply now, then give feedback: the toggle's own sound/haptic
            // follows the NEW setting (SPEC §4.9). The listener re-applies
            // the same values after the bloc saved them.
            unawaited(audio.applySettings(next));
            haptics.applySettings(next);
            feedback.toggle();
            bloc.add(SettingsChanged(next));
          }

          return Scaffold(
            appBar: AppBar(title: Text(l10n.settingsTitle)),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                SwitchListTile(
                  key: const ValueKey('toggle-sound'),
                  title: Text(l10n.settingsSound),
                  value: s.soundEnabled,
                  onChanged: (v) =>
                      toggle(v, (v) => s.copyWith(soundEnabled: v)),
                ),
                SwitchListTile(
                  key: const ValueKey('toggle-music'),
                  title: Text(l10n.settingsMusic),
                  value: s.musicEnabled,
                  onChanged: (v) =>
                      toggle(v, (v) => s.copyWith(musicEnabled: v)),
                ),
                SwitchListTile(
                  key: const ValueKey('toggle-haptics'),
                  title: Text(l10n.settingsHaptics),
                  value: s.hapticsEnabled,
                  onChanged: (v) =>
                      toggle(v, (v) => s.copyWith(hapticsEnabled: v)),
                ),
                _VolumeRow(
                  label: l10n.settingsSfxVolume,
                  value: s.sfxVolume,
                  onChanged: (v) =>
                      bloc.add(SettingsChanged(s.copyWith(sfxVolume: v))),
                  // Play the tap at the NEW volume (SPEC §4.9).
                  onChangeEnd: (v) {
                    unawaited(audio.applySettings(s.copyWith(sfxVolume: v)));
                    unawaited(audio.play(Sfx.buttonTap));
                  },
                ),
                _VolumeRow(
                  label: l10n.settingsMusicVolume,
                  value: s.musicVolume,
                  onChanged: (v) =>
                      bloc.add(SettingsChanged(s.copyWith(musicVolume: v))),
                ),
                ?extra,
                const Divider(),
                ListTile(
                  title: Text(
                    l10n.settingsReset,
                    style: AppTypography.label.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  onTap: () => _confirmReset(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Text(
                    l10n.settingsDisclaimer,
                    style: AppTypography.caption,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: Text(
                    l10n.settingsCredits,
                    style: AppTypography.caption,
                  ),
                ),
                GestureDetector(
                  key: const ValueKey('version-label'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => bloc.add(VersionTapped(DateTime.now())),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Text(
                      l10n.settingsVersion(version),
                      style: AppTypography.caption,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.normal,
                  curve: AppMotion.move,
                  child: state.demoUnlocked
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.gutter,
                          ),
                          child: DemoPanel(state: state, feedback: feedback),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

typedef PlayerSettingsChange = PlayerSettings Function(bool value);

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTypography.body)),
        Expanded(
          flex: 3,
          child: Slider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    ),
  );
}
