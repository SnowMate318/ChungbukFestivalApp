class SeedQrPayload {
  const SeedQrPayload({required this.seedUid});

  static final RegExp _seedUidPattern = RegExp(r'^[A-Za-z0-9]{20}$');

  final String seedUid;

  String encode() {
    return seedUid.trim();
  }

  static SeedQrPayload? tryParse(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty || !_seedUidPattern.hasMatch(trimmed)) {
      return null;
    }

    return SeedQrPayload(seedUid: trimmed);
  }
}
