# FCM 서버 푸시 알림 구현 가이드

> **목표**: Supabase Edge Functions를 사용하여 서버에서 FCM 푸시 알림 전송
> **작성일**: 2025-12-14

---

## 📋 개요

현재 앱은 로컬 알림만 사용하고 있지만, 이제 **서버에서 FCM 푸시 알림을 보낼 수 있는 기능**이 추가되었습니다.

### 주요 변경사항

1. ✅ **Supabase Edge Function 생성** (`send-fcm-push`)
2. ✅ **FCM 서비스 개선** (서버 푸시 수신 처리)
3. ✅ **백그라운드 메시지 핸들러 개선**

---

## 🏗️ 아키텍처

```
[Supabase Edge Function]
    ↓
[FCM REST API]
    ↓
[Firebase Cloud Messaging]
    ↓
[사용자 기기]
    ├─ 포그라운드: 로컬 알림으로 표시
    ├─ 백그라운드: 시스템 알림 표시
    └─ 종료 상태: 시스템 알림 표시
```

---

## 🚀 설정 방법

### 1. Firebase 서버 키 가져오기

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택
3. **프로젝트 설정** → **클라우드 메시징** 탭
4. **서버 키** 복사 (또는 **서비스 계정**에서 새 키 생성)

> ⚠️ **주의**: 서버 키는 절대 클라이언트 코드에 노출되면 안 됩니다!

### 2. Supabase 시크릿 설정

#### 방법 1: Supabase CLI 사용

```bash
# Supabase CLI 설치 (없는 경우)
npm install -g supabase

# Supabase 로그인
supabase login

# 프로젝트 링크
supabase link --project-ref enyxrgxixrnoazzgqyyd

# 시크릿 설정
supabase secrets set FCM_SERVER_KEY=your_firebase_server_key_here
```

#### 방법 2: Supabase Dashboard 사용

