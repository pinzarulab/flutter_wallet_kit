import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wallet support check returns a boolean', (_) async {
    const wallet = FlutterWalletKit();
    final supported = await wallet.isWalletSupported();
    expect(supported, isA<bool>());
  });
}
