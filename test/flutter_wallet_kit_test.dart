import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit_method_channel.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeWalletPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWalletKitPlatform {
  @override
  Future<WalletResult> addPass({
    Uint8List? iosPassData,
    String? androidJwt,
    String? androidPassJson,
  }) async =>
      WalletResult.success;

  @override
  Future<WalletPassStatus> getPassStatus(Uint8List iosPassData) async =>
      WalletPassStatus.added;

  @override
  Future<bool> isWalletSupported() async => true;
}

void main() {
  final initialPlatform = FlutterWalletKitPlatform.instance;

  tearDown(() => FlutterWalletKitPlatform.instance = initialPlatform);

  test('$MethodChannelFlutterWalletKit is default instance', () {
    expect(initialPlatform, isA<MethodChannelFlutterWalletKit>());
  });

  test('delegates public operations', () async {
    FlutterWalletKitPlatform.instance = FakeWalletPlatform();
    const wallet = FlutterWalletKit();

    expect(await wallet.isWalletSupported(), isTrue);
    expect(
      await wallet.addPass(
        iosPassData: Uint8List.fromList([1]),
        androidJwt: 'jwt',
      ),
      WalletResult.success,
    );
    expect(
      await wallet.getPassStatus(iosPassData: Uint8List.fromList([1])),
      WalletPassStatus.added,
    );
  });

  test('delegates generated Google Wallet metadata', () async {
    FlutterWalletKitPlatform.instance = FakeWalletPlatform();
    const wallet = FlutterWalletKit();
    final pass = GoogleWalletPass.metadata(
      type: GoogleWalletPassType.generic,
      issuerEmail: 'wallet@example.iam.gserviceaccount.com',
      issuerId: '123456789',
      objectId: 'object-1',
      classId: 'generic-class',
      values: const {'hexBackgroundColor': '#4285f4'},
      issuedAt: 123,
    );

    expect(await wallet.addGoogleWalletPass(pass), WalletResult.success);
  });

  test('rejects empty pass data before platform call', () async {
    const wallet = FlutterWalletKit();
    expect(
      await wallet.getPassStatus(iosPassData: Uint8List(0)),
      WalletPassStatus.invalidPass,
    );
  });
}
