<img src="https://github.com/user-attachments/assets/82abbb59-c857-426a-88a0-dc427891dca2" alt="icon10" width="400"/>

# 📱 구독 관리를 쉽게, **쉽독**

> 정기 결제를 한눈에 관리할 수 있는 구독 관리 앱  
> Flutter 기반 | Android / iOS 지원


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

## 🛠 기술 스택 및 구조

> Flutter 기반으로 설계되었으며, 사용자 편의성과 유지보수를 고려한 구조로 구성되어 있습니다.

- **Flutter + Dart** 기반 멀티플랫폼 개발
- **상태관리**: `MultiProvider`, `Notifier` 구조 적용
- **아키텍처**: `DAO - Repository - ViewModel` 패턴 도입으로 모듈화 및 의존성 최소화
- **Firebase 연동**
  - `Firebase Auth`: 익명 로그인으로 유저 데이터 구분
  - `Firebase Functions`: 자동 알림 푸시, 결제 일정 자동 삭제/갱신 로직 서버리스 구현
- **알림 시스템**: 로컬 알림 + 클라우드 푸시 알림 병행 구현
- **광고 수익화**
  - Google AdMob 기반
  - 배너 광고, 전면 광고, 앱 오프닝 광고, 네이티브 광고 등 다양한 형식으로 최적화

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

## 📲 다운로드

- [![App Store](https://img.shields.io/badge/App%20Store-%230078D6?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/kr/app/%EA%B5%AC%EB%8F%85-%EA%B4%80%EB%A6%AC%EB%A5%BC-%EC%89%BD%EA%B2%8C-%EC%89%BD%EB%8F%85/id6747409683)

---

## 📌 문의 / 피드백

이슈나 개선 요청은 GitHub Issues를 통해 전달해주세요.  
버그 제보, 기능 제안, 디자인 피드백 모두 환영합니다.

---

## 📝 라이선스

본 프로젝트는 MIT License 하에 공개되어 있습니다.
