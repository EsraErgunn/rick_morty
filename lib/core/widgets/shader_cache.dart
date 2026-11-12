import 'dart:async';
import 'dart:ui' as ui;

import '../../app/theme/motion.dart';
import '../logging/app_logger.dart';

/// Loads a fragment program from an asset path.
typedef ProgramLoader = Future<ui.FragmentProgram> Function(String asset);

/// Draws a program once off screen, so its GPU pipeline is compiled before
/// the first visible frame needs it.
typedef ProgramWarmer = Future<void> Function(ui.FragmentProgram program);

Future<ui.FragmentProgram> _fromAsset(String asset) =>
    ui.FragmentProgram.fromAsset(asset);

Future<void> _drawOnce(ui.FragmentProgram program) async {
  const side = 8;
  final shader = program.fragmentShader();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    ui.Paint()..shader = shader,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(side, side);
    image.dispose();
  } finally {
    picture.dispose();
    shader.dispose();
  }
}

/// `--dart-define=DISABLE_SHADERS=true` (debug/profile only): every shader
/// widget draws its static fallback. A diagnosis switch for devices (or
/// emulators) whose GPU chokes on the shaders.
const bool disableShadersDefine = bool.fromEnvironment('DISABLE_SHADERS');

/// Release builds always use the shaders.
bool shadersDisabled({
  required bool isRelease,
  bool requested = disableShadersDefine,
}) => !isRelease && requested;

/// Loads the app's fragment programs once per run and keeps them
/// (animation rules: load once, never in `build`). Each program is warmed
/// up off screen; a program that fails, or does not load and warm up within
/// [AppMotion.shaderLoadLimit], stays null and its widget draws a
/// non-shader fallback, so a slow GPU can never freeze the app.
class ShaderCache {
  ShaderCache({
    this._loader = _fromAsset,
    this._warmer = _drawOnce,
    this.enabled = true,
    this._limit = AppMotion.shaderLoadLimit,
  });

  static const String holoAsset = 'shaders/holo.frag';
  static const String portalAsset = 'shaders/portal.frag';
  static const List<String> assets = [holoAsset, portalAsset];

  final ProgramLoader _loader;
  final ProgramWarmer _warmer;
  final Duration _limit;

  /// False = never load; every widget uses its fallback (DISABLE_SHADERS).
  final bool enabled;
  final Map<String, ui.FragmentProgram> _programs = {};
  final Set<String> _failed = {};
  Future<void>? _loading;

  /// Card holo foil (`holo.frag`), null until loaded or if it failed.
  ui.FragmentProgram? get holo => _programs[holoAsset];

  /// Portal vortex (`portal.frag`), null until loaded or if it failed.
  ui.FragmentProgram? get portal => _programs[portalAsset];

  bool get failed => _failed.isNotEmpty;

  bool failedFor(String asset) => _failed.contains(asset);

  /// Safe to call many times; loads each program only once.
  Future<void> load() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    if (!enabled) {
      AppLogger.info('shaders disabled (DISABLE_SHADERS), using fallbacks');
      return;
    }
    for (final asset in assets) {
      final watch = Stopwatch()..start();
      try {
        final program = await _loader(asset).timeout(_limit);
        await _warmer(program).timeout(_limit - watch.elapsed);
        _programs[asset] = program;
        AppLogger.debug(
          'shader $asset ready in ${watch.elapsedMilliseconds} ms',
        );
      } on Object catch (e) {
        _failed.add(asset);
        AppLogger.warning('shader $asset failed to load, using fallback', e);
      }
    }
  }
}
