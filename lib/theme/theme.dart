import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 메인 컬러 팔레트
const Color mainYellow = Color(0xFFFFD600); // 쨍한 노랑
const Color yellowLight1 = Color(0xFFFFEA70);
const Color yellowLight2 = Color(0xFFFFF5B2);
const Color yellowLight3 = Color(0xFFFFFBE6);

const Color mainBrown = Color(0xFF8D5524); // 쨍한 갈색
const Color brownLight1 = Color(0xFFB07B4B);
const Color brownLight2 = Color(0xFFCFA882);
const Color brownLight3 = Color(0xFFE5D3B3);

const Color primaryBlue = Color(0xFF007AFF); // 파란색(확인 버튼, 하이라이트)

/// Material 기본 보라색 대신 앱 테마 노란색을 쓰도록 ColorScheme 고정
ColorScheme _yellowLightColorScheme() {
  return ColorScheme.light(
    primary: mainYellow,
    onPrimary: Colors.black,
    primaryContainer: yellowLight2,
    onPrimaryContainer: Colors.black,
    secondary: mainYellow,
    onSecondary: Colors.black,
    secondaryContainer: yellowLight3,
    onSecondaryContainer: Colors.black,
    tertiary: mainBrown,
    onTertiary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    error: const Color(0xFFF2616A),
    onError: Colors.white,
    outline: brownLight3,
  );
}

ColorScheme _yellowDarkColorScheme() {
  return ColorScheme.dark(
    primary: mainYellow,
    onPrimary: Colors.black,
    primaryContainer: mainBrown,
    onPrimaryContainer: yellowLight1,
    secondary: yellowLight1,
    onSecondary: Colors.black,
    surface: const Color(0xFF1E1E1E),
    onSurface: yellowLight1,
    error: const Color(0xFFDD7980),
    onError: Colors.black,
  );
}

WidgetStateProperty<Color?> _yellowSwitchThumb() {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return mainYellow;
    return Colors.grey.shade400;
  });
}

WidgetStateProperty<Color?> _yellowSwitchTrack() {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return yellowLight1;
    return Colors.grey.shade300;
  });
}

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _yellowLightColorScheme(),
  primaryColor: mainYellow,
  scaffoldBackgroundColor: Colors.white,
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: mainYellow,
    primaryContrastingColor: Colors.black,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: mainYellow,
    circularTrackColor: yellowLight2,
    linearTrackColor: yellowLight2,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: _yellowSwitchThumb(),
    trackColor: _yellowSwitchTrack(),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return mainYellow;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(Colors.black),
    side: const BorderSide(color: mainBrown, width: 1.5),
  ),

  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return mainYellow;
      return brownLight1;
    }),
  ),

  sliderTheme: const SliderThemeData(
    activeTrackColor: mainYellow,
    inactiveTrackColor: yellowLight2,
    thumbColor: mainYellow,
    overlayColor: Color(0x33FFD600),
  ),

  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    headerBackgroundColor: mainYellow,
    headerForegroundColor: Colors.black,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.black;
      return Colors.black87;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return mainYellow;
      return null;
    }),
    todayForegroundColor: WidgetStateProperty.all(mainBrown),
    todayBackgroundColor: WidgetStateProperty.all(yellowLight2),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: mainYellow),
  ),

  timePickerTheme: TimePickerThemeData(
    dialHandColor: mainYellow,
    dialBackgroundColor: yellowLight3,
    hourMinuteColor: yellowLight2,
    hourMinuteTextColor: Colors.black,
    dayPeriodColor: yellowLight2,
    entryModeIconColor: mainBrown,
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: mainYellow),
  ),

  dividerTheme: const DividerThemeData(color: brownLight3, thickness: 1),

  tabBarTheme: TabBarThemeData(
    dividerColor: brownLight3,
    labelColor: mainBrown,
    unselectedLabelColor: brownLight1,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: mainYellow, width: 2),
    ),
    indicatorColor: mainYellow,
  ),

  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.black),
    scrolledUnderElevation: 0,
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.black),
    ),
  ),

  cardTheme: CardThemeData(
    color: yellowLight2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: yellowLight2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: mainYellow,
    foregroundColor: Colors.black,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: mainYellow,
      foregroundColor: Colors.black,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: mainYellow),
    ),
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(
      color: brownLight1,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  ),

  iconTheme: const IconThemeData(color: Colors.black),

  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    ),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    textColor: Colors.black,
  ),

  textSelectionTheme: TextSelectionThemeData(
    cursorColor: mainYellow,
    selectionColor: mainYellow.withValues(alpha: 0.35),
    selectionHandleColor: mainYellow,
  ),

  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    contentTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainYellow, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: brownLight3, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: brownLight3, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(color: Colors.black),
    floatingLabelStyle: TextStyle(color: mainBrown),
    hintStyle: TextStyle(color: Colors.black54),
    focusColor: mainYellow,
    prefixIconColor: mainBrown,
    suffixIconColor: mainBrown,
  ),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        }
        return Colors.black87;
      }),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _yellowDarkColorScheme(),
  primaryColor: mainYellow,
  scaffoldBackgroundColor: const Color(0xFF1E1E1E),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: mainYellow,
    primaryContrastingColor: Colors.black,
    brightness: Brightness.dark,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: mainYellow,
    circularTrackColor: Color(0xFF333333),
    linearTrackColor: Color(0xFF333333),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: _yellowSwitchThumb(),
    trackColor: _yellowSwitchTrack(),
  ),

  dividerTheme: const DividerThemeData(color: Color(0xFF333333), thickness: 1),

  tabBarTheme: TabBarThemeData(
    dividerColor: const Color(0xFF333333),
    labelColor: yellowLight1,
    unselectedLabelColor: brownLight2,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: mainYellow, width: 2),
    ),
    indicatorColor: mainYellow,
  ),

  textSelectionTheme: TextSelectionThemeData(
    cursorColor: mainYellow,
    selectionColor: mainYellow.withValues(alpha: 0.35),
    selectionHandleColor: mainYellow,
  ),

  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    scrolledUnderElevation: 0,
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.black),
    ),
  ),

  cardTheme: CardThemeData(
    color: const Color(0xFF232323),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF232323),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: mainYellow,
    foregroundColor: Colors.black,
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: yellowLight1,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: yellowLight1,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(
      color: brownLight2,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  ),

  iconTheme: const IconThemeData(color: Colors.black),

  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    ),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    textColor: Colors.black,
  ),

  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    contentTextStyle: TextStyle(color: Colors.black, fontSize: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: mainYellow, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    labelStyle: TextStyle(color: Colors.black),
    floatingLabelStyle: TextStyle(color: mainYellow),
    hintStyle: TextStyle(color: Colors.black54),
    focusColor: mainYellow,
  ),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        }
        return Colors.black87;
      }),
    ),
  ),
);
