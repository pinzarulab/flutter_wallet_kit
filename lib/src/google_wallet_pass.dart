import 'dart:convert';

/// Google Wallet pass families supported by save-to-wallet payloads.
enum GoogleWalletPassType {
  generic,
  loyalty,
  offer,
  giftCard,
  eventTicket,
  flight,
  transit,
}

extension on GoogleWalletPassType {
  String get objectsKey => switch (this) {
        GoogleWalletPassType.generic => 'genericObjects',
        GoogleWalletPassType.loyalty => 'loyaltyObjects',
        GoogleWalletPassType.offer => 'offerObjects',
        GoogleWalletPassType.giftCard => 'giftCardObjects',
        GoogleWalletPassType.eventTicket => 'eventTicketObjects',
        GoogleWalletPassType.flight => 'flightObjects',
        GoogleWalletPassType.transit => 'transitObjects',
      };

  String get classesKey => switch (this) {
        GoogleWalletPassType.generic => 'genericClasses',
        GoogleWalletPassType.loyalty => 'loyaltyClasses',
        GoogleWalletPassType.offer => 'offerClasses',
        GoogleWalletPassType.giftCard => 'giftCardClasses',
        GoogleWalletPassType.eventTicket => 'eventTicketClasses',
        GoogleWalletPassType.flight => 'flightClasses',
        GoogleWalletPassType.transit => 'transitClasses',
      };
}

/// Unsigned Google Wallet JSON consumed by Android's `PayClient.savePasses`.
///
/// Android signs this metadata with the app signing certificate registered in
/// Google Wallet Business Console. No private key belongs in the app.
final class GoogleWalletPass {
  GoogleWalletPass._(this.json);

  /// Complete JSON envelope passed to Google Wallet.
  final String json;

  /// Builds a standard save-to-wallet envelope for any supported pass type.
  ///
  /// [values] contains type-specific object fields. `id`, `classId`, and
  /// `state` are supplied automatically. [passClass] is optional when its class
  /// already exists in Google Wallet Business Console or was created earlier.
  factory GoogleWalletPass.metadata({
    required GoogleWalletPassType type,
    required String issuerEmail,
    required String issuerId,
    required String objectId,
    required String classId,
    Map<String, Object?> values = const {},
    Map<String, Object?>? passClass,
    String state = 'ACTIVE',
    int? issuedAt,
    List<String> origins = const [],
  }) {
    _requireValue(issuerEmail, 'issuerEmail');
    _requireValue(issuerId, 'issuerId');
    _requireValue(objectId, 'objectId');
    _requireValue(classId, 'classId');
    _requireValue(state, 'state');

    final object = <String, Object?>{
      ...values,
      'id': _qualifiedId(issuerId, objectId),
      'classId': _qualifiedId(issuerId, classId),
      'state': state,
    };
    final payload = <String, Object?>{
      if (passClass != null)
        type.classesKey: [
          {...passClass, 'id': _qualifiedId(issuerId, classId)},
        ],
      type.objectsKey: [object],
    };
    return GoogleWalletPass._(
      jsonEncode({
        'iss': issuerEmail,
        'aud': 'google',
        'typ': 'savetowallet',
        'iat': issuedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'origins': origins,
        'payload': payload,
      }),
    );
  }

  /// Uses developer-authored save-to-wallet JSON without altering it.
  factory GoogleWalletPass.custom(String json) {
    final value = json.trim();
    if (value.isEmpty) {
      throw const FormatException('Google Wallet pass JSON cannot be empty.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException catch (error) {
      throw FormatException(
          'Invalid Google Wallet pass JSON: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Google Wallet pass JSON must contain a top-level object.',
      );
    }
    return GoogleWalletPass._(value);
  }

  static String _qualifiedId(String issuerId, String value) {
    return value.contains('.') ? value : '$issuerId.$value';
  }

  static void _requireValue(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Cannot be empty.');
    }
  }

  @override
  String toString() => json;
}
