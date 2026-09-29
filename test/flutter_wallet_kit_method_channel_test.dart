import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterWalletKit();
  const channel = MethodChannel('flutter_wallet_kit');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isWalletSupported' => true,
        'addPass' => 'alreadyAdded',
        'getPassStatus' => 'added',
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps support response', () async {
    expect(await platform.isWalletSupported(), isTrue);
  });

  test('passes both payloads and maps add result', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(
      await platform.addPass(iosPassData: bytes, androidJwt: 'signed.jwt'),
      WalletResult.alreadyAdded,
    );
    expect(calls.single.arguments, {
      'iosPassData': bytes,
      'androidJwt': 'signed.jwt',
    });
  });

  test('passes unsigned Android metadata', () async {
    const json = '{"payload":{"genericObjects":[]}}';
    await platform.addPass(androidPassJson: json);
    expect(calls.single.arguments, {'androidPassJson': json});
  });

  test('maps pass status', () async {
    expect(
      await platform.getPassStatus(Uint8List.fromList([1])),
      WalletPassStatus.added,
    );
  });

  test('maps platform errors to typed results', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'invalidPass'),
    );
    expect(await platform.addPass(androidJwt: 'bad'), WalletResult.invalidPass);
  });
}
