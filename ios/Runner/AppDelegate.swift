import Flutter
import UIKit
import CoreTelephony

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let carrierChannel = FlutterMethodChannel(name: "custom.carrier.info",
                                              binaryMessenger: controller.binaryMessenger)
    carrierChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getCarrierName" {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
          result(carrier.carrierName ?? "Unavailable")
        } else {
          result("Unavailable")
        }
      }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
