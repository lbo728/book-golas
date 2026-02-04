# App Store Connect IAP 상품 등록 가이드

## 📋 개요

이 가이드는 Bookgolas 앱의 인앱 구매(IAP) 상품을 App Store Connect에 등록하는 방법을 설명합니다.

**필요 권한**: App Manager 또는 Admin (Account Holder)

---

## 🎯 등록할 상품

| Product ID | 타입 | 가격 | 설명 |
|------------|------|------|------|
| `monthly` | Auto-Renewable Subscription | ₩3,900/월 | 월간 구독 |
| `yearly` | Auto-Renewable Subscription | ₩29,900/년 | 연간 구독 (17% 할인) |
| `lifetime` | Non-Consumable | TBD | 평생 이용권 |

**Entitlement**: "byungsker's lab Pro"

---

## 📝 Step 1: App Store Connect 로그인

1. https://appstoreconnect.apple.com 접속
2. Apple ID로 로그인
3. **나의 앱** 선택
4. **Bookgolas** 앱 선택

---

## 📝 Step 2: 구독 그룹 생성

### 2.1 구독 그룹 추가

1. 좌측 메뉴에서 **구독** 클릭
2. **구독 그룹 추가** 버튼 클릭
3. 구독 그룹 정보 입력:
   - **참조 이름**: `Bookgolas Pro Subscription`
   - **App Store 표시 이름** (한국어):
     - 제목: `Bookgolas Pro`
     - 설명: `무제한 독서 관리 및 AI 기능 이용`

### 2.2 구독 그룹 저장

- **저장** 버튼 클릭

---

## 📝 Step 3: 월간 구독 상품 등록

### 3.1 구독 추가

1. 방금 생성한 구독 그룹 선택
2. **구독 추가** 버튼 클릭

### 3.2 기본 정보

- **참조 이름**: `Bookgolas Pro Monthly`
- **제품 ID**: `monthly` (정확히 입력!)
- **구독 기간**: `1개월`

### 3.3 구독 가격

1. **구독 가격** 섹션에서 **가격 추가** 클릭
2. 가격 설정:
   - **국가/지역**: 대한민국
   - **가격**: ₩3,900
3. **다음** 클릭

### 3.4 App Store 정보 (한국어)

- **표시 이름**: `월간 구독`
- **설명**: `Bookgolas Pro 기능을 한 달 동안 이용할 수 있습니다.`

### 3.5 검토 정보

- **스크린샷**: (선택사항) Paywall 스크린샷 업로드
- **검토 노트**: `월간 구독 상품입니다. RevenueCat를 통해 관리됩니다.`

### 3.6 저장

- **저장** 버튼 클릭

---

## 📝 Step 4: 연간 구독 상품 등록

### 4.1 구독 추가

1. 동일한 구독 그룹에서 **구독 추가** 클릭

### 4.2 기본 정보

- **참조 이름**: `Bookgolas Pro Yearly`
- **제품 ID**: `yearly` (정확히 입력!)
- **구독 기간**: `1년`

### 4.3 구독 가격

1. **구독 가격** 섹션에서 **가격 추가** 클릭
2. 가격 설정:
   - **국가/지역**: 대한민국
   - **가격**: ₩29,900
3. **다음** 클릭

### 4.4 App Store 정보 (한국어)

- **표시 이름**: `연간 구독`
- **설명**: `Bookgolas Pro 기능을 1년 동안 이용할 수 있습니다. 월간 대비 17% 할인!`

### 4.5 검토 정보

- **스크린샷**: (선택사항) Paywall 스크린샷 업로드
- **검토 노트**: `연간 구독 상품입니다. RevenueCat를 통해 관리됩니다.`

### 4.6 저장

- **저장** 버튼 클릭

---

## 📝 Step 5: 평생 이용권 상품 등록 (Optional)

### 5.1 인앱 구매 추가

1. 좌측 메뉴에서 **인앱 구매** 클릭
2. **인앱 구매 추가** 버튼 클릭
3. 타입 선택: **비소모성** (Non-Consumable)

### 5.2 기본 정보

- **참조 이름**: `Bookgolas Pro Lifetime`
- **제품 ID**: `lifetime` (정확히 입력!)

### 5.3 가격

1. **가격 추가** 클릭
2. 가격 설정:
   - **국가/지역**: 대한민국
   - **가격**: TBD (예: ₩99,000)
3. **다음** 클릭

### 5.4 App Store 정보 (한국어)

- **표시 이름**: `평생 이용권`
- **설명**: `Bookgolas Pro 기능을 평생 이용할 수 있습니다. 단 한 번의 결제로 영구 사용!`

### 5.5 검토 정보

- **스크린샷**: (선택사항) Paywall 스크린샷 업로드
- **검토 노트**: `평생 이용권 상품입니다. RevenueCat를 통해 관리됩니다.`

### 5.6 저장

- **저장** 버튼 클릭

