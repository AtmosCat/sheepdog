package com.middlenamestudio.sheepdog

import android.content.Context
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ExampleNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        // 광고 요소 연결
        adView.findViewById<TextView>(R.id.ad_headline)?.apply {
            text = nativeAd.headline
            adView.headlineView = this
        }
        adView.findViewById<TextView>(R.id.ad_body)?.apply {
            text = nativeAd.body
            adView.bodyView = this
        }
        adView.findViewById<ImageView>(R.id.ad_icon)?.apply {
            nativeAd.icon?.drawable?.let { setImageDrawable(it) }
            adView.iconView = this
        }

        // 기타 광고 요소 연결(필요시)
        // adView.callToActionView = ...
        // adView.advertiserView = ...
        // ...

        adView.setNativeAd(nativeAd)
        return adView
    }
}
