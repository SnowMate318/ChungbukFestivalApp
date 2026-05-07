import 'package:flutter_test/flutter_test.dart';
import 'package:greenfestival/data/models/seed_qr_payload.dart';

void main() {
  group('SeedQrPayload.tryParse', () {
    test('parses a bare seed uid', () {
      final payload = SeedQrPayload.tryParse('booth-uid_123');

      expect(payload?.seedUid, 'booth-uid_123');
    });

    test('parses a legacy seed deep link', () {
      final payload = SeedQrPayload.tryParse(
        'greenfestival://seed/booth-uid_123?v1',
      );

      expect(payload?.seedUid, 'booth-uid_123');
    });

    test('rejects unknown QR values', () {
      expect(
        SeedQrPayload.tryParse('greenfestival://user/booth-uid_123?v1'),
        isNull,
      );
      expect(
        SeedQrPayload.tryParse('https://example.com/booth-uid_123'),
        isNull,
      );
    });
  });
}
