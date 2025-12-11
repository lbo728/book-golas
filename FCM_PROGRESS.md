# FCM 푸시 알림 구현 진행 상황

## 작업 브랜치
`feature/fcm-push-notifications`

## 완료된 작업 (6/14)

### ✅ 1. FCM 구현 계획 문서 작성
- **파일**: `FCM_IMPLEMENTATION.md`
- **커밋**: `docs: FCM 푸시 알림 구현 계획 문서 작성`
- **내용**: 전체 구현 계획, Firebase 설정, 네이티브 설정, FCMService 아키텍처, 테스트 체크리스트

### ✅ 2. feature/fcm-push-notifications 브랜치 생성
- **브랜치**: `feature/fcm-push-notifications`
- **상태**: 현재 작업 중인 브랜치

### ✅ 3. 앱 패키지 이름 litgoal → bookgolas 변경
- **커밋**: `refactor: 앱 패키지 이름을 litgoal에서 bookgolas로 변경`
- **변경 파일**:
  - `pubspec.yaml`: `lit_goal` → `book_golas`
  - `android/app/build.gradle`: `com.litgoal.app` → `com.bookgolas.app`
  - `android/app/src/main/kotlin/com/bookgolas/app/MainActivity.kt`: 패키지 경로 변경 및 이동
  - `ios/Runner/Info.plist`: Bundle ID 및 URL scheme 변경
  - `ios/Runner.xcodeproj/project.pbxproj`: Bundle identifier 변경

### ✅ 4. Firebase 프로젝트 book-golas 재설정
- **Firebase 프로젝트**: `book-golas`
- **생성된 파일**:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- **도구**: `flutterfire configure`

### ✅ 5. FCM 관련 패키지 설치
- **커밋**: `feat: FCM 푸시 알림 패키지 추가`
- **추가된 패키지**:
  ```yaml
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2
  ```

### ✅ 6. iOS 네이티브 설정
- **커밋**: `feat: iOS Firebase 및 푸시 알림 네이티브 설정`
- **파일**: `ios/Runner/AppDelegate.swift`
- **변경 내용**:
  - Firebase 초기화 (`FirebaseApp.configure()`)
  - 알림 권한 요청 (`UNUserNotificationCenter`)
  - Remote notification 등록 (`registerForRemoteNotifications()`)

#### ⚠️ 수동 설정 필요:
사용자가 Xcode에서 수동으로 설정해야 함:
1. Xcode 열기: `ios/Runner.xcworkspace`
2. Runner 타겟 선택 → Signing & Capabilities
3. **Push Notifications** capability 추가
4. **Background Modes** capability 추가 → **Remote notifications** 체크

---

## 대기 중인 작업 (8/14)

### 🔄 7. Android 네이티브 설정 (보류)
사용자 요청으로 나중 작업으로 미뤄짐. 필요 시 다음 작업 수행:
- `android/app/src/main/AndroidManifest.xml` 수정
- Firebase Messaging 서비스 등록
- 알림 권한 추가

### ⏭️ 8. FCMService 클래스 구현
**위치**: `lib/data/services/fcm_service.dart` (새 파일 생성)

**구현 내용**:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // 초기화
  Future<void> initialize() async {
    // 타임존 데이터 초기화
    tz.initializeTimeZones();

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // FCM 권한 요청
    await _requestPermission();

    // FCM 토큰 가져오기
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // 토큰 갱신 리스너
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      // TODO: 서버에 새 토큰 저장
    });

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 메시지 처리는 main.dart에서 설정
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  // FCM 권한 요청
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // 로컬 알림으로 표시
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
      );
    }
  }

  // 알림 탭 처리
  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: 화면 이동 로직 구현
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reading Reminder',
      channelDescription: '매일 독서 목표 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // 매일 정해진 시간에 알림 스케줄링
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    await _localNotifications.zonedSchedule(
      0, // notification id
      '오늘의 독서 목표',
      '오늘의 목표 페이지 수를 설정해주세요!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reading Reminder',
          channelDescription: '매일 독서 목표 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // SharedPreferences에 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', hour);
    await prefs.setInt('notification_minute', minute);
    await prefs.setBool('notification_enabled', true);
  }

  // 다음 알림 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // 알림 취소
  Future<void> cancelDailyNotification() async {
    await _localNotifications.cancel(0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', false);
  }

  // 알림 설정 상태 가져오기
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notification_enabled') ?? false,
      'hour': prefs.getInt('notification_hour') ?? 21,
      'minute': prefs.getInt('notification_minute') ?? 0,
    };
  }
}
```

### ⏭️ 9. main.dart에 FCM 초기화 추가
**파일**: `lib/main.dart`

**추가할 코드**:
```dart
// 파일 상단에 import 추가
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/fcm_service.dart';

// 백그라운드 메시지 핸들러 (main 함수 밖에 정의)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM 서비스 초기화
  await FCMService().initialize();

  // 기존 Supabase 초기화 코드는 그대로 유지
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  AppConfig.validateApiKeys();

  runApp(const MyApp());
}
```

### ⏭️ 10. Supabase fcm_tokens 테이블 생성
Supabase Dashboard에서 SQL 실행:

```sql
-- FCM 토큰 테이블 생성
CREATE TABLE fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android', 'web')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_token ON fcm_tokens(token);

