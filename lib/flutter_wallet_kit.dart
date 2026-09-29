import 'package:flutter/foundation.dart';

import 'flutter_wallet_kit_platform_interface.dart';
import 'src/google_wallet_pass.dart';
import 'src/wallet_models.dart';

export 'src/google_wallet_pass.dart';
export 'src/wallet_buttons.dart';
export 'src/wallet_models.dart';

/// Unified Apple Wallet and Google Wallet API.
class FlutterWalletKit {
  const FlutterWalletKit();

  /// Whether the active platform can present its native add-to-wallet flow.
  Future<bool> isWalletSupported() {
    return FlutterWalletKitPlatform.instance.isWalletSupported();
  }

  /// Adds the platform-specific pass.
  ///
  /// Supply [iosPassData] with complete `.pkpass` bytes on iOS. Supply a
  /// backend-signed Google Wallet [androidJwt], or unsigned Android SDK
  /// [androidPassJson], on Android. Android values are mutually exclusive.
  Future<WalletResult> addPass({
    Uint8List? iosPassData,
    String? androidJwt,
    String? androidPassJson,
  }) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return SynchronousFuture(WalletResult.unsupportedPlatform);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        (iosPassData == null || iosPassData.isEmpty)) {
      return SynchronousFuture(WalletResult.invalidPass);
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        !_hasExactlyOneAndroidPass(androidJwt, androidPassJson)) {
      return SynchronousFuture(WalletResult.invalidPass);
    }
    return FlutterWalletKitPlatform.instance.addPass(
      iosPassData: iosPassData,
      androidJwt: androidJwt,
      androidPassJson: androidPassJson,
    );
  }

  /// Adds unsigned metadata through Android's `PayClient.savePasses` API.
  Future<WalletResult> addGoogleWalletPass(GoogleWalletPass pass) {
    return addPass(androidPassJson: pass.json);
  }

  /// Checks whether an Apple pass is already installed.
  ///
  /// On Android this returns [WalletPassStatus.unsupported], because Google
  /// Wallet does not provide an equivalent pass-presence API.
  Future<WalletPassStatus> getPassStatus({required Uint8List iosPassData}) {
    if (iosPassData.isEmpty) {
      return SynchronousFuture(WalletPassStatus.invalidPass);
    }
    return FlutterWalletKitPlatform.instance.getPassStatus(iosPassData);
  }

  static bool _hasExactlyOneAndroidPass(String? jwt, String? json) {
    final hasJwt = jwt != null && jwt.trim().isNotEmpty;
    final hasJson = json != null && json.trim().isNotEmpty;
    return hasJwt != hasJson;
  }
}
