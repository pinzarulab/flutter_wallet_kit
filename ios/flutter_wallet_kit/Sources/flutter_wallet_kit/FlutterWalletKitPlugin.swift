import Flutter
import PassKit
import UIKit

public class FlutterWalletKitPlugin: NSObject, FlutterPlugin, PKAddPassesViewControllerDelegate {
  private var pendingResult: FlutterResult?
  private var pendingPass: PKPass?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_wallet_kit", binaryMessenger: registrar.messenger())
    let instance = FlutterWalletKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.register(
      AppleWalletButtonFactory(messenger: registrar.messenger()),
      withId: "flutter_wallet_kit/apple_wallet_button"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isWalletSupported":
      result(PKPassLibrary.isPassLibraryAvailable() && PKAddPassesViewController.canAddPasses())
    case "addPass":
      addPass(call, result: result)
    case "getPassStatus":
      getPassStatus(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func addPass(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result("operationInProgress")
      return
    }
    guard PKPassLibrary.isPassLibraryAvailable(), PKAddPassesViewController.canAddPasses() else {
      result("walletUnavailable")
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["iosPassData"] as? FlutterStandardTypedData
    else {
      result("invalidPass")
      return
    }

    let pass: PKPass
    do {
      pass = try PKPass(data: typedData.data)
    } catch {
      result("invalidPass")
      return
    }

    if PKPassLibrary().containsPass(pass) {
      result("alreadyAdded")
      return
    }
    guard
      let controller = PKAddPassesViewController(pass: pass),
      let presenter = Self.topViewController()
    else {
      result("walletUnavailable")
      return
    }

    pendingResult = result
    pendingPass = pass
    controller.delegate = self
    DispatchQueue.main.async {
      presenter.present(controller, animated: true)
    }
  }

  private func getPassStatus(_ call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["iosPassData"] as? FlutterStandardTypedData,
      let pass = try? PKPass(data: typedData.data)
    else {
      result("invalidPass")
      return
    }
    result(PKPassLibrary().containsPass(pass) ? "added" : "notAdded")
  }

  public func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
    let result = pendingResult
    let wasAdded = pendingPass.map { PKPassLibrary().containsPass($0) } ?? false
    pendingResult = nil
    pendingPass = nil
    controller.dismiss(animated: true) {
      result?(wasAdded ? "success" : "cancelled")
    }
  }

  private static func topViewController() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }?
      .rootViewController
    return topViewController(from: root)
  }

  private static func topViewController(from controller: UIViewController?) -> UIViewController? {
    if let presented = controller?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = controller as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tabs = controller as? UITabBarController {
      return topViewController(from: tabs.selectedViewController)
    }
    return controller
  }
}

private final class AppleWalletButtonFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func createArgsCodec() -> any FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AppleWalletButtonView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }
}

private final class AppleWalletButtonView: NSObject, FlutterPlatformView {
  private let button: PKAddPassButton
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    let arguments = args as? [String: Any]
    let style: PKAddPassButtonStyle = arguments?["style"] as? String == "blackOutline"
      ? .blackOutline
      : .black
    button = PKAddPassButton(addPassButtonStyle: style)
    button.frame = frame
    button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    channel = FlutterMethodChannel(
      name: "flutter_wallet_kit/apple_button_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    button.addTarget(self, action: #selector(pressed), for: .touchUpInside)
  }

  func view() -> UIView { button }

  @objc private func pressed() {
    channel.invokeMethod("onPressed", arguments: nil)
  }
}
