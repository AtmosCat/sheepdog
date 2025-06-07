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

final ThemeData lightTheme = ThemeData(
  primaryColor: mainBrown,
  scaffoldBackgroundColor: Colors.white, // 쨍한 노랑 배경

  dividerTheme: DividerThemeData(
    color: brownLight3,
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
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    scrolledUnderElevation: 0,
  ),

  // 팝업메뉴
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black),
    labelTextStyle: WidgetStateProperty.all(const TextStyle(color: Colors.black)),
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

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: mainBrown,
    foregroundColor: Colors.white,
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

  iconTheme: const IconThemeData(
    color: Colors.black, // 모든 아이콘 기본 검정색
  ),

  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    ),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    textColor: Colors.black,
  ),

  // 다이얼로그 테마
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
    contentTextStyle: TextStyle(color: Colors.black, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),

  // 텍스트필드 하이라이트(포커스) 컬러
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryBlue, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(color: Colors.black),
    floatingLabelStyle: TextStyle(color: Colors.black),
    hintStyle: TextStyle(color: Colors.black54),
  ),

  // 텍스트 버튼, 확인/취소 버튼 테마
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey;
        }
        // 확인 버튼: 파란색, 취소 버튼: 회색(별도 구현 필요)
        return primaryBlue;
      }),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  primaryColor: brownLight1,
  scaffoldBackgroundColor: const Color(0xFF1E1E1E),

  dividerTheme: const DividerThemeData(
    color: Color(0xFF333333),
    thickness: 1,
  ),

  tabBarTheme: TabBarThemeData(
    dividerColor: const Color(0xFF333333),
    labelColor: yellowLight1,
    unselectedLabelColor: brownLight2,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: yellowLight1, width: 2),
    ),
  ),

  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    scrolledUnderElevation: 0,
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black),
    labelTextStyle: WidgetStateProperty.all(const TextStyle(color: Colors.black)),
  ),

  cardTheme: CardThemeData(
    color: const Color(0xFF232323),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 1,
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF232323),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: yellowLight1,
    foregroundColor: mainBrown,
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

  iconTheme: const IconThemeData(
    color: Colors.black,
  ),

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
    titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
    contentTextStyle: TextStyle(color: Colors.black, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryBlue, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(color: Colors.black),
    hintStyle: TextStyle(color: Colors.black54),
  ),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey;
        }
        return primaryBlue;
      }),
    ),
  ),
);
