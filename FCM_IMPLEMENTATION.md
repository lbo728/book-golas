# FCM Push Notification 구현 계획

> **목표**: 매일 정해진 시간에 "오늘의 목표 페이지 수를 설정해주세요!" 알림 전송
> **기술 스택**: Firebase Cloud Messaging + flutter_local_notifications
> **작성일**: 2025-12-07

---

## 📋 개요

### 요구사항
- 매일 사용자가 설정한 시간에 알림 발송
- "오늘의 목표 페이지 수를 설정해주세요!" 메시지
- 알림 탭 시 앱 열기 및 해당 화면 이동
- 향후 확장: 관리자 공지, 친구 알림 등

### 왜 FCM인가?
- ✅ 로컬 알림 + 원격 푸시 모두 지원
- ✅ 향후 서버 트리거 알림 확장 가능
- ✅ Firebase 에코시스템과 통합
- ✅ iOS/Android 모두 지원

---

## 🏗️ 아키텍처

```
[사용자 기기]
    ↓
[로컬 스케줄링] ← SharedPreferences (알림 시간 저장)
    ↓
[flutter_local_notifications] → 정해진 시간에 알림 표시

[Firebase Admin SDK] (향후)
    ↓
[FCM Server]
    ↓
[사용자 기기] → 원격 푸시 수신
```

---

## 📦 Phase 1: Firebase 프로젝트 설정

### 1-1. Firebase 프로젝트 생성
```bash
# Firebase Console에서 프로젝트 생성
# https://console.firebase.google.com/
```

### 1-2. FlutterFire CLI 설정
```bash
# Firebase CLI 설치 (최초 1회)
npm install -g firebase-tools

# FlutterFire CLI 설치 (최초 1회)
dart pub global activate flutterfire_cli

# Firebase 로그인
firebase login

# Flutter 프로젝트에 Firebase 자동 설정
cd app
flutterfire configure
```

**자동 생성되는 파일들:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 1-3. 패키지 설치
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2
  shared_preferences: ^2.3.3  # 이미 설치됨
```

```bash
flutter pub get
```

---

## ⚙️ Phase 2: 네이티브 설정

### 2-1. Android 설정

#### `android/app/build.gradle`
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // FCM 최소 요구사항
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.5.1')
}
```

#### `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

    <application>
        <!-- FCM 기본 채널 -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />

        <!-- 로컬 알림 리시버 -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
    </application>
</manifest>
```

### 2-2. iOS 설정

#### `ios/Runner/AppDelegate.swift`
```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // 알림 권한 요청
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Xcode Capabilities
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Runner → Signing & Capabilities
3. `+ Capability` → **Push Notifications** 추가
4. `+ Capability` → **Background Modes** → **Remote notifications** 체크

---

## 💻 Phase 3: FCMService 구현

### 파일 구조
```
lib/
├── data/
│   └── services/
│       └── fcm_service.dart  (새로 생성)
└── main.dart  (수정)
```

### `lib/data/services/fcm_service.dart`
핵심 기능:
- Firebase Messaging 초기화
- FCM 토큰 관리
- Foreground/Background 메시지 처리
- 로컬 알림 스케줄링 (매일 반복)
- 알림 탭 처리 (네비게이션)

**주요 메서드:**
```dart
class FCMService {
  static Future<void> initialize();
  static Future<void> scheduleDailyNotification({hour, minute, title, body});
  static Future<void> cancelAllNotifications();
  static Future<void> saveTokenToDatabase(String token);
  static void onTokenRefresh(Function(String) callback);
}
```

---

## 🗄️ Phase 4: Supabase 데이터베이스

### `fcm_tokens` 테이블 생성

```sql
CREATE TABLE fcm_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_type TEXT, -- 'ios' or 'android'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS 정책
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own tokens" ON fcm_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own tokens" ON fcm_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON fcm_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens" ON fcm_tokens
  FOR DELETE USING (auth.uid() = user_id);
```

---

## 🎨 Phase 5: 알림 설정 UI

### `lib/ui/auth/widgets/my_page_screen.dart` 수정

추가할 섹션:
```
[알림 설정]
├─ [스위치] 알림 받기
│   └─ "매일 정해진 시간에 알림을 받습니다"
└─ [시간 선택] 알림 시간
    └─ "09:00" (TimePicker)
```

**SharedPreferences 저장 항목:**
- `notifications_enabled`: bool
- `notification_hour`: int
- `notification_minute`: int

---

## 🔄 Phase 6: main.dart 통합

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. FCM 초기화
  await FCMService.initialize();

  // 3. 기존 초기화
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(...);

  runApp(const MyApp());
}
```

---

## 📱 Phase 7: 알림 플로우

### 로컬 알림 (매일 반복)
```
사용자가 알림 시간 설정 (예: 09:00)
    ↓
SharedPreferences 저장
    ↓
FCMService.scheduleDailyNotification()
    ↓
flutter_local_notifications가 매일 09:00에 알림 표시
    ↓
사용자가 알림 탭
    ↓
앱 열기 → BookListScreen으로 이동
```

### 원격 푸시 (향후 구현)
```
Firebase Admin SDK (서버)
    ↓
FCM Server
    ↓
사용자 기기 (FCM 토큰으로 타겟팅)
    ↓
Foreground: 로컬 알림으로 표시
Background/Terminated: 시스템 알림 표시
```

---

## ✅ 테스트 체크리스트

### 로컬 알림 테스트
- [ ] 알림 권한 요청 정상 작동
- [ ] 알림 시간 설정 후 저장 확인
- [ ] 설정한 시간에 알림 수신 확인
- [ ] 알림 탭 시 앱 열림 확인
- [ ] 알림 OFF 시 알림 취소 확인

### FCM 테스트 (향후)
- [ ] FCM 토큰 생성 확인
- [ ] 토큰 Supabase 저장 확인
- [ ] Foreground 메시지 수신 확인
- [ ] Background 메시지 수신 확인
- [ ] Terminated 상태 메시지 수신 확인

### 플랫폼별 테스트
- [ ] Android 물리 기기 테스트
- [ ] iOS 물리 기기 테스트
- [ ] 앱 재시작 후 알림 유지 확인

---

## 🚀 향후 확장 계획

### Phase 8: 서버 트리거 푸시 (선택)
- Supabase Edge Function 또는 별도 백엔드
- Firebase Admin SDK로 푸시 발송
- 사용 사례:
  - 관리자 공지
  - 친구 초대/추천
  - 목표 달성 축하 메시지

### Phase 9: 고급 기능
- 알림 카테고리별 설정
- 조용한 시간(DND) 설정
- 푸시 알림 통계 (오픈율 등)

---

## 📚 참고 자료

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Console](https://console.firebase.google.com/)

---

## 🔧 트러블슈팅

### iOS에서 알림이 안 올 때
1. Xcode Capabilities 확인
2. 물리 기기에서 테스트 (시뮬레이터는 푸시 제한)
3. `ios/Podfile` 확인

### Android에서 알림이 안 올 때
1. `google-services.json` 위치 확인
2. minSdkVersion 21 이상 확인
3. 앱 알림 권한 설정 확인

### 백그라운드 알림이 작동 안 할 때
- Android: 배터리 최적화 예외 추가
- iOS: Background Modes 활성화 확인
