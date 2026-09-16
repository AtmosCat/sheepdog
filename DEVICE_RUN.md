# 실기기 실행 / 재실행 치트시트

프로젝트 루트에서 실행.

```bash
cd /Users/hojeong/Desktop/HOJEONG_JEONG/dev/app_in_toss/sheepdog
```

---

## 실기기 연결 후 실행

USB로 기기 연결 → 개발자 모드/신뢰 허용 후:

```bash
flutter devices
flutter run -d R3CWC0GYBTR


## iOS 실기기 실행

```bash
flutter run -d 00008020-000518CE2603002E

최초/서명 이슈 시 Xcode에서 Signing & Capabilities 확인 후 다시 실행.

---

## 4. 수정사항 반영해서 재실행 (앱이 이미 떠 있는 상태)

`flutter run`이 돌아가는 터미널에서:

| 키 | 동작 |
|----|------|
| `r` | Hot Reload — UI/로직 변경 빠르게 반영 |
| `R` | Hot Restart — 앱 상태 초기화 후 재시작 |

저장만으로 반영되게 하려면:

```bash
flutter run --hot
```

(`--hot`은 기본값이라 보통 `r` / `R`만 쓰면 됨)

---

## 5. 강하게 재실행

앱을 완전히 끄고 다시 빌드·설치:

```bash
# 실행 중이면 q 로 종료 후
flutter run -d <device-id>
```

캐시/빌드까지 지우고 강하게:

```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

iOS만 더 강하게 (Pods 재설치):

```bash
flutter clean
cd ios && pod install --repo-update && cd ..
flutter pub get
flutter run -d <ios-device-id>
```

---

## 6. Xcode 열기

```bash
open ios/Runner.xcworkspace
```

`.xcodeproj`가 아니라 **`.xcworkspace`** 를 연다. (CocoaPods)

---

## 7. 출시 전 필수 — 기존 기록 보존

앱을 업데이트해도 구독 기록이 절대 지워지면 안 된다. AAB/스토어 업로드 전에:

```bash
./tool/pre_release_check.sh
```

