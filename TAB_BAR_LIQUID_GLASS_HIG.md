# 📱 iOS Bottom Navigation (Tab Bar / Floating Liquid Glass) — Apple HIG 인용 스펙

> 아래 스펙은 Apple 공식 Human Interface Guidelines 문서와  
> Apple이 제시한 “Liquid Glass” 디자인 시스템을 기반으로 작성되었으며,  
> 모든 인용은 해당 출처 링크를 포함하고 있다.

---

## 🧭 1. Tab Bar 기본 정의

> **A tab bar appears at the bottom of an app screen and provides the ability to quickly switch between different sections of an app.**  
> — _Apple Human Interface Guidelines: Tab Bars_ :contentReference[oaicite:0]{index=0}

### 🔗 출처

https://developer.apple.com/design/human-interface-guidelines/tab-bars :contentReference[oaicite:1]{index=1}

---

## 🎨 2. 반투명 & 재질(Material)

### Apple이 정의하는 새로운 디자인 시스템: **Liquid Glass**

> **“Interfaces across Apple platforms feature a new dynamic material called Liquid Glass, which combines the optical properties of glass with a sense of fluidity.”**  
> — _Apple Developer Documentation: Adopting Liquid Glass_ :contentReference[oaicite:2]{index=2}

Liquid Glass의 핵심 특징:

- 반투명 유리 같은 시각 효과
- 콘텐츠 위에 떠 있는 느낌
- 빛 반사·굴절 같은 미묘한 효과

### 🔗 출처

https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass :contentReference[oaicite:3]{index=3}

---

## 📍 3. 위치 & 레이어

Apple HIG가 정의하는 Tab Bar 동작:

> **Tab bars provide persistent, top-level navigation within your app. With the new design, the tab bar on iPhone floats above the content, and can be configured to minimize on scroll, keeping the focus on your content.**  
> — _WWDC25 Documentation (Apple Developer)_ :contentReference[oaicite:4]{index=4}

즉:

- Tab Bar는 **콘텐츠 위에 떠 있음**
- 스크롤 시 자동으로 축소/숨김 가능

### 🔗 출처

https://developer.apple.com/videos/play/wwdc2025/284/ :contentReference[oaicite:5]{index=5}

---

## 🔳 4. 동작 행태 (Tab Bar Role)

Apple은 아래처럼 명시함:

> **Use a tab bar strictly for navigation. Tab bar buttons should not be used to perform actions.**  
> — _Human Interface Guidelines: Tab Bars_ :contentReference[oaicite:6]{index=6}

즉, Tab Bar는 **네비게이션 전용**이며,  
버튼은 **다른 기능 수행 장소로 이동**시키는 데 쓰여야 함.

---

## 🎯 5. 구성 요소 — 기본 규칙

### 아이콘 개수와 역할

Apple:

> **Include essential tabs only, and use the minimum tabs necessary for your information hierarchy.**  
> — _Human Interface Guidelines: Tab Bars_ :contentReference[oaicite:7]{index=7}

정리하면:

- 3~5개의 탭 권장
- 너무 많으면 UX 저하

### 투명성 & 반투명 효과

Tab Bar는 **translucent (반투명)** 해야하며,  
배경 콘텐츠를 섞어서 보여줌. :contentReference[oaicite:8]{index=8}

---

## 🚀 6. Apple HIG가 알려주는 숨김 처리

Tab Bar는:

> **Hidden when a keyboard is displayed. A tab bar may be hidden when a keyboard is onscreen.**  
> — _Human Interface Guidelines: Tab Bars_ :contentReference[oaicite:9]{index=9}

즉 자연스러운 행동:

- 키보드 올라왔을 때 **숨김**
- 스크롤 → **축소 또는 숨김 가능**

---

## 🧠 7. Tab Bar + 액세서리 (iOS 26)

WWDC Apple 공식 설명:

> **Above the tab bar, you can have an accessory view like the mini player in the Music app. … When the tab bar is minimized, the accessory view animates down to display inline with the tab bar.**  
> — _WWDC25 Docs_ :contentReference[oaicite:10]{index=10}

→ 즉 Apple도 Tab Bar 위에 별도 뷰를 “층(layer)”로 두는 것을 지원함.

---

## 📏 8. 디자인 인사이트: Liquid Glass의 철학

Apple 공식 Liquid Glass 철학에서:

> **Liquid Glass encourages a more layer approach to designing your app, so having content that expands underneath the tab bar using a bit of a blurry overlay.**  
> — _Exploring tab bars on iOS 26 with Liquid Glass_ :contentReference[oaicite:11]{index=11}

핵심 포인트:

- 콘텐츠가 Tab Bar **아래로 스크롤되도록**
- Tab Bar는 **Glass material로 콘텐츠와 시각적으로 구분**

### 🔗 출처

https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/ :contentReference[oaicite:12]{index=12}

---

## 🧠 9. 요약 — Apple HIG 핵심 가이드라인 인용

| 항목               | Apple HIG 인용 문구                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------------------- |
| **역할**           | “Provide the ability to quickly switch between different sections.” :contentReference[oaicite:13]{index=13} |
| **투명성**         | “Tab bars are translucent.” :contentReference[oaicite:14]{index=14}                                         |
| **Tab Bar 행동**   | “Floating above content, minimize on scroll.” :contentReference[oaicite:15]{index=15}                       |
| **Keyboard**       | “Hidden when keyboard is onscreen.” :contentReference[oaicite:16]{index=16}                                 |
| **Accessory view** | “Can have accessory view above Tab Bar.” :contentReference[oaicite:17]{index=17}                            |

---

## 🔗 공식 가이드라인 원문 링크

- Apple Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines :contentReference[oaicite:18]{index=18}
- Tab Bars — https://developer.apple.com/design/human-interface-guidelines/tab-bars :contentReference[oaicite:19]{index=19}
- Liquid Glass Overview — https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass :contentReference[oaicite:20]{index=20}
- WWDC25 Tab Bars & Liquid Glass — https://developer.apple.com/videos/play/wwdc2025/284/ :contentReference[oaicite:21]{index=21}
