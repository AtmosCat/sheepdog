import 'package:flutter/material.dart';

enum AppColor {
  // primary
  primaryBlue,
  primaryLightBlue,
  primaryRed,
  primaryLightRed,
  primaryOrange,
  primaryLightOrange,
  primaryGreen,
  primaryLightGreen,
  onPrimaryWhite,
  shadowBlack,
  divider,
  // main theme 추가
  mainYellow,
  mainYellowLight1,
  mainYellowLight2,
  mainYellowLight3,
  mainBrown,
  mainBrownLight1,
  mainBrownLight2,
  mainBrownLight3,
  // background
  containerWhite,
  scaffoldGray,
  containerGray30,
  containerGray20,
  containerGray10,
  containerLightGray30,
  containerLightGray20,
  containerLightGray10,
  containerRed30,
  containerRed20,
  containerRed10,
  containerBlue30,
  containerBlue20,
  containerBlue10,
  // contents
  defaultBlack,
  deepBlack,
  disabled,
  gray30,
  gray20,
  gray10,
  lightGray30,
  lightGray20,
  lightGray10,
}

class AppColors {
  static final lightColorScheme = MyColor(
    colors: {
      // main theme color
      AppColor.mainYellow: Color(0xFFFFD600),
      AppColor.mainYellowLight1: Color(0xFFFFEA70),
      AppColor.mainYellowLight2: Color(0xFFFFF5B2),
      AppColor.mainYellowLight3: Color(0xFFFFFBE6),
      AppColor.mainBrown: Color(0xFF8D5524),
      AppColor.mainBrownLight1: Color(0xFFB07B4B),
      AppColor.mainBrownLight2: Color(0xFFCFA882),
      AppColor.mainBrownLight3: Color(0xFFE5D3B3),
      // 기존 primary 주요색상
      AppColor.primaryBlue: Color(0xFF007AFF),
      AppColor.primaryLightBlue: Color(0xFFB3D9FF),
      AppColor.primaryRed: Color(0xFFF2616A),
      AppColor.primaryLightRed: Color(0xFFFFC9CC),
      AppColor.primaryOrange: Color(0xFFFF8D14),
      AppColor.primaryLightOrange: Color(0xFFFFBA72),
      AppColor.primaryGreen: Color(0xFF4CAF50),
      AppColor.primaryLightGreen: Color(0xFF93CF96),
      AppColor.onPrimaryWhite: Colors.white,
      AppColor.shadowBlack: Color(0xFF000000),
      AppColor.divider: Colors.grey.withOpacity(0.2),
      // background 컬러
      AppColor.scaffoldGray: Color(0xFFF1F1F1),
      AppColor.containerWhite: Colors.white,
      AppColor.containerGray30: Color(0xFFAAAAAA),
      AppColor.containerGray20: Color(0xFFCCCCCC),
      AppColor.containerGray10: Color(0xFFEEEEEE),
      AppColor.containerLightGray30: Color(0xFFF7F7F7),
      AppColor.containerLightGray20: Color(0xFFF9F9F9),
      AppColor.containerLightGray10: Color(0xFFFBFBFB),
      AppColor.containerRed30: Color(0xFFE8878E),
      AppColor.containerRed20: Color(0xFFF1B1B9),
      AppColor.containerRed10: Color(0xFFF9E0E5),
      AppColor.containerBlue30: Color(0xFF89AEE6),
      AppColor.containerBlue20: Color(0xFFB1D4F2),
      AppColor.containerBlue10: Color(0xFFE0F0FF),
      // contents 컬러
      AppColor.defaultBlack: Color(0xFF333333),
      AppColor.deepBlack: Color(0xFF111111),
      AppColor.disabled: Color(0xFF999999),
      AppColor.gray30: Color(0xFF555555),
      AppColor.gray20: Color(0xFF777777),
      AppColor.gray10: Color(0xFF999999),
      AppColor.lightGray30: Color(0xFFAAAAAA),
      AppColor.lightGray20: Color(0xFFCCCCCC),
      AppColor.lightGray10: Color(0xFFEEEEEE),
    },
  );

