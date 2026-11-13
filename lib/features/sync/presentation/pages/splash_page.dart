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

/// İlk ekran: API'yi senkronlar (senkronluysa atlar), sonra [onDone] çağırır
/// (router menüyü açar). Üstünde bir [SyncBloc] bekler.
class SplashPage extends StatefulWidget {
  const SplashPage({required this.onDone, this.shaders, super.key});

  /// Senkron başarılı olup yükleyici yerleşince bir kez çağrılır.
  final VoidCallback onDone;

  /// Yükleyici için portal shader'ı (null = sarmal çizici).
  final ShaderCache? shaders;

  /// Bir hata gösterilirken portal parlaklığı (SPEC §4.1).
  static const double dimIntensity = 0.05;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loaderActive = true;
  bool _done = false;
  Timer? _fallback;

  /// Hangisi önce gelirse bir kez geçiş yapar: yükleyici yerleşti ya da
  /// yedek zamanlayıcı (kare gerektirmez, böylece takılan bir kare hattı
  /// uygulamayı asla splash'te tutamaz).
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
        // Geçiş yükleyicinin yerleşmesini bekler (bkz. onSettled), ama
        // yükleyicinin kapanabileceği süreden asla uzun değil.
        final success = state.status == SyncStatus.success;
        if (success) {
          _fallback?.cancel();
          _fallback = Timer(AppMotion.splashExitLimit, _finish);
        }
        setState(() => _loaderActive = !success);
      },
      child: Scaffold(
        // Görselin yeşil parıltısı merkezindedir; BoxFit.cover ile bu
        // ekran merkezi, yani yükleyicinin durduğu yerdir.
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
