import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';

void main() {
  const keys = {
    GoogleWalletPassType.generic: 'genericObjects',
    GoogleWalletPassType.loyalty: 'loyaltyObjects',
    GoogleWalletPassType.offer: 'offerObjects',
    GoogleWalletPassType.giftCard: 'giftCardObjects',
    GoogleWalletPassType.eventTicket: 'eventTicketObjects',
    GoogleWalletPassType.flight: 'flightObjects',
    GoogleWalletPassType.transit: 'transitObjects',
  };

  for (final entry in keys.entries) {
    test('builds ${entry.key.name} metadata', () {
      final pass = GoogleWalletPass.metadata(
        type: entry.key,
        issuerEmail: 'wallet@example.iam.gserviceaccount.com',
        issuerId: 'issuer-123',
        objectId: 'object-1',
        classId: 'class-1',
        issuedAt: 123,
        values: const {'custom': 'value'},
      );
      final decoded = jsonDecode(pass.json) as Map<String, dynamic>;
      final payload = decoded['payload'] as Map<String, dynamic>;
      final object = (payload[entry.value] as List).single as Map;

      expect(decoded['iat'], 123);
      expect(object['id'], 'issuer-123.object-1');
      expect(object['classId'], 'issuer-123.class-1');
      expect(object['state'], 'ACTIVE');
      expect(object['custom'], 'value');
    });
  }

  test('includes optional class metadata', () {
    final pass = GoogleWalletPass.metadata(
      type: GoogleWalletPassType.loyalty,
      issuerEmail: 'wallet@example.iam.gserviceaccount.com',
      issuerId: 'issuer',
      objectId: 'object',
      classId: 'class',
      passClass: const {'id': 'issuer.class'},
    );
    final decoded = jsonDecode(pass.json) as Map<String, dynamic>;
    final payload = decoded['payload'] as Map<String, dynamic>;
    expect(payload['loyaltyClasses'], [
      const {'id': 'issuer.class'}
    ]);
  });

  test('preserves valid custom JSON', () {
    const json = '{"iss":"custom","payload":{}}';
    expect(GoogleWalletPass.custom(json).json, json);
  });

  test('rejects malformed custom JSON', () {
    expect(() => GoogleWalletPass.custom('{'), throwsFormatException);
    expect(() => GoogleWalletPass.custom('[]'), throwsFormatException);
  });
}
