import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/start_route.dart';
import 'core/audio/audio_service.dart';

/// Uygulamanın giriş noktası: bağımlılıkları kurar, sesleri yükler ve uygulamayı başlatır.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // START_ROUTE performans ölçümleri için bir debug/profile yardımcısıdır; release yok sayar.
  await configureDependencies(
    initialLocation: resolveStartRoute(isRelease: kReleaseMode),
  );
  final audio = getIt<AudioService>()..attachLifecycle();
  unawaited(audio.preload());
  runApp(PortalCardsApp(router: getIt<GoRouter>()));
}