1. [Supabase Dashboard](https://supabase.com/dashboard) 접속
2. 프로젝트 선택
3. **Project Settings** → **Edge Functions** → **Secrets**
4. `FCM_SERVER_KEY` 추가하고 Firebase 서버 키 입력

### 3. Edge Function 배포

```bash
# Edge Function 배포
supabase functions deploy send-fcm-push

# 배포 확인
supabase functions list
```

---

## 💻 사용 방법

### 클라이언트에서 테스트 (선택사항)

```dart
// FCMService 인스턴스 가져오기
final fcmService = FCMService();

// 서버 푸시 전송 요청 (테스트용)
await fcmService.requestServerPush(
  title: '테스트 알림',
  body: '서버에서 보낸 푸시 알림입니다!',
  data: {
    'type': 'test',
    'screen': 'home',
  },
);
```

### 서버에서 직접 호출 (권장)

#### Supabase Edge Function 직접 호출

```typescript
// 다른 Edge Function이나 백엔드에서 호출
const response = await fetch("https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-fcm-push", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
  },
  body: JSON.stringify({
    userId: "user-uuid-here",
    title: "오늘의 독서 목표",
    body: "오늘도 힘차게 독서를 시작해보아요!",
    data: {
      type: "daily_reminder",
      screen: "book_detail",
    },
  }),
});
```

#### Flutter에서 호출

```dart
final supabase = Supabase.instance.client;

final response = await supabase.functions.invoke(
  'send-fcm-push',
  body: {
    'userId': userId,
    'title': '오늘의 독서 목표',
    'body': '목표 페이지 수를 설정해주세요!',
    'data': {
      'type': 'daily_reminder',
      'screen': 'book_detail',
    },
  },
);
```

---

## 📅 자동 스케줄링 설정 (선택)

매일 정해진 시간에 자동으로 푸시를 보내려면 Supabase의 `pg_cron` 확장을 사용할 수 있습니다.

### 데이터베이스에서 스케줄러 설정

```sql
-- pg_cron 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 매일 오후 9시에 독서 현황 업데이트 알림 전송
SELECT cron.schedule(
  'daily-reading-reminder',
  '0 21 * * *', -- 매일 21:00 (KST)
  $$
  SELECT
    net.http_post(
      url := 'https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-fcm-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'userId', user_id,
        'title', '오늘 독서는 어땠나요?',
        'body', '현황을 업데이트해주세요!',
        'data', jsonb_build_object(
          'type', 'evening_reflection',
          'screen', 'book_detail'
        )
      )
    )
  FROM fcm_tokens
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE created_at > NOW() - INTERVAL '30 days'
  );
  $$
);
```

> ⚠️ **주의**: `pg_cron`은 Supabase Pro 플랜 이상에서만 사용 가능합니다.

---

## 🤔 클라이언트에서 FCM 푸시를 보낼 수 있나요?

### ❌ 클라이언트에서 직접 FCM 푸시 전송은 권장하지 않습니다

**이유:**

1. **보안 문제**: Firebase 서버 키를 클라이언트 코드에 포함하면 누구나 악용 가능
2. **무단 사용**: 서버 키가 노출되면 다른 사용자에게 스팸 알림을 보낼 수 있음
3. **Firebase 정책 위반**: Firebase는 서버 키를 서버 사이드에서만 사용하도록 권장

### ✅ 대안: 로컬 알림 사용 (현재 구현됨)

현재 앱은 이미 **로컬 알림**을 사용하고 있어서 클라이언트에서 직접 알림을 보낼 수 있습니다:

```dart
// 이미 구현되어 있음!
FCMService().scheduleDailyNotification(
  hour: 21,
  minute: 0,
);
```

**로컬 알림의 장점:**

- ✅ 서버 키 불필요 (보안 문제 없음)
- ✅ 인터넷 연결 불필요
- ✅ 배터리 효율적
- ✅ 앱이 종료되어도 작동
- ✅ 클라이언트에서 완전히 제어 가능

---

## 🔄 로컬 알림 vs 서버 푸시

### 로컬 알림 (현재 사용 중) ⭐ 권장

- ✅ 인터넷 연결 불필요
- ✅ 배터리 효율적
- ✅ 앱이 종료되어도 작동
- ✅ 클라이언트에서 직접 제어 가능
- ✅ 서버 키 불필요 (보안 안전)
- ❌ 앱이 삭제되면 알림도 사라짐
- ❌ 서버에서 제어 불가

### 서버 푸시 (선택사항)

- ✅ 서버에서 실시간 제어 가능
- ✅ 사용자별 맞춤 알림 가능
- ✅ 관리자 공지, 이벤트 알림 등 확장 가능
- ✅ 앱이 삭제되어도 서버에서 알림 전송 가능
- ❌ 인터넷 연결 필요
- ❌ FCM 토큰 관리 필요
- ❌ 서버 인프라 필요

### 권장 사용법

**대부분의 경우: 로컬 알림 사용 (현재 방식 유지)**

- ✅ 매일 정해진 시간 알림 → 로컬 알림
- ✅ 사용자가 설정한 알림 → 로컬 알림
- ✅ 앱 내 이벤트 알림 → 로컬 알림

**서버 푸시가 필요한 경우:**

- 관리자 공지 (서버에서 즉시 전송)
- 친구 초대/추천 (다른 사용자에게 전송)
- 목표 달성 축하 메시지 (서버에서 계산 후 전송)
- 이벤트 알림 (서버에서 스케줄링)

> 💡 **결론**: 현재 앱의 일일 독서 알림은 **로컬 알림으로 충분**합니다. 서버 푸시는 향후 확장 기능(친구 기능, 관리자 공지 등)을 위해 준비해둔 것입니다.

---

## 📱 알림 수신 처리

### 포그라운드 메시지

```dart
// fcm_service.dart에서 자동 처리
void _handleForegroundMessage(RemoteMessage message) {
  // 서버 푸시를 로컬 알림으로 변환하여 표시
  // 데이터 페이로드를 활용한 딥링크 처리 가능
}
```

### 백그라운드 메시지

```dart
// main.dart에서 처리
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) {
  // 백그라운드에서 데이터 처리 가능
  // 로컬 알림 스케줄링, 데이터 저장 등
}
```

### 알림 탭 처리

```dart
// main.dart에서 설정
FCMService().onNotificationTap = () {
  // 알림 탭 시 특정 화면으로 이동
  Navigator.push(...);
};
```

---

## 🧪 테스트 방법

### 1. Edge Function 테스트

```bash
# Supabase CLI로 로컬 테스트
supabase functions serve send-fcm-push

# 다른 터미널에서 테스트
curl -X POST http://localhost:54321/functions/v1/send-fcm-push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "userId": "user-uuid",
    "title": "테스트",
    "body": "테스트 메시지"
  }'
```

### 2. 앱에서 테스트

```dart
// 테스트 버튼 추가 (개발용)
ElevatedButton(
  onPressed: () async {
    final fcmService = FCMService();
    await fcmService.requestServerPush(
      title: '테스트 알림',
      body: '서버에서 보낸 푸시입니다!',
    );
  },
  child: Text('서버 푸시 테스트'),
)
```

---

## 🔧 트러블슈팅

### "FCM_SERVER_KEY not configured" 에러

- Supabase 시크릿에 `FCM_SERVER_KEY`가 설정되었는지 확인
- Edge Function이 재배포되었는지 확인

### "No FCM tokens found" 에러

- `fcm_tokens` 테이블에 해당 사용자의 토큰이 있는지 확인
- 앱에서 `FCMService().saveTokenToSupabase()`가 호출되었는지 확인

### 푸시가 전송되지 않음

- Firebase 서버 키가 올바른지 확인
- FCM 토큰이 유효한지 확인 (토큰은 만료될 수 있음)
- 앱이 알림 권한을 받았는지 확인
- Firebase Console에서 메시지 전송 로그 확인

### iOS에서 푸시가 안 옴

- APNs 인증서가 Firebase에 등록되었는지 확인
- Xcode에서 Push Notifications Capability가 활성화되었는지 확인
- 물리 기기에서 테스트 (시뮬레이터는 푸시 제한)

---

## 📚 참고 자료

- [Supabase Edge Functions 문서](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [FCM REST API 문서](https://firebase.google.com/docs/cloud-messaging/send-message)
- [FlutterFire FCM 문서](https://firebase.flutter.dev/docs/messaging/overview)

---

## ✅ 체크리스트

- [x] Supabase Edge Function 생성
- [x] FCM 서비스 코드 개선
- [x] 백그라운드 메시지 핸들러 개선
- [ ] Firebase 서버 키 Supabase 시크릿에 설정
- [ ] Edge Function 배포
- [ ] 테스트 푸시 전송 확인
- [ ] 자동 스케줄러 설정 (선택)

---

**마지막 업데이트**: 2025-12-14
