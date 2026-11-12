import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/portal_loader.dart';
import '../../../../core/widgets/screen_background.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';
import '../widgets/sync_status_view.dart';

/// First screen: syncs the API (or skips if synced), then calls [onDone]
/// (the router opens the menu). Expects a [SyncBloc] above it.
class SplashPage extends StatefulWidget {
  const SplashPage({required this.onDone, this.shaders, super.key});

  /// Called once sync succeeded and the loader has settled.
  final VoidCallback onDone;

  /// Portal shader for the loader (null = spiral painter).
  final ShaderCache? shaders;

  /// Portal brightness while a failure is shown (SPEC §4.1).
  static const double dimIntensity = 0.05;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loaderActive = true;
  bool _done = false;
  Timer? _fallback;

  /// Navigates once, whichever comes first: the loader settled, or the
  /// fallback timer (which needs no frame, so a stalled frame pipeline can
  /// never keep the app on the splash).
  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _fallback?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        // Navigation waits for the loader to settle (see onSettled), but
        // never longer than the loader could take to close.
        final success = state.status == SyncStatus.success;
        if (success) {
          _fallback?.cancel();
          _fallback = Timer(AppMotion.splashExitLimit, _finish);
        }
        setState(() => _loaderActive = !success);
      },
      child: Scaffold(
        // The art's green glow is at its center; with BoxFit.cover that is
        // the screen center, where the loader sits.
        body: ScreenBackground(
          asset: Backgrounds.splash,
          child: LayoutBuilder(
            builder: (context, box) {
              final edge = box.maxHeight / 2 + AppSizes.splashPortal / 2;
              return BlocBuilder<SyncBloc, SyncState>(
                builder: (context, state) => Stack(
                  children: [
                    Center(
                      child: PortalLoader(
                        active: _loaderActive,
                        intensity: state.status == SyncStatus.failure
                            ? SplashPage.dimIntensity
                            : 1,
                        onSettled: _finish,
                        shaders: widget.shaders,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.gutter,
                      right: AppSpacing.gutter,
                      bottom: edge + AppSpacing.lg,
                      child: Text(
                        AppLocalizations.of(context).appTitle,
                        style: AppTypography.display,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.gutter,
                      right: AppSpacing.gutter,
                      top: edge + AppSpacing.lg,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.contentMaxWidth,
                          ),
                          child: AnimatedSwitcher(
                            duration: AppMotion.normal,
                            transitionBuilder: _slideUp,
                            child: state.status == SyncStatus.failure
                                ? SyncErrorView(
                                    key: const ValueKey('sync-error'),
                                    connectionProblem:
                                        state.isConnectionProblem,
                                    onRetry: () => context.read<SyncBloc>().add(
                                      const SyncRetryRequested(),
                                    ),
                                  )
                                : SyncProgressView(
                                    key: const ValueKey('sync-progress'),
                                    progress: state.progress,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _slideUp(Widget child, Animation<double> animation) {
    final offset = Tween(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: AppMotion.move));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
