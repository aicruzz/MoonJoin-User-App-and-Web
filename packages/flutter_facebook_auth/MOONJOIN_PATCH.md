# flutter_facebook_auth (vendored)

Upstream: https://github.com/darwin-morocho/flutter-facebook-auth
Branch `sdk-18.x`, commit `13a779835fda4ca31e9fd5c67c3a56c1df3a96e8` (v7.1.2),
package directory `facebook_auth/`. `example/` and `test/` are not included.

This copy carries a local iOS patch that previously lived only in one machine's
`~/.pub-cache`, so a clean checkout did not build the validated Facebook login.
Vendoring it makes the release reproducible. The Android and Dart sources are
unchanged from upstream.

## iOS changes against upstream

- `ios/Classes/FacebookAuthBridge.h` / `.m` (new): Objective-C bridge that builds
  the `FBSDKLoginConfiguration` and calls `FBSDKLoginManager` for login.
- `ios/Classes/FacebookAuth.swift`: login goes through `FacebookAuthBridge`
  (tracking passed as 0 = enabled, 1 = limited).
- `ios/Classes/SwiftFlutterFacebookAuthPlugin.swift`: the plugin's
  `didFinishLaunchingWithOptions` no longer forwards to the Facebook SDK. The app
  initialises the SDK itself in `ios/Runner/AppDelegate.swift`
  (`ApplicationDelegate.shared.initializeSDK()`); keep that call.

Do not replace this package with the upstream git dependency without re-applying
and re-validating these changes on a physical iPhone.
