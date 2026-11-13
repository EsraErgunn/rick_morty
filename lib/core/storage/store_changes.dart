import 'dart:async';

/// [sources] kaynaklarından herhangi biri tetiklendiğinde tetiklenen tek bir akış. Her dinleyici
/// kendi aboneliklerini alır, kendisiyle birlikte iptal edilir.
Stream<void> mergeChanges(List<Stream<void>> sources) {
  late StreamController<void> controller;
  final subs = <StreamSubscription<void>>[];
  controller = StreamController<void>(
    onListen: () {
      for (final s in sources) {
        subs.add(s.listen(controller.add, onError: controller.addError));
      }
    },
    onCancel: () => Future.wait([for (final s in subs) s.cancel()]),
  );
  return controller.stream;
}
