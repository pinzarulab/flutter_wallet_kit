import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_wallet_kit_platform_interface.dart';
import 'src/wallet_models.dart';

class MethodChannelFlutterWalletKit extends FlutterWalletKitPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_wallet_kit');

  @override
  Future<bool> isWalletSupported() async {
    try {
      return await methodChannel.invokeMethod<bool>('isWalletSupported') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<WalletResult> addPass({
    Uint8List? iosPassData,
    String? androidJwt,
    String? androidPassJson,
  }) async {
    try {
      final value = await methodChannel.invokeMethod<String>('addPass', {
        if (iosPassData != null) 'iosPassData': iosPassData,
        if (androidJwt != null) 'androidJwt': androidJwt,
        if (androidPassJson != null) 'androidPassJson': androidPassJson,
      });
      return _walletResult(value);
    } on MissingPluginException {
      return WalletResult.unsupportedPlatform;
    } on PlatformException catch (error) {
      return _walletResult(error.code);
    }
  }

  @override
  Future<WalletPassStatus> getPassStatus(Uint8List iosPassData) async {
    try {
      final value = await methodChannel.invokeMethod<String>('getPassStatus', {
        'iosPassData': iosPassData,
      });
      return switch (value) {
        'added' => WalletPassStatus.added,
        'notAdded' => WalletPassStatus.notAdded,
        'invalidPass' => WalletPassStatus.invalidPass,
        _ => WalletPassStatus.unsupported,
      };
    } on MissingPluginException {
      return WalletPassStatus.unsupported;
    } on PlatformException catch (error) {
      return error.code == 'invalidPass'
          ? WalletPassStatus.invalidPass
          : WalletPassStatus.unsupported;
    }
  }

  WalletResult _walletResult(String? value) => switch (value) {
        'success' => WalletResult.success,
        'cancelled' => WalletResult.cancelled,
        'alreadyAdded' => WalletResult.alreadyAdded,
        'walletUnavailable' => WalletResult.walletUnavailable,
        'invalidPass' => WalletResult.invalidPass,
        'operationInProgress' => WalletResult.operationInProgress,
        'unsupportedPlatform' => WalletResult.unsupportedPlatform,
        _ => WalletResult.internalError,
      };
}
