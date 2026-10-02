import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _ButtonPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWalletKitPlatform {
  WalletResult result = WalletResult.success;
  String? receivedJson;

  @override
  Future<WalletResult> addPass({
    Uint8List? iosPassData,
    String? androidJwt,
    String? androidPassJson,
  }) async {
    receivedJson = androidPassJson;
    return result;
  }

  @override
  Future<WalletPassStatus> getPassStatus(Uint8List iosPassData) async =>
      WalletPassStatus.unsupported;

  @override
  Future<bool> isWalletSupported() async => true;
}

void main() {
  final initialPlatform = FlutterWalletKitPlatform.instance;

  tearDown(() => FlutterWalletKitPlatform.instance = initialPlatform);

  testWidgets('custom button adds pass and reports success', (tester) async {
    final platform = _ButtonPlatform();
    FlutterWalletKitPlatform.instance = platform;
    var succeeded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WalletButton(
          androidPass: '{"payload":{"genericObjects":[]}}',
          onSuccess: () => succeeded = true,
          builder: (context, onPressed, isLoading) {
            return TextButton(
              onPressed: onPressed,
              child: Text(isLoading ? 'Loading' : 'Custom wallet button'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Custom wallet button'));
    await tester.pump();

    expect(succeeded, isTrue);
    expect(platform.receivedJson, '{"payload":{"genericObjects":[]}}');
  });

  testWidgets('custom button reports malformed JSON', (tester) async {
    FlutterWalletKitPlatform.instance = _ButtonPlatform();
    Object? receivedError;

    await tester.pumpWidget(
      MaterialApp(
        home: WalletButton(
          androidPass: '{',
          onError: (error) => receivedError = error,
          builder: (context, onPressed, isLoading) {
            return TextButton(
              onPressed: onPressed,
              child: const Text('Custom wallet button'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Custom wallet button'));
    await tester.pump();

    expect(receivedError, isA<FormatException>());
  });
}
