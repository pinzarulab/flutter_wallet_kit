import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../flutter_wallet_kit_platform_interface.dart';
import 'google_wallet_pass.dart';
import 'wallet_models.dart';

enum AppleWalletButtonStyle { black, blackOutline }

/// Builds a custom wallet action surface.
///
/// [onPressed] is `null` while disabled or while an operation is running.
typedef WalletButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback? onPressed,
  bool isLoading,
);

/// Platform-neutral wallet action with developer-owned visual design.
///
/// Supply both [iosPassData] and one Android value from shared code. Native
/// platform uses only its matching value.
class WalletButton extends StatefulWidget {
  const WalletButton({
    required this.builder,
    this.iosPassData,
    this.androidPass,
    this.androidJwt,
    this.onSuccess,
    this.onCanceled,
    this.onError,
    this.onResult,
    this.enabled = true,
    super.key,
  })  : assert(
          androidPass == null ||
              androidPass is String ||
              androidPass is GoogleWalletPass,
          'androidPass must be a String or GoogleWalletPass.',
        ),
        assert(
          androidPass == null || androidJwt == null,
          'Provide androidPass or androidJwt, not both.',
        );

  final WalletButtonBuilder builder;
  final Uint8List? iosPassData;

  /// [GoogleWalletPass] metadata or complete developer-authored JSON string.
  final Object? androidPass;

  /// Backend-signed Google Wallet JWT.
  final String? androidJwt;
  final VoidCallback? onSuccess;
  final VoidCallback? onCanceled;
  final ValueChanged<Object>? onError;
  final ValueChanged<WalletResult>? onResult;
  final bool enabled;

  @override
  State<WalletButton> createState() => _WalletButtonState();
}

class _WalletButtonState extends State<WalletButton> {
  bool _isLoading = false;

  Future<void> _pressed() async {
    if (_isLoading || !widget.enabled) return;
    setState(() => _isLoading = true);
    try {
      final androidPassJson = switch (widget.androidPass) {
        GoogleWalletPass value => value.json,
        String value => GoogleWalletPass.custom(value).json,
        _ => null,
      };
      final result = await FlutterWalletKitPlatform.instance.addPass(
        iosPassData: widget.iosPassData,
        androidJwt: widget.androidJwt,
        androidPassJson: androidPassJson,
      );
      if (!mounted) return;
      widget.onResult?.call(result);
      switch (result) {
        case WalletResult.success || WalletResult.alreadyAdded:
          widget.onSuccess?.call();
        case WalletResult.cancelled:
          widget.onCanceled?.call();
        default:
          widget.onError?.call(WalletException(result));
      }
    } catch (error) {
      if (mounted) widget.onError?.call(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.enabled && !_isLoading ? _pressed : null,
      _isLoading,
    );
  }
}

/// Apple's native, localized `PKAddPassButton`.
class AddToAppleWalletButton extends StatefulWidget {
  const AddToAppleWalletButton({
    required this.onPressed,
    this.style = AppleWalletButtonStyle.black,
    this.width = 140,
    this.height = 44,
    this.enabled = true,
    super.key,
  })  : assert(width > 0),
        assert(height > 0);

  final VoidCallback onPressed;
  final AppleWalletButtonStyle style;
  final double width;
  final double height;
  final bool enabled;

  @override
  State<AddToAppleWalletButton> createState() => _AddToAppleWalletButtonState();
}

class _AddToAppleWalletButtonState extends State<AddToAppleWalletButton> {
  MethodChannel? _channel;

  void _created(int id) {
    _channel = MethodChannel('flutter_wallet_kit/apple_button_$id')
      ..setMethodCallHandler((call) async {
        if (call.method == 'onPressed' && widget.enabled) widget.onPressed();
      });
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: UiKitView(
          viewType: 'flutter_wallet_kit/apple_wallet_button',
          creationParams: {'style': widget.style.name},
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _created,
        ),
      ),
    );
  }
}

/// Google's official localized Android XML Add to Google Wallet asset.
class AddToGoogleWalletButton extends StatefulWidget {
  const AddToGoogleWalletButton({
    this.pass,
    this.onPressed,
    this.onSuccess,
    this.onCanceled,
    this.onError,
    this.width = 250,
    this.height = 48,
    this.enabled = true,
    this.includeClearSpace = true,
    super.key,
  })  : assert(
          pass == null || pass is String || pass is GoogleWalletPass,
          'pass must be a String or GoogleWalletPass.',
        ),
        assert(
          onPressed != null || pass != null,
          'Provide onPressed or pass.',
        ),
        assert(width >= 200, 'Google requires a minimum width of 200dp.'),
        assert(height >= 48, 'Google requires a minimum height of 48dp.');

  /// [GoogleWalletPass] metadata or complete developer-authored JSON string.
  final Object? pass;

  /// Legacy/custom tap handler. When set, automatic [pass] handling is skipped.
  final VoidCallback? onPressed;
  final VoidCallback? onSuccess;
  final VoidCallback? onCanceled;
  final ValueChanged<Object>? onError;
  final double width;
  final double height;
  final bool enabled;

  /// Adds Google's required 8dp clear space around the asset.
  final bool includeClearSpace;

  @override
  State<AddToGoogleWalletButton> createState() =>
      _AddToGoogleWalletButtonState();
}

class _AddToGoogleWalletButtonState extends State<AddToGoogleWalletButton> {
  MethodChannel? _channel;
  bool _saving = false;

  void _created(int id) {
    _channel = MethodChannel('flutter_wallet_kit/google_button_$id')
      ..setMethodCallHandler((call) async {
        if (call.method == 'onPressed' && widget.enabled) {
          await _pressed();
        }
      });
  }

  Future<void> _pressed() async {
    if (_saving) return;
    final onPressed = widget.onPressed;
    if (onPressed != null) {
      onPressed();
      return;
    }

    _saving = true;
    try {
      final pass = widget.pass;
      final json = switch (pass) {
        GoogleWalletPass value => value.json,
        String value => GoogleWalletPass.custom(value).json,
        _ => throw ArgumentError('Missing Google Wallet pass.'),
      };
      final result = await FlutterWalletKitPlatform.instance.addPass(
        androidPassJson: json,
      );
      if (!mounted) return;
      switch (result) {
        case WalletResult.success:
          widget.onSuccess?.call();
        case WalletResult.cancelled:
          widget.onCanceled?.call();
        default:
          widget.onError?.call(WalletException(result));
      }
    } catch (error) {
      if (mounted) widget.onError?.call(error);
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    final button = IgnorePointer(
      ignoring: !widget.enabled,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AndroidView(
          viewType: 'flutter_wallet_kit/google_wallet_button',
          onPlatformViewCreated: _created,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      ),
    );
    return widget.includeClearSpace
        ? Padding(padding: const EdgeInsets.all(8), child: button)
        : button;
  }
}
