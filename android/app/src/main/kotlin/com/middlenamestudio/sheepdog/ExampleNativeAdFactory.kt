package com.middlenamestudio.sheepdog

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.view.View
import android.widget.FrameLayout

class ExampleNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): FrameLayout {
        // 광고 레이아웃을 위한 XML 레이아웃 파일을 만들어 사용하거나, 코드로 직접 구성할 수 있습니다.
        val adView = LayoutInflater.from(context).inflate(R.layout.native_ad_layout, null) as FrameLayout

        // 예시: 광고 제목, 설명, 아이콘 등 연결
        adView.findViewById<TextView>(R.id.ad_headline).text = nativeAd.headline
        adView.findViewById<TextView>(R.id.ad_body).text = nativeAd.body
        nativeAd.icon?.drawable?.let {
            adView.findViewById<ImageView>(R.id.ad_icon).setImageDrawable(it)
        }

        // 기타 광고 요소 연결(필요에 따라)
        // ...

        return adView
    }
}
