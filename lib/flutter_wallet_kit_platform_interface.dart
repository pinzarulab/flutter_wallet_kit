import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_wallet_kit_method_channel.dart';
import 'src/wallet_models.dart';

abstract class FlutterWalletKitPlatform extends PlatformInterface {
  FlutterWalletKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWalletKitPlatform _instance = MethodChannelFlutterWalletKit();

  static FlutterWalletKitPlatform get instance => _instance;

  static set instance(FlutterWalletKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isWalletSupported() {
    throw UnimplementedError('isWalletSupported() has not been implemented.');
  }

  Future<WalletResult> addPass({
    Uint8List? iosPassData,
    String? androidJwt,
    String? androidPassJson,
  }) {
    throw UnimplementedError('addPass() has not been implemented.');
  }

  Future<WalletPassStatus> getPassStatus(Uint8List iosPassData) {
    throw UnimplementedError('getPassStatus() has not been implemented.');
  }
}
