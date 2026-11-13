import 'dart:async';
import 'dart:ui' as ui;

import '../../app/theme/motion.dart';
import '../logging/app_logger.dart';

/// Bir görsel dosya yolundan fragment programı yükler.
typedef ProgramLoader = Future<ui.FragmentProgram> Function(String asset);

/// Bir programı ekran dışında bir kez çizer, böylece GPU hattı ilk görünür
/// kare ona ihtiyaç duymadan önce derlenir.
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

/// `--dart-define=DISABLE_SHADERS=true` (yalnızca debug/profile): her shader
/// widget'ı statik yedeğini çizer. GPU'su shader'larda tıkanan cihazlar (ya da
/// emülatörler) için bir teşhis anahtarı.
const bool disableShadersDefine = bool.fromEnvironment('DISABLE_SHADERS');

/// Release derlemeler her zaman shader'ları kullanır.
bool shadersDisabled({
  required bool isRelease,
  bool requested = disableShadersDefine,
}) => !isRelease && requested;

/// Uygulamanın fragment programlarını her çalıştırmada bir kez yükler ve tutar
/// (animasyon kuralları: bir kez yükle, asla `build` içinde değil). Her program ekran
/// dışında ısıtılır; başarısız olan ya da [AppMotion.shaderLoadLimit] içinde yüklenip
/// ısınmayan bir program null kalır ve widget'ı shader'sız bir yedek
/// çizer, böylece yavaş bir GPU uygulamayı asla donduramaz.
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

  /// False = asla yükleme; her widget yedeğini kullanır (DISABLE_SHADERS).
  final bool enabled;
  final Map<String, ui.FragmentProgram> _programs = {};
  final Set<String> _failed = {};
  Future<void>? _loading;

  /// Kart holo folyosu (`holo.frag`), yüklenene kadar ya da başarısız olduysa null.
  ui.FragmentProgram? get holo => _programs[holoAsset];

  /// Portal girdabı (`portal.frag`), yüklenene kadar ya da başarısız olduysa null.
  ui.FragmentProgram? get portal => _programs[portalAsset];

  bool get failed => _failed.isNotEmpty;

  bool failedFor(String asset) => _failed.contains(asset);

  /// Defalarca çağrılabilir; her programı yalnızca bir kez yükler.
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
