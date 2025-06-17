package com.middlenamestudio.sheepdog

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "adFactoryExample",
            ExampleNativeAdFactory(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // factory 등록 해제 (필수)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactoryExample")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
