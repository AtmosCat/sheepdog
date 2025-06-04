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

final ThemeData lightTheme = ThemeData(
  // 메인 테마 컬러
  primaryColor: mainBrown,
  scaffoldBackgroundColor: mainYellow, // 쨍한 노랑 배경

  // 디바이더 색상
  dividerTheme: DividerThemeData(
    color: brownLight3, // 밝은 갈색
    thickness: 1,
  ),

  tabBarTheme: TabBarThemeData(
    dividerColor: brownLight3,
    labelColor: mainBrown,
    unselectedLabelColor: brownLight1,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: mainBrown, width: 2),
    ),
  ),

  // 앱 바
  appBarTheme: AppBarTheme(
    titleTextStyle: TextStyle(color: mainBrown, fontSize: 18, fontWeight: FontWeight.bold),
    backgroundColor: yellowLight3, // 연한 노랑
    iconTheme: IconThemeData(color: mainBrown),
    scrolledUnderElevation: 0,
  ),

  // 팝업메뉴
  popupMenuTheme: PopupMenuThemeData(
    color: yellowLight3,
    textStyle: TextStyle(color: mainBrown),
    labelTextStyle: WidgetStateProperty.all(TextStyle(color: mainBrown)),
  ),

  // 카드
  cardTheme: CardThemeData(
    color: yellowLight2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
  ),

  // 바텀시트
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: yellowLight2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
  ),

  // 플로팅 액션 버튼
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: mainBrown, // 갈색
    foregroundColor: Colors.white, // 흰색 아이콘/글씨
  ),

  // 텍스트
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      color: mainBrown,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: mainBrown,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(
      color: brownLight1,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  ),

  // 아이콘
  iconTheme: IconThemeData(
    color: mainBrown,
  ),

  // 아이콘 버튼
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(mainBrown),
    ),
  ),

  // 리스트타일
  listTileTheme: ListTileThemeData(
    iconColor: mainBrown,
    textColor: mainBrown,
  ),
);

final ThemeData darkTheme = ThemeData(
  primaryColor: brownLight1, // 밝은 갈색
  scaffoldBackgroundColor: Color(0xFF1E1E1E), // 다크 배경

  dividerTheme: DividerThemeData(
    color: Color(0xFF333333),
    thickness: 1,
  ),

  tabBarTheme: TabBarThemeData(
    dividerColor: Color(0xFF333333),
    labelColor: yellowLight1,
    unselectedLabelColor: brownLight2,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: yellowLight1, width: 2),
    ),
  ),

  appBarTheme: AppBarTheme(
    titleTextStyle: TextStyle(color: yellowLight1, fontSize: 18, fontWeight: FontWeight.bold),
    backgroundColor: Color(0xFF232323),
    iconTheme: IconThemeData(color: yellowLight1),
    scrolledUnderElevation: 0,
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: Color(0xFF232323),
    textStyle: TextStyle(color: yellowLight1),
    labelTextStyle: WidgetStateProperty.all(TextStyle(color: yellowLight1)),
  ),

  cardTheme: CardThemeData(
    color: Color(0xFF232323),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: Color(0xFF232323),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: yellowLight1, // 밝은 노랑
    foregroundColor: mainBrown, // 갈색 아이콘/글씨
  ),

  textTheme: TextTheme(
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

  iconTheme: IconThemeData(
    color: yellowLight1,
  ),

  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(yellowLight1),
    ),
  ),

  listTileTheme: ListTileThemeData(
    iconColor: yellowLight1,
    textColor: yellowLight1,
  ),
);
