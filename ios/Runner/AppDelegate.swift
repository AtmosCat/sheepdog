import Flutter
import UIKit
import FirebaseCore
import GoogleMobileAds
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
    // 네이티브 광고 팩토리 등록
    let nativeAdFactory = ExampleNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "adFactoryExample",
      nativeAdFactory: nativeAdFactory
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