  static final darkColorScheme = MyColor(
    colors: {
      // main theme color
      AppColor.mainYellow: Color(0xFFFFD600),
      AppColor.mainYellowLight1: Color(0xFFFFEA70),
      AppColor.mainYellowLight2: Color(0xFFFFF5B2),
      AppColor.mainYellowLight3: Color(0xFFFFFBE6),
      AppColor.mainBrown: Color(0xFF8D5524),
      AppColor.mainBrownLight1: Color(0xFFB07B4B),
      AppColor.mainBrownLight2: Color(0xFFCFA882),
      AppColor.mainBrownLight3: Color(0xFFE5D3B3),
      // 기존 primary 주요색상
      AppColor.primaryBlue: Color(0xFF7CA7D5),
      AppColor.primaryRed: Color(0xFFDD7980),
      AppColor.primaryOrange: Color(0xFFFF8D14),
      AppColor.primaryLightOrange: Color(0xFFFFBA72),
      AppColor.primaryGreen: Color(0xFF4CAF50),
      AppColor.primaryLightGreen: Color(0xFF93CF96),
      AppColor.onPrimaryWhite: Colors.white,
      AppColor.shadowBlack: Color(0xFF000000),
      AppColor.divider: Colors.white.withOpacity(0.2),
      AppColor.scaffoldGray: Color(0xFF121212),
      AppColor.containerWhite: Color(0xFF1E1E1E),
      AppColor.containerGray30: Color(0xFF555555),
      AppColor.containerGray20: Color(0xFF777777),
      AppColor.containerGray10: Color(0xFF999999),
      AppColor.containerLightGray30: Color(0xFF1E1E1E),
      AppColor.containerLightGray20: Color(0xFF333333),
      AppColor.containerLightGray10: Color(0xFF555555),
      AppColor.containerRed30: Color(0xFF7A5053),
      AppColor.containerRed20: Color(0xFFB77073),
      AppColor.containerRed10: Color(0xFFDC8A91),
      AppColor.containerBlue30: Color(0xFF406D92),
      AppColor.containerBlue20: Color(0xFF6B98C5),
      AppColor.containerBlue10: Color(0xFF9AB8E2),
      AppColor.defaultBlack: Color(0xFFDDDDDD),
      AppColor.deepBlack: Colors.white,
      AppColor.disabled: Color(0xFF555555),
      AppColor.gray30: Color(0xFF888888),
      AppColor.gray20: Color(0xFFAAAAAA),
      AppColor.gray10: Color(0xFFCCCCCC),
      AppColor.lightGray30: Color(0xFF555555),
      AppColor.lightGray20: Color(0xFF777777),
      AppColor.lightGray10: Color(0xFF999999),
    },
  );
}

@immutable
class MyColor extends ThemeExtension<MyColor> {
  final Map<AppColor, Color> colors;

  const MyColor({required this.colors});

  @override
  MyColor copyWith({Map<AppColor, Color>? colors}) {
    return MyColor(colors: colors ?? this.colors);
  }

  @override
  MyColor lerp(ThemeExtension<MyColor>? other, double t) {
    if (other is! MyColor) return this;

    final Map<AppColor, Color> lerpedColors = {};
    for (var key in colors.keys) {
      lerpedColors[key] = Color.lerp(colors[key], other.colors[key], t)!;
    }
    return MyColor(colors: lerpedColors);
  }

  Color getColor(AppColor key) => colors[key] ?? Colors.transparent;
}

extension AppColorExtension on AppColor {
  Color of(BuildContext context) {
    final theme = Theme.of(context).extension<MyColor>();
    return theme?.getColor(this) ?? Colors.transparent;
  }
}
