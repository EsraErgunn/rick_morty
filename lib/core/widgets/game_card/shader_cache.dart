import 'dart:ui' as ui;

import '../../logging/app_logger.dart';

/// Loads a fragment program from an asset path.
typedef ProgramLoader = Future<ui.FragmentProgram> Function(String asset);

Future<ui.FragmentProgram> _fromAsset(String asset) =>
    ui.FragmentProgram.fromAsset(asset);

/// Loads `holo.frag` once per app run and keeps it (animation rules: load
/// once, never in `build`). If loading fails, [holo] stays null and the
/// holo layer draws its non-shader fallback.
class ShaderCache {
  ShaderCache({this._loader = _fromAsset});

  static const String holoAsset = 'shaders/holo.frag';

  final ProgramLoader _loader;
  Future<void>? _loading;

  ui.FragmentProgram? _holo;
  bool _failed = false;

  /// Null until loaded, or if loading failed.
  ui.FragmentProgram? get holo => _holo;

  bool get failed => _failed;

  /// Safe to call many times; loads only once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _holo = await _loader(holoAsset);
    } on Object catch (e) {
      _failed = true;
      AppLogger.warning('holo shader failed to load, using fallback', e);
    }
  }
}
