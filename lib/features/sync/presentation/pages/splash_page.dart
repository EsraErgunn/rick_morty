import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/portal_loader.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';
import '../widgets/sync_status_view.dart';

/// First screen: syncs the API (or skips if synced), then calls [onDone]
/// (the router opens the menu). Expects a [SyncBloc] above it.
class SplashPage extends StatefulWidget {
  const SplashPage({required this.onDone, super.key});

  /// Called once sync succeeded and the loader has settled.
  final VoidCallback onDone;

  /// Portal brightness while a failure is shown (SPEC §4.1).
  static const double dimIntensity = 0.05;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loaderActive = true;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        // Navigation waits for the loader to settle (see onSettled).
        setState(() => _loaderActive = state.status != SyncStatus.success);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: BlocBuilder<SyncBloc, SyncState>(
                  builder: (context, state) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).appTitle,
                        style: AppTypography.display,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PortalLoader(
                        active: _loaderActive,
                        intensity: state.status == SyncStatus.failure
                            ? SplashPage.dimIntensity
                            : 1,
                        onSettled: widget.onDone,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedSwitcher(
                        duration: AppMotion.normal,
                        transitionBuilder: _slideUp,
                        child: state.status == SyncStatus.failure
                            ? SyncErrorView(
                                key: const ValueKey('sync-error'),
                                connectionProblem: state.isConnectionProblem,
                                onRetry: () => context.read<SyncBloc>().add(
                                  const SyncRetryRequested(),
                                ),
                              )
                            : SyncProgressView(
                                key: const ValueKey('sync-progress'),
                                progress: state.progress,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
