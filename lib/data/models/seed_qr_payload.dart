class SeedQrPayload {
  const SeedQrPayload({required this.seedUid});

  static const String _scheme = 'greenfestival';
  static const String _host = 'seed';
  static const String _version = '1';

  final String seedUid;

  String encode() {
    return Uri(
      scheme: _scheme,
      host: _host,
      pathSegments: [seedUid],
      queryParameters: const <String, String>{'v': _version},
    ).toString();
  }

  static SeedQrPayload? tryParse(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != _scheme || uri.host != _host) {
      return null;
    }

    if (uri.queryParameters['v'] != _version) {
      return null;
    }

    final pathSegments = uri.pathSegments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (pathSegments.isEmpty) {
      return null;
    }

    return SeedQrPayload(seedUid: pathSegments.first);
  }
}
