import '../../../../core/network/endpoints.dart';

/// Strict field access for API JSON. Throws [FormatException] with the field
/// name when a field is missing or has the wrong type; mappers turn that
/// into a `ParseFailure`.
extension JsonReader on Map<String, dynamic> {
  T field<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw FormatException(
      'field "$key": expected $T, got ${value.runtimeType}',
    );
  }

  Map<String, dynamic> object(String key) => field<Map<String, dynamic>>(key);

  /// A list of resource URLs mapped to their ids.
  List<int> idsFromUrls(String key) => [
    for (final url in field<List<dynamic>>(key))
      if (url is String)
        Endpoints.idFromUrl(url) ??
            (throw FormatException('field "$key": no id in "$url"'))
      else
        throw FormatException('field "$key": expected URL strings'),
  ];

  /// The id at the end of the `url` field, or null if the URL is empty
  /// (the API uses "" for an unknown origin or location).
  int? optionalIdFromUrl(String key) {
    final url = field<String>(key);
    return url.isEmpty ? null : Endpoints.idFromUrl(url);
  }
}
