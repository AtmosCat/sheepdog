<img src="https://github.com/user-attachments/assets/82abbb59-c857-426a-88a0-dc427891dca2" alt="icon10" width="400"/>

# 📱 구독 관리를 쉽게, **쉽독**

> 정기 결제를 한눈에 관리할 수 있는 구독 관리 앱  
> Flutter 기반 | Android / iOS 지원

> **쉽독은 단순한 구독 관리 앱이 아닙니다.**  
> 사용자의 소비 패턴을 정돈하고, 구독의 효율성을 높이며, 개인화된 추천과 분석을 통해 ‘합리적인 구독 소비 생활’을 설계하는 서비스입니다.  
> 현재는 광고 및 프리미엄 멤버십 기반으로 수익을 창출하고 있으며, 향후 구독 분석 리포트 및 추천 기반 광고 시스템으로의 확장을 계획하고 있습니다.

---

## ✨ 소개

**쉽독**은 구독 서비스, 월세, 보험료, 통신비 등 다양한 정기 결제 항목을 한 곳에서 관리할 수 있도록 돕는 앱입니다.  
점점 복잡해지는 구독 생활 속에서, 사용자가 놓치지 않고 결제 일정을 확인하고 정리할 수 있도록 설계했습니다.

---

## 🎯 개발 배경

최근 사용자들은 OTT, 음악, 클라우드, 생산성 툴 등 다양한 서비스를 구독하고 있습니다.  
그러나 구독 항목이 늘어날수록, 어떤 서비스에 얼마나 지출하고 있는지 파악하기 어려워졌습니다.  
또한, 보험료·월세·통신비와 같이 매달 고정적으로 발생하는 지출 역시 통합 관리가 필요해졌습니다.  
**쉽독**은 이러한 사용자의 니즈를 반영하여, **정기 결제 전체를 직관적으로 관리할 수 있는 솔루션**을 제공하고자 개발되었습니다.

---

## ⚙️ 주요 기능

- **정기 결제 등록 및 관리**  
  내가 구독 중인 항목의 이름, 결제일, 금액, 결제 수단 등 기록 가능

- **카테고리별 분류 기능**  
  구독 서비스를 `콘텐츠`, `금융`, `생활비` 등으로 구분해 시각적으로 보기 좋게 정리

- **알림 기능**  
  결제 예정일 전/당일에 알림 전송으로 미납 방지

- **구독 달력 제공**  
  월간 뷰에서 결제 예정일, 완료된 결제, 임박 알림 등을 한눈에 파악

- **결제 수단 관리**  
  서비스별 결제 수단 연결로 신용카드/계좌 기반의 지출 흐름까지 관리

---

## 🎨 UI/UX 디자인
<img width="600" alt="image" src="https://github.com/user-attachments/assets/2ac64676-ac98-4f07-b005-e7f2594752fb" />

---

## 🛠 기술 스택 및 구조

> Flutter 기반으로 설계되었으며, 사용자 편의성과 유지보수를 고려한 구조로 구성되어 있습니다.

## 🧩 기술 스택

| 분류            | 이름                                                                 |
|-----------------|----------------------------------------------------------------------|
| Architecture    | MVVM (`ViewModel - Repository - DAO`) 구조 구현                      |
| 상태 관리       | `MultiProvider`, `ChangeNotifier` 기반 상태관리                      |
| 비동기 처리     | `Future`, `async/await`, `Firebase Functions`                         |
| 메시지 전송     | `Firebase Cloud Messaging (FCM)`을 통한 푸시 알림                     |
| 데이터 처리     | `Provider` 기반 상태 연동 / JSON 파싱 / 날짜 연산                     |
| 데이터 저장     | `SharedPreferences`, `Firebase Firestore`, `LocalStorage`             |
| 알림            | `flutter_local_notifications`, `firebase_messaging` 통한 결제일 알림 |
| API 통신        | `Firebase Functions` (서버리스 API 호출 포함)                  |
| 활용 API        | Google AdMob, Firebase Auth, Firebase Firestore, Firebase Functions   |
| UI Frameworks   | Flutter, Material Design 위젯, 커스텀 테마(다크모드/라이트모드 지원)   |

---

## 🖼 스크린샷

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/fe8c1fad-458a-4135-b444-eca255a4be0b" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/bf9f783b-6d70-4041-b123-5a508c72cead" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/157cafe8-6035-4902-a88f-ced0d34e78b9" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/9df87480-9835-4339-93f0-aefa62b05b4f" width="200"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/fc1498b7-883b-4c59-ad40-731f34905ed0" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/3c70780e-0fe1-42d0-b12e-49b48f727c6c" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/12906474-6e0d-448e-b74b-025e0259127e" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/2aa92f75-00e9-4694-93f7-3c936740c587" width="200"/></td>
  </tr>
</table>

---

## 💰 비즈니스 모델

- **현재 수익 구조**
  - 📢 **광고 수익화**  
    Google AdMob을 기반으로 사용자 맞춤형 광고를 앱 내 자연스럽게 배치하여 수익을 창출하고 있습니다. (배너 광고, 전면 광고, 앱 오프닝 광고, 네이티브 광고 등)
  - 💎 **프리미엄 멤버십 운영**  
    - 광고 제거 기능
    - 구독 서비스 등록 가능 개수 확장
    - 구독 서비스 이모지 선택 옵션 확장 (300종 이상 제공)

- **향후 계획**
  - 🧠 **구독 서비스 추천 기반 광고 연동**  
    사용자의 구독 유형 및 패턴을 분석하여 맞춤형 서비스 추천과 광고를 연동하는 구조로 고도화 예정
  - 📊 **프리미엄 혜택 확장**  
    - 고급 분석 리포트 제공 (구독 과다/비효율 진단 등)
    - 홈 화면 위젯 기능 등 유용한 프리미엄 기능 지속 추가 예정
   
---

## 🔮 향후 계획

- 🔧 **알림 설정 고도화**  
  `Firebase Functions`의 기능을 세분화하여, 결제일 알림을 시간대·반복 조건 등 사용자 맞춤형으로 정교하게 설정 가능하도록 개선할 예정입니다.

- 📊 **정기결제 분석 리포트 제공**  
  사용자의 구독 내역 데이터를 바탕으로,  
  - 구독 서비스 유형  
  - 결제 패턴  
  - 실사용 시간  
  등을 분석하여 **과소 이용 서비스에 대한 해지 제안**, **사용자 맞춤형 신규 서비스 추천** 등 인사이트 기반 리포트를 제공할 예정입니다.

## 📲 다운로드

- [![App Store](https://img.shields.io/badge/App%20Store-%230078D6?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/kr/app/%EA%B5%AC%EB%8F%85-%EA%B4%80%EB%A6%AC%EB%A5%BC-%EC%89%BD%EA%B2%8C-%EC%89%BD%EB%8F%85/id6747409683)

---

## 📌 문의 / 피드백

이슈나 개선 요청은 GitHub Issues를 통해 전달해주세요.  
버그 제보, 기능 제안, 디자인 피드백 모두 환영합니다.

---

## 📝 라이선스

본 프로젝트는 MIT License 하에 공개되어 있습니다.