-- RLS 정책 활성화
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 토큰만 조회/삽입/업데이트 가능
CREATE POLICY "Users can view their own tokens"
  ON fcm_tokens FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tokens"
  ON fcm_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens"
  ON fcm_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tokens"
  ON fcm_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- updated_at 자동 업데이트 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fcm_tokens_updated_at
  BEFORE UPDATE ON fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### ⏭️ 11. FCM 토큰 저장 기능 구현
**파일**: `lib/data/services/fcm_service.dart` (위의 FCMService에 추가)

**추가할 메서드**:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// FCMService 클래스에 추가
Future<void> saveTokenToSupabase() async {
  if (_fcmToken == null) {
    print('FCM token is null');
    return;
  }

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    print('User not logged in');
    return;
  }

  try {
    // 디바이스 타입 결정
    String deviceType;
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isIOS) {
      deviceType = 'ios';
    } else if (Platform.isAndroid) {
      deviceType = 'android';
    } else {
      deviceType = 'unknown';
    }

    // 기존 토큰 확인
    final existing = await supabase
        .from('fcm_tokens')
        .select()
        .eq('user_id', userId)
        .eq('device_type', deviceType)
        .maybeSingle();

    if (existing != null) {
      // 토큰 업데이트
      await supabase
          .from('fcm_tokens')
          .update({
            'token': _fcmToken,
            'last_used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
      print('FCM token updated');
    } else {
      // 새 토큰 삽입
      await supabase.from('fcm_tokens').insert({
        'user_id': userId,
        'token': _fcmToken,
        'device_type': deviceType,
      });
      print('FCM token saved');
    }
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}
```

**main.dart에서 호출**:
```dart
// FCM 서비스 초기화 후
await FCMService().initialize();

// 로그인 후 토큰 저장 (AuthService에서 호출하거나 AuthWrapper에서 처리)
// 예: AuthWrapper에서 로그인 상태 확인 후
if (authState == AuthChangeEvent.signedIn) {
  await FCMService().saveTokenToSupabase();
}
```

### ⏭️ 12. MyPageScreen에 알림 설정 UI 추가
**파일**: `lib/ui/auth/widgets/my_page_screen.dart`

**추가할 UI 코드**:
```dart
// MyPageScreen에 추가
import 'package:book_golas/data/services/fcm_service.dart';

// State 변수
bool _notificationEnabled = false;
TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0);

@override
void initState() {
  super.initState();
  _loadNotificationSettings();
}

Future<void> _loadNotificationSettings() async {
  final settings = await FCMService().getNotificationSettings();
  setState(() {
    _notificationEnabled = settings['enabled'];
    _notificationTime = TimeOfDay(
      hour: settings['hour'],
      minute: settings['minute'],
    );
  });
}

// UI 위젯
Widget _buildNotificationSettings() {
  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '알림 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('매일 독서 목표 알림'),
            subtitle: Text(_notificationEnabled
                ? '매일 ${_notificationTime.format(context)}에 알림을 받습니다'
                : '알림을 받지 않습니다'),
            value: _notificationEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationEnabled = value;
              });

              if (value) {
                await FCMService().scheduleDailyNotification(
                  hour: _notificationTime.hour,
                  minute: _notificationTime.minute,
                );
              } else {
                await FCMService().cancelDailyNotification();
              }
            },
          ),
          if (_notificationEnabled)
            ListTile(
              title: const Text('알림 시간'),
              trailing: Text(
                _notificationTime.format(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _notificationTime,
                );

                if (time != null) {
                  setState(() {
                    _notificationTime = time;
                  });

                  await FCMService().scheduleDailyNotification(
                    hour: time.hour,
                    minute: time.minute,
                  );
                }
              },
            ),
        ],
      ),
    ),
  );
}
```

### ⏭️ 13. 알림 권한 상태 확인 및 안내
**파일**: `lib/data/services/fcm_service.dart`

**추가 메서드**:
```dart
// 알림 권한 상태 확인
Future<bool> isNotificationPermissionGranted() async {
  final settings = await _firebaseMessaging.getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
         settings.authorizationStatus == AuthorizationStatus.provisional;
}

