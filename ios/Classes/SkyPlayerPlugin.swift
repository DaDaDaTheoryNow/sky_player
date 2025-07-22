import Flutter
import UIKit

public class SkyPlayerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sky_player_channel", binaryMessenger: registrar.messenger())
      
    let factory = FLNativeViewFactory(messenger: registrar.messenger())
    registrar.register(
              factory,
              withId: "sky_player_view")
      
    let instance = SkyPlayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
