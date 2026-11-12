import 'dart:ui' as ui;

import '../logging/app_logger.dart';

/// Loads a fragment program from an asset path.
typedef ProgramLoader = Future<ui.FragmentProgram> Function(String asset);

Future<ui.FragmentProgram> _fromAsset(String asset) =>
    ui.FragmentProgram.fromAsset(asset);

/// Loads the app's fragment programs once per run and keeps them
/// (animation rules: load once, never in `build`). A program that fails to
/// load stays null and its widget draws a non-shader fallback.
class ShaderCache {
  ShaderCache({this._loader = _fromAsset});

  static const String holoAsset = 'shaders/holo.frag';
  static const String portalAsset = 'shaders/portal.frag';
  static const List<String> assets = [holoAsset, portalAsset];

  final ProgramLoader _loader;
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
    for (final asset in assets) {
      try {
        _programs[asset] = await _loader(asset);
      } on Object catch (e) {
        _failed.add(asset);
        AppLogger.warning('shader $asset failed to load, using fallback', e);
      }
    }
  }
}
