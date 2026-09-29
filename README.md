# flutter_wallet_kit

One API for adding Apple Wallet `.pkpass` files and Google Wallet metadata or signed JWTs.

## Features

- Presents Apple's native `PKAddPassesViewController`.
- Calls Google Wallet's `PayClient.savePasses` or `savePassesJwt` flow.
- Checks device/API availability.
- Detects an installed Apple pass through `PKPassLibrary.containsPass`.
- Returns strongly typed results instead of leaking platform exceptions.
- Includes Apple's native `PKAddPassButton` and Google's official localized Android XML assets.

## Install

```yaml
dependencies:
  flutter_wallet_kit: ^0.0.1
```

Supported targets: iOS 15+ and Android API 24+.

## Use

```dart
import 'dart:typed_data';

import 'package:flutter_wallet_kit/flutter_wallet_kit.dart';

const wallet = FlutterWalletKit();

final supported = await wallet.isWalletSupported();
if (!supported) return;

final result = await wallet.addPass(
  iosPassData: myPkpassBytes,
  androidJwt: mySignedGoogleWalletJwt,
);

if (result == WalletResult.success) {
  print('Pass added!');
}
```

Both arguments may be supplied from shared code. Native code uses only its platform's value.

### Build Google Wallet metadata

`GoogleWalletPass.metadata` supports `generic`, `loyalty`, `offer`, `giftCard`, `eventTicket`, `flight`, and `transit`. It generates standard envelope fields and qualified object/class IDs. Add only pass-specific fields through `values`.

```dart
final passId = DateTime.now().microsecondsSinceEpoch.toString();

final pass = GoogleWalletPass.metadata(
  type: GoogleWalletPassType.generic,
  issuerEmail: 'google-wallet-backend@example.iam.gserviceaccount.com',
  issuerId: AppConstants.issuerId,
  objectId: passId,
  classId: 'car_card',
  values: {
    'hexBackgroundColor': '#4285f4',
    'cardTitle': {
      'defaultValue': {
        'language': 'en',
        'value': 'My personal card [DEMO ONLY]',
      },
    },
    'subheader': {
      'defaultValue': {
        'language': 'en',
        'value': 'You are just better',
      },
    },
    'header': {
      'defaultValue': {
        'language': 'en',
        'value': 'OOOOOOO Satalana',
      },
    },
    'barcode': {'type': 'QR_CODE', 'value': passId},
    'textModulesData': [
      {'header': 'POINTS', 'body': '67 69', 'id': 'points'},
    ],
  },
);
```

Android SDK signs this metadata using your registered app-signing certificate. No service-account private key is stored in Flutter.

### Check Apple pass status

```dart
final status = await wallet.getPassStatus(iosPassData: myPkpassBytes);
final isAdded = status == WalletPassStatus.added;
```

Google Wallet has no equivalent client API, so Android returns `WalletPassStatus.unsupported`.

### Official buttons

```dart
AddToAppleWalletButton(
  onPressed: () => wallet.addPass(iosPassData: myPkpassBytes),
)

AddToGoogleWalletButton(
  pass: pass,
  onSuccess: () => showSnackBar(context, 'Success!'),
  onCanceled: () => showSnackBar(context, 'Action canceled.'),
  onError: (error) => showSnackBar(context, error.toString()),
)
```

For complete control, pass developer-authored JSON directly:

```dart
AddToGoogleWalletButton(
  pass: myCompleteJsonString,
  onSuccess: onSuccess,
  onCanceled: onCanceled,
  onError: onError,
)
```

Or validate/store it first with `GoogleWalletPass.custom(myCompleteJsonString)`. Existing manual button usage remains supported through `onPressed`.

Each button renders only on its native platform. Apple uses system-provided, localized `PKAddPassButton`. Android bundles Google's official localized XML assets, enforces its 200dp × 48dp minimum, and includes required 8dp clear space by default.

## Backend requirement

For signed JWT mode, generate and sign Google Wallet JWTs on a trusted backend. Never ship a service-account private key in a Flutter app. For metadata mode, Android's SDK signs the JSON using the app certificate. Register the Android package name and signing-certificate SHA-1 fingerprint in Google Wallet Business Console.

Apple `.pkpass` files must include a valid Apple-issued signature. Pass bytes may be downloaded by the app, but pass signing belongs on a secure server.

## Results

`addPass` returns one of:

- `success`
- `cancelled`
- `alreadyAdded` (iOS)
- `unsupportedPlatform`
- `walletUnavailable`
- `invalidPass`
- `operationInProgress`
- `internalError`

## Platform notes

No Wallet entitlement is needed merely to present and add a signed `.pkpass`. Access to other passes remains governed by Apple's PassKit entitlements.

Android SDK dependency: `com.google.android.gms:play-services-pay:16.5.0`.
