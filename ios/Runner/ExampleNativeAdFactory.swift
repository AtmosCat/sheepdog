import Foundation
import google_mobile_ads
import UIKit

class ExampleNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd, // ← 언더스코어로 레이블 제거!
    customOptions: [AnyHashable : Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = .white
    adView.layer.cornerRadius = 20
    adView.clipsToBounds = true

    // Headline
    let headline = UILabel()
    headline.text = nativeAd.headline
    headline.font = UIFont.boldSystemFont(ofSize: 16)
    headline.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(headline)
    adView.headlineView = headline

    // Body
    if let bodyText = nativeAd.body {
      let body = UILabel()
      body.text = bodyText
      body.font = UIFont.systemFont(ofSize: 14)
      body.translatesAutoresizingMaskIntoConstraints = false
      adView.addSubview(body)
      adView.bodyView = body

      NSLayoutConstraint.activate([
        headline.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
        headline.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
        headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),

        body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 8),
        body.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
        body.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
        body.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16)
      ])
    } else {
      NSLayoutConstraint.activate([
        headline.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
        headline.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
        headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
        headline.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16)
      ])
    }

    adView.nativeAd = nativeAd
    return adView
  }
}