// 권한 요청 (설정 화면 열기 안내)
Future<void> requestNotificationPermission() async {
  final hasPermission = await isNotificationPermissionGranted();

  if (!hasPermission) {
    // iOS에서는 한 번 거부하면 앱 설정에서 수동으로 켜야 함
    // 사용자에게 안내 다이얼로그 표시
    print('Please enable notifications in Settings');
  }
}
```

### ⏭️ 14. 매일 정해진 시간 알림 스케줄링 테스트
**테스트 체크리스트**:

1. **권한 확인**
   - [ ] iOS: Xcode에서 Push Notifications capability 추가 완료
   - [ ] iOS: Background Modes - Remote notifications 체크 완료
   - [ ] 앱 실행 시 알림 권한 팝업 표시 확인

2. **FCM 토큰 생성 및 저장**
   - [ ] 앱 실행 시 FCM 토큰이 콘솔에 출력되는지 확인
   - [ ] Supabase `fcm_tokens` 테이블에 토큰이 저장되는지 확인
   - [ ] 로그아웃 후 재로그인 시 토큰이 업데이트되는지 확인

3. **알림 설정 UI**
   - [ ] MyPage에서 알림 설정 카드가 표시되는지 확인
   - [ ] 알림 토글 on/off 동작 확인
   - [ ] 시간 선택 다이얼로그가 열리고 시간이 변경되는지 확인
   - [ ] 설정한 시간이 SharedPreferences에 저장되는지 확인

4. **로컬 알림 스케줄링**
   - [ ] 알림을 켜고 시간을 설정했을 때 스케줄링이 되는지 확인
   - [ ] 설정한 시간에 실제로 알림이 오는지 확인
   - [ ] 알림 메시지: "오늘의 목표 페이지 수를 설정해주세요!" 확인
   - [ ] 알림을 탭했을 때 앱이 열리는지 확인

5. **테스트 알림 발송**
   - [ ] 1분 후 알림 테스트 기능 추가 (개발용)
   - [ ] 포그라운드 상태에서 알림 수신 확인
   - [ ] 백그라운드 상태에서 알림 수신 확인
   - [ ] 앱 종료 상태에서 알림 수신 확인

**테스트용 임시 코드** (MyPageScreen에 버튼 추가):
```dart
// 테스트용 1분 후 알림
ElevatedButton(
  onPressed: () async {
    await FCMService().scheduleDailyNotification(
      hour: DateTime.now().hour,
      minute: DateTime.now().minute + 1,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('1분 후 알림이 발송됩니다')),
    );
  },
  child: const Text('테스트 알림 (1분 후)'),
),
```

---

## 다음 작업 시작 가이드

### 1단계: FCMService 클래스 구현
```bash
cd /Users/byungskersmacbook/Documents/GitHub/book-golas/app
```

새 파일 생성: `lib/data/services/fcm_service.dart`
위의 "⏭️ 8. FCMService 클래스 구현" 섹션의 전체 코드를 복사하여 붙여넣기

### 2단계: main.dart 수정
`lib/main.dart` 파일 열기
위의 "⏭️ 9. main.dart에 FCM 초기화 추가" 섹션의 코드 추가

### 3단계: Supabase 테이블 생성
1. Supabase Dashboard 접속: https://app.supabase.com
2. `book-golas` 프로젝트 선택
3. SQL Editor 열기
4. 위의 "⏭️ 10. Supabase fcm_tokens 테이블 생성" 섹션의 SQL 실행

### 4단계: FCM 토큰 저장 기능 추가
`lib/data/services/fcm_service.dart`에 토큰 저장 메서드 추가
`lib/main.dart` 또는 `AuthService`에서 로그인 후 토큰 저장 호출

### 5단계: MyPage 알림 설정 UI 추가
`lib/ui/auth/widgets/my_page_screen.dart` 수정
위의 "⏭️ 12. MyPageScreen에 알림 설정 UI 추가" 섹션의 코드 추가

### 6단계: 테스트
- iOS 시뮬레이터 또는 실제 기기에서 실행
- 알림 설정 UI에서 알림 켜기
- 1분 후 알림 테스트 버튼으로 알림 수신 확인

---

## 주의사항

1. **iOS Xcode 수동 설정 필수**
   - Push Notifications capability
   - Background Modes (Remote notifications)
   - 이 설정이 없으면 알림이 작동하지 않음

2. **Android 설정은 보류**
   - 사용자 요청으로 Android 네이티브 설정은 나중으로 미뤄짐
   - iOS 테스트 완료 후 Android 작업 진행 예정

3. **Firebase Console 설정**
   - APNs 인증 키 업로드 필요 (iOS 푸시를 위해)
   - Firebase Console → Project Settings → Cloud Messaging → APNs

4. **테스트 환경**
   - iOS 시뮬레이터는 푸시 알림을 수신할 수 없음
   - 실제 iOS 기기에서 테스트 필요

---

## 커밋 히스토리

```bash
git log --oneline
```

1. `docs: FCM 푸시 알림 구현 계획 문서 작성`
2. `refactor: 앱 패키지 이름을 litgoal에서 bookgolas로 변경`
3. `feat: FCM 푸시 알림 패키지 추가`
4. `feat: iOS Firebase 및 푸시 알림 네이티브 설정`

---

## 참고 문서

- **FCM_IMPLEMENTATION.md**: 전체 구현 계획 및 아키텍처
- **CLAUDE.md**: 프로젝트 개요 및 개발 가이드
- **BOOKGOLAS_ROADMAP.md**: 제품 로드맵

---

## 문의 사항

FCM 구현 중 문제가 발생하면:
1. Firebase Console에서 프로젝트 설정 확인
2. Xcode에서 Capabilities 설정 확인
3. FCM 토큰이 정상적으로 생성되는지 로그 확인
4. Supabase RLS 정책이 활성화되어 있는지 확인
