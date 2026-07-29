import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure native Firebase before any Auth / APNs work.
    // Dart `Firebase.initializeApp` is a no-op when an app already exists.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Silent APNs is required for Firebase Phone Auth without Safari reCAPTCHA.
    // User permission is NOT required for silent verification pushes.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward APNs token to Firebase Auth (required for silent phone verification).
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Prefer `.unknown` so the SDK detects sandbox vs production from the
    // provisioning profile — DEBUG/RELEASE macros alone are unreliable.
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    NSLog(
      "[PhoneAuth] APNs token registered with Firebase Auth "
        + "(bytes=\(deviceToken.count), type=unknown/auto)"
    )
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog(
      "[PhoneAuth] APNs registration failed: \(error.localizedDescription). "
        + "Firebase Phone Auth will fall back to Safari reCAPTCHA."
    )
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Handle silent push for phone auth verification.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      NSLog("[PhoneAuth] Handled Firebase Auth silent verification notification")
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  // Handle reCAPTCHA / OAuth redirect URLs for phone auth fallback.
  // Also forwards unknown URLs to Flutter/plugins (Razorpay UPI return paths
  // are handled inside the Razorpay iOS SDK presented Checkout).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  // iOS 13+ scene / universal-link style opens — keep Firebase Auth covered.
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL, Auth.auth().canHandle(url) {
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }
}
