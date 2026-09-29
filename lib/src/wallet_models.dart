/// Result of an attempt to add a pass to a device wallet.
enum WalletResult {
  success,
  cancelled,
  alreadyAdded,
  unsupportedPlatform,
  walletUnavailable,
  invalidPass,
  operationInProgress,
  internalError,
}

/// Installation state of a pass.
///
/// Google Wallet does not expose a client API for querying whether a JWT-backed
/// pass is already saved, so Android returns [unsupported].
enum WalletPassStatus { added, notAdded, unsupported, invalidPass }

/// Error delivered by callback-based wallet widgets.
final class WalletException implements Exception {
  const WalletException(this.result, [this.message]);

  final WalletResult result;
  final String? message;

  @override
  String toString() =>
      message ??
      switch (result) {
        WalletResult.unsupportedPlatform => 'Wallet platform is unsupported.',
        WalletResult.walletUnavailable => 'Google Wallet is unavailable.',
        WalletResult.invalidPass => 'Google Wallet pass data is invalid.',
        WalletResult.operationInProgress =>
          'Another wallet operation is already in progress.',
        WalletResult.internalError =>
          'Google Wallet returned an internal error.',
        _ => 'Wallet operation failed: ${result.name}.',
      };
}