---

## 📝 Step 6: Sandbox 테스터 계정 생성

### 6.1 Sandbox 테스터 추가

1. App Store Connect 홈에서 **사용자 및 액세스** 클릭
2. 좌측 메뉴에서 **Sandbox 테스터** 클릭
3. **테스터 추가** 버튼 클릭

### 6.2 테스터 정보 입력

- **이름**: `Bookgolas Tester`
- **성**: `1`
- **이메일**: 새로운 Apple ID (예: `bookgolas.test1@icloud.com`)
- **비밀번호**: 안전한 비밀번호 생성
- **국가/지역**: 대한민국

### 6.3 저장

- **초대** 버튼 클릭

---

## 📝 Step 7: RevenueCat 대시보드 연동

### 7.1 RevenueCat 로그인

1. https://app.revenuecat.com 접속
2. Bookgolas 프로젝트 선택

### 7.2 Products 설정

1. 좌측 메뉴에서 **Products** 클릭
2. **Add Product** 버튼 클릭
3. 각 상품 추가:
   - **Product ID**: `monthly` (App Store Connect와 동일!)
   - **Type**: Subscription
   - **Duration**: 1 month
   - **Store**: App Store
4. `yearly`, `lifetime`도 동일하게 추가

### 7.3 Entitlement 생성

1. 좌측 메뉴에서 **Entitlements** 클릭
2. **Add Entitlement** 버튼 클릭
3. Entitlement 정보:
   - **Identifier**: `byungsker's lab Pro` (정확히 입력!)
   - **Products**: `monthly`, `yearly`, `lifetime` 모두 선택

### 7.4 Offerings 설정

1. 좌측 메뉴에서 **Offerings** 클릭
2. **Default Offering** 선택
3. **Add Package** 버튼 클릭
4. 패키지 추가:
   - **Monthly Package**: Product `monthly` 선택
   - **Annual Package**: Product `yearly` 선택
   - **Lifetime Package**: Product `lifetime` 선택

---

## ✅ 검증 체크리스트

### App Store Connect
- [ ] 구독 그룹 생성됨: `Bookgolas Pro Subscription`
- [ ] 월간 구독 등록됨: Product ID `monthly`, ₩3,900
- [ ] 연간 구독 등록됨: Product ID `yearly`, ₩29,900
- [ ] 평생 이용권 등록됨 (Optional): Product ID `lifetime`
- [ ] Sandbox 테스터 계정 생성됨
- [ ] 모든 상품 상태: **제출 준비 완료** 또는 **승인됨**

### RevenueCat
- [ ] Products 등록됨: `monthly`, `yearly`, `lifetime`
- [ ] Entitlement 생성됨: `byungsker's lab Pro`
- [ ] Offerings 설정됨: Default Offering에 3개 패키지 추가
- [ ] App Store Connect 연동 확인: API Key 설정됨

---

## 🚨 주의사항

### Product ID 정확성
- **CRITICAL**: Product ID는 코드와 정확히 일치해야 합니다.
- 오타 시 IAP가 작동하지 않습니다.
- 확인: `monthly`, `yearly`, `lifetime` (모두 소문자)

### Entitlement ID 정확성
- **CRITICAL**: Entitlement ID는 `"byungsker's lab Pro"` (따옴표 포함 X, 공백 포함 O)
- 코드에서 사용하는 ID와 정확히 일치해야 합니다.

### 가격 정책
- 월간: ₩3,900
- 연간: ₩29,900 (월간 대비 17% 할인)
- 평생: TBD (추후 결정)

### Sandbox 테스트
- Sandbox 테스터 계정으로만 테스트 가능
- 실제 결제는 발생하지 않음
- 테스트 후 구독 취소 필요 (자동 갱신 방지)

---

## 📞 문제 해결

### "제품 ID가 이미 사용 중입니다"
- 다른 앱에서 동일한 Product ID를 사용 중일 수 있습니다.
- 해결: Product ID 앞에 앱 번들 ID 추가 (예: `com.bookgolas.app.monthly`)

### "구독 그룹을 찾을 수 없습니다"
- 구독 그룹이 저장되지 않았을 수 있습니다.
- 해결: Step 2부터 다시 진행

### RevenueCat에서 상품이 보이지 않음
- App Store Connect와 RevenueCat의 Product ID가 일치하지 않을 수 있습니다.
- 해결: Product ID 철자 확인 (대소문자 구분)

---

## 📚 참고 자료

- [App Store Connect 도움말 - 인앱 구매](https://help.apple.com/app-store-connect/#/devae49fb316)
- [RevenueCat 문서 - iOS 설정](https://www.revenuecat.com/docs/getting-started/installation/ios)
- [RevenueCat 문서 - Products 설정](https://www.revenuecat.com/docs/entitlements)

---

**작성일**: 2026-01-28  
**작성자**: Atlas (Orchestrator Agent)  
**버전**: 1.0
