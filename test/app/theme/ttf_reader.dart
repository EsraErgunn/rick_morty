import 'dart:typed_data';

/// Minimal TrueType reader for tests: the set of code points a font maps
/// (cmap formats 4 and 12) and its OpenType GSUB feature tags.
class TtfReader {
  TtfReader(Uint8List bytes) : _data = ByteData.sublistView(bytes) {
    final count = _data.getUint16(4);
    for (var i = 0; i < count; i++) {
      final rec = 12 + 16 * i;
      final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
      _tables[tag] = _data.getUint32(rec + 8);
    }
  }

  final ByteData _data;
  final Map<String, int> _tables = {};

  Set<int> codePoints() {
    final cmap = _tables['cmap'];
    if (cmap == null) return const {};
    final result = <int>{};
    final subtables = _data.getUint16(cmap + 2);
    for (var i = 0; i < subtables; i++) {
      final start = cmap + _data.getUint32(cmap + 4 + 8 * i + 4);
      switch (_data.getUint16(start)) {
        case 4:
          final segX2 = _data.getUint16(start + 6);
          for (var s = 0; s < segX2 ~/ 2; s++) {
            final end = _data.getUint16(start + 14 + 2 * s);
            final first = _data.getUint16(start + 16 + segX2 + 2 * s);
            for (var cp = first; cp <= end && cp != 0xFFFF; cp++) {
              result.add(cp);
            }
          }
        case 12:
          final groups = _data.getUint32(start + 12);
          for (var g = 0; g < groups; g++) {
            final rec = start + 16 + 12 * g;
            final first = _data.getUint32(rec);
            final end = _data.getUint32(rec + 4);
            for (var cp = first; cp <= end; cp++) {
              result.add(cp);
            }
          }
      }
    }
    return result;
  }

  Set<String> gsubFeatures() {
    final gsub = _tables['GSUB'];
    if (gsub == null) return const {};
    final list = gsub + _data.getUint16(gsub + 6);
    final count = _data.getUint16(list);
    return {
      for (var i = 0; i < count; i++)
        String.fromCharCodes([
          for (var b = 0; b < 4; b++) _data.getUint8(list + 2 + 6 * i + b),
        ]),
    };
  }
}
