import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet_kit_example/main.dart';

void main() {
  testWidgets('shows wallet support state', (tester) async {
    await tester.pumpWidget(const WalletExampleApp());
    expect(find.textContaining('Wallet supported:'), findsOneWidget);
  });
}
