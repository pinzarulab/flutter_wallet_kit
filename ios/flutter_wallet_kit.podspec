#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_wallet_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_wallet_kit'
  s.version          = '0.0.2'
  s.summary          = 'Native Apple Wallet and Google Wallet bridge for Flutter.'
  s.description      = <<-DESC
Add signed passes to Apple Wallet and Google Wallet from Flutter.
                       DESC
  s.homepage         = 'https://pub.dev/packages/flutter_wallet_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'flutter_wallet_kit contributors'
  s.source           = { :path => '.' }
  s.source_files = 'flutter_wallet_kit/Sources/flutter_wallet_kit/**/*'
  s.dependency 'Flutter'
  s.framework = 'PassKit'
  s.platform = :ios, '15.0'
  s.resource_bundles = {'flutter_wallet_kit_privacy' => ['flutter_wallet_kit/Sources/flutter_wallet_kit/PrivacyInfo.xcprivacy']}

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
