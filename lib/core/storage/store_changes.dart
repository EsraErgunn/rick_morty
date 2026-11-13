import 'dart:async';

/// One stream that fires whenever any of [sources] fires. Each listener gets
/// its own subscriptions, cancelled with it.
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
