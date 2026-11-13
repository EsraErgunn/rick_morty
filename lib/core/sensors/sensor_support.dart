import 'package:flutter/foundation.dart';

/// Hareket sensörleri yalnızca telefonlarda var. Masaüstünde (macOS, test
/// için kullanılır) `sensors_plus`'ın uygulaması yoktur ve
/// `MissingPluginException` fırlatır; bu yüzden sensör sınıfları orada boş bir akış
/// kullanır; dokunarak sürükleme eğimi ve portal butonu yine çalışır.
bool get deviceHasMotionSensors =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
