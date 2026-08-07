import Foundation
import google_mobile_ads
import UIKit

class ExampleNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd, // ← 언더스코어로 레이블 제거!
    customOptions: [AnyHashable : Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = .clear

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    row.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(row)

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFill
    iconView.clipsToBounds = true
    iconView.layer.cornerRadius = 20
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: 40).isActive = true
    if let icon = nativeAd.icon?.image {
      iconView.image = icon
    }
    adView.iconView = iconView
    row.addArrangedSubview(iconView)

    let textColumn = UIStackView()
    textColumn.axis = .vertical
    textColumn.spacing = 4
    textColumn.alignment = .leading

    let headline = UILabel()
    headline.text = nativeAd.headline
    headline.font = UIFont.boldSystemFont(ofSize: 15)
    headline.numberOfLines = 1
    adView.headlineView = headline
    textColumn.addArrangedSubview(headline)

    if let bodyText = nativeAd.body {
      let body = UILabel()
      body.text = bodyText
      body.font = UIFont.systemFont(ofSize: 13)
      body.textColor = UIColor.darkGray
      body.numberOfLines = 2
      adView.bodyView = body
      textColumn.addArrangedSubview(body)
    }

    row.addArrangedSubview(textColumn)

    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
      row.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 4),
      row.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -4),
      row.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -4),
    ])

    adView.nativeAd = nativeAd
    return adView
  }
}
