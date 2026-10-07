import Flutter
import UIKit
import FBSDKCoreKit

public class SwiftFlutterFacebookAuthPlugin: NSObject, FlutterPlugin {
    let facebookAuth = FacebookAuth()

    public static func register(with registrar: FlutterPluginRegistrar) {
        ApplicationDelegate.initialize()
        let channel = FlutterMethodChannel(name: "app.meedu/flutter_facebook_auth", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterFacebookAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.facebookAuth.handle(call, result: result)
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]) -> Bool {
        return true
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let urlOptions: [UIApplication.OpenURLOptionsKey: Any] = options
        return ApplicationDelegate.shared.application(app, open: url, options: urlOptions)
    }
}
