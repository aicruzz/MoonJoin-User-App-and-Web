//
//  FacebookAuth.swift
//
import FBSDKLoginKit
import Flutter
import Foundation

class FacebookAuth: NSObject {
    let loginManager: LoginManager = .init()
    var pendingResult: FlutterResult? = nil
    private var mainWindow: UIWindow? {
        if let applicationWindow = UIApplication.shared.delegate?.window ?? nil {
            return applicationWindow
        }
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.session.role == .windowApplication }),
               let sceneDelegate = scene.delegate as? UIWindowSceneDelegate,
               let window = sceneDelegate.window as? UIWindow {
                return window
            }
        }
        return nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "login":
            let permissions = args?["permissions"] as! [String]
            let tracking = args?["tracking"] as! String
            let customNonce = args?["nonce"] as? String
            login(permissions: permissions, flutterResult: result, tracking: tracking == "limited" ? 1 : 0, nonce: customNonce)
        case "getAccessToken":
            if let token = AccessToken.current, !token.isExpired {
                result(getAccessToken(accessToken: token, authenticationToken: AuthenticationToken.current, isLimitedLogin: isLimitedLogin()))
            } else if let authToken = AuthenticationToken.current {
                result(getAccessToken(accessToken: nil, authenticationToken: authToken, isLimitedLogin: isLimitedLogin()))
            } else {
                result(nil)
            }
        case "getUserData":
            let fields = args?["fields"] as! String
            getUserData(fields: fields, flutterResult: result)
        case "logOut":
            loginManager.logOut()
            result(nil)
        case "updateAutoLogAppEventsEnabled":
            let enabled = args?["enabled"] as! Bool
            Settings.shared.isAutoLogAppEventsEnabled = enabled
            result(nil)
        case "isAutoLogAppEventsEnabled":
            result(Settings.shared.isAutoLogAppEventsEnabled)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func login(permissions: [String], flutterResult: @escaping FlutterResult, tracking: UInt, nonce: String?) {
        guard setPendingResult(methodName: "login", flutterResult: flutterResult) else { return }
        let isLimited = !Settings.shared.isAdvertiserTrackingEnabled
        let resolvedTracking: UInt = isLimited ? 1 : tracking
        let viewController = mainWindow?.rootViewController
        FacebookAuthBridge.login(withPermissions: permissions, viewController: viewController, tracking: resolvedTracking, nonce: nonce ?? UUID().uuidString) { [weak self] result, error, cancelled in
            guard let self = self else { return }
            if let error = error {
                self.finishWithError(errorCode: "FAILED", message: error.localizedDescription)
                return
            }
            if cancelled {
                self.finishWithError(errorCode: "CANCELLED", message: "User has cancelled login with facebook")
                return
            }
            if let loginResult = result as? LoginManagerLoginResult {
                self.setIsLimitedLogin(isLimited)
                self.finishWithResult(data: self.getAccessToken(accessToken: loginResult.token, authenticationToken: AuthenticationToken.current, isLimitedLogin: isLimited))
            }
        }
    }

    private func getUserData(fields: String, flutterResult: @escaping FlutterResult) {
        let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": fields])
        graphRequest.start { _, result, error in
            if let error = error {
                self.sendErrorToClient(result: flutterResult, errorCode: "FAILED", message: error.localizedDescription)
            } else {
                flutterResult(result as! NSDictionary)
            }
        }
    }

    private func setPendingResult(methodName: String, flutterResult: @escaping FlutterResult) -> Bool {
        if pendingResult != nil {
            sendErrorToClient(result: pendingResult!, errorCode: "OPERATION_IN_PROGRESS", message: "The method \(methodName) called while another Facebook login operation was in progress.")
            return false
        }
        pendingResult = flutterResult
        return true
    }

    private func finishWithResult(data: Any?) {
        pendingResult?(data)
        pendingResult = nil
    }

    private func finishWithError(errorCode: String, message: String) {
        if let pending = pendingResult {
            sendErrorToClient(result: pending, errorCode: errorCode, message: message)
            pendingResult = nil
        }
    }

    private func sendErrorToClient(result: FlutterResult, errorCode: String, message: String) {
        result(FlutterError(code: errorCode, message: message, details: nil))
    }

    private func getAccessToken(accessToken: AccessToken?, authenticationToken: AuthenticationToken?, isLimitedLogin: Bool) -> [String: Any] {
        if isLimitedLogin || accessToken == nil {
            return [
                "type": "limited",
                "userId": NSNull(),
                "userEmail": NSNull(),
                "userName": NSNull(),
                "token": authenticationToken?.tokenString as Any,
                "nonce": authenticationToken?.nonce as Any,
            ]
        }
        return [
            "type": "classic",
            "token": accessToken!.tokenString,
            "userId": accessToken!.userID,
            "expires": Int64((accessToken!.expirationDate.timeIntervalSince1970 * 1000).rounded()),
            "applicationId": accessToken!.appID,
            "grantedPermissions": accessToken!.permissions.map { $0.name },
            "declinedPermissions": accessToken!.declinedPermissions.map { $0.name },
            "authenticationToken": authenticationToken?.tokenString as Any,
        ] as [String: Any]
    }

    private func setIsLimitedLogin(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "facebook_limited_login")
    }

    private func isLimitedLogin() -> Bool {
        return UserDefaults.standard.bool(forKey: "facebook_limited_login")
    }
}
