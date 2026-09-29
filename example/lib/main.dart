import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';

void main() => runApp(const WalletExampleApp());

class WalletExampleApp extends StatelessWidget {
  const WalletExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WalletExamplePage());
  }
}

class WalletExamplePage extends StatefulWidget {
  const WalletExamplePage({super.key});

  @override
  State<WalletExamplePage> createState() => _WalletExamplePageState();
}

class _WalletExamplePageState extends State<WalletExamplePage> {
  static const wallet = FlutterWalletKit();
  bool? supported;
  WalletResult? lastResult;

  // Replace placeholders with real issuer/class values.
  final Uint8List pkpassBytes = Uint8List(0);
  late final GoogleWalletPass googlePass = GoogleWalletPass.metadata(
    type: GoogleWalletPassType.generic,
    issuerEmail: 'wallet@example.iam.gserviceaccount.com',
    issuerId: '123456789',
    objectId: 'card-${DateTime.now().millisecondsSinceEpoch}',
    classId: 'car_card',
    values: const {
      'hexBackgroundColor': '#4285f4',
      'cardTitle': {
        'defaultValue': {'language': 'en', 'value': 'My personal card'},
      },
      'header': {
        'defaultValue': {'language': 'en', 'value': 'Example pass'},
      },
      'barcode': {'type': 'QR_CODE', 'value': 'example'},
    },
  );

  @override
  void initState() {
    super.initState();
    wallet.isWalletSupported().then((value) {
      if (mounted) setState(() => supported = value);
    });
  }

  Future<void> addApplePass() async {
    final result = await wallet.addPass(iosPassData: pkpassBytes);
    if (mounted) setState(() => lastResult = result);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_wallet_kit')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wallet supported: ${supported ?? 'checking…'}'),
            const SizedBox(height: 24),
            AddToAppleWalletButton(onPressed: addApplePass),
            AddToGoogleWalletButton(
              pass: googlePass,
              onSuccess: () => showMessage('Success!'),
              onCanceled: () => showMessage('Action canceled.'),
              onError: (error) => showMessage(error.toString()),
            ),
            if (lastResult != null) Text('Result: ${lastResult!.name}'),
          ],
        ),
      ),
    );
  }
}
