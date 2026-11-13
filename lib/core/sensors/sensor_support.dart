import 'package:flutter/foundation.dart';

/// Motion sensors exist only on phones. On desktop (macOS, used for
/// testing) `sensors_plus` has no implementation and throws
/// `MissingPluginException`, so the sensor classes use an empty stream
/// there; the touch drag tilt and the portal button still work.
bool get deviceHasMotionSensors =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
