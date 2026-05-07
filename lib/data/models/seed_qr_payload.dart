class SeedQrPayload {
  const SeedQrPayload({required this.seedUid});

  final String seedUid;

  String encode() {
    return seedUid.trim();
  }

  static SeedQrPayload? tryParse(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!trimmed.contains('://')) {
      return SeedQrPayload(seedUid: trimmed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'greenfestival' ||
        uri.host.toLowerCase() != 'seed' ||
        uri.pathSegments.length != 1) {
      return null;
    }

    final seedUid = uri.pathSegments.single.trim();
    if (seedUid.isEmpty) {
      return null;
    }

    return SeedQrPayload(seedUid: seedUid);
  }
}
