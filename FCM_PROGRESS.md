# FCM 푸시 알림 구현 진행 상황

## 작업 브랜치
`feature/fcm-push-notifications`

## 완료된 작업 (13/14)

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

### ✅ 7. Android 네이티브 설정 (보류)
사용자 요청으로 나중 작업으로 미뤄짐.

### ✅ 8. FCMService 클래스 구현
- **파일**: `app/lib/data/services/fcm_service.dart`
- **커밋**: 다음 커밋에 포함 예정
- **내용**:
  - FCM 초기화 및 토큰 관리
  - 로컬 알림 스케줄링
  - Supabase 토큰 저장 기능
  - 알림 권한 확인 메서드

### ✅ 9. main.dart에 FCM 초기화 추가
- **파일**: `app/lib/main.dart`
- **커밋**: 다음 커밋에 포함 예정
- **내용**:
  - Firebase 초기화
  - 백그라운드 메시지 핸들러 등록
  - FCM 서비스 초기화
  - AuthWrapper에서 로그인 후 토큰 저장
  - import 경로 lit_goal → book_golas 변경

### ✅ 10. Supabase fcm_tokens 테이블 생성
- **상태**: SQL 제공 완료
- **작업 필요**: 사용자가 Supabase Dashboard에서 SQL 실행 필요

### ✅ 11. FCM 토큰 저장 기능 구현
- **파일**: `app/lib/data/services/fcm_service.dart`
- **내용**: `saveTokenToSupabase()` 메서드가 FCMService에 포함됨

### ✅ 12. MyPageScreen에 알림 설정 UI 추가
- **파일**: `app/lib/ui/auth/widgets/my_page_screen.dart`
- **커밋**: 다음 커밋에 포함 예정
- **내용**:
  - 알림 on/off 토글
  - 알림 시간 설정 UI
  - FCMService 연동

### ✅ 13. 알림 권한 상태 확인 및 안내
- **파일**: `app/lib/data/services/fcm_service.dart`
- **내용**:
  - `isNotificationPermissionGranted()` 메서드
  - `requestNotificationPermission()` 메서드

---

## 대기 중인 작업 (1/14)

### ⏭️ 14. 매일 정해진 시간 알림 스케줄링 테스트

**현재 상태**: 구현 완료, 테스트 대기 중

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

## 다음 작업: Supabase 테이블 생성 및 테스트

### 필수 작업: Supabase fcm_tokens 테이블 생성
1. Supabase Dashboard 접속: https://app.supabase.com
2. `book-golas` 프로젝트 선택
3. SQL Editor 열기
4. 위의 섹션에서 제공된 SQL 실행

### 테스트 준비
1. **iOS Xcode 설정** (필수):
   - `ios/Runner.xcworkspace` 열기
   - Runner 타겟 선택 → Signing & Capabilities
   - **Push Notifications** capability 추가
   - **Background Modes** capability 추가 → **Remote notifications** 체크

2. **앱 실행 및 테스트**:
   ```bash
   cd /Users/byungskersmacbook/Documents/GitHub/book-golas/app
   flutter run
   ```

3. **테스트 항목**:
   - 앱 실행 시 FCM 토큰이 콘솔에 출력되는지 확인
   - MyPage에서 알림 설정 UI 확인
   - 알림 토글 on/off 동작 확인
   - 알림 시간 설정 동작 확인

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
5. `docs: FCM 구현 작업 현황 문서 작성` (FCM_PROGRESS.md)
6. (다음 커밋 예정) `feat: FCM 서비스 구현 및 알림 설정 UI 추가`
   - FCMService 클래스 구현
   - main.dart FCM 초기화
   - MyPageScreen 알림 설정 UI
   - import 경로 변경 (lit_goal → book_golas)

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
