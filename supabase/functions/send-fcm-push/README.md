# FCM 푸시 알림 전송 Edge Function

이 Edge Function은 Firebase Cloud Messaging을 사용하여 푸시 알림을 전송합니다.

## 설정 방법

### 1. Firebase 서버 키 가져오기

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택
3. 프로젝트 설정 → 클라우드 메시징 탭
4. "서버 키" 복사

### 2. Supabase 시크릿 설정

```bash
# Supabase CLI로 시크릿 설정
supabase secrets set FCM_SERVER_KEY=your_firebase_server_key_here
```

또는 Supabase Dashboard에서:
1. Project Settings → Edge Functions → Secrets
2. `FCM_SERVER_KEY` 추가

### 3. Edge Function 배포

```bash
# Supabase CLI 설치 (없는 경우)
npm install -g supabase

# Supabase 로그인
supabase login

# 프로젝트 링크
supabase link --project-ref your-project-ref

# Edge Function 배포
supabase functions deploy send-fcm-push
```

## 사용 방법

### API 호출 예시

```typescript
// 특정 사용자에게 푸시 전송
const response = await fetch(
  'https://your-project.supabase.co/functions/v1/send-fcm-push',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${supabaseAnonKey}`,
    },
    body: JSON.stringify({
      userId: 'user-uuid-here',
      title: '오늘의 독서 목표',
      body: '오늘도 힘차게 독서를 시작해보아요!',
      data: {
        type: 'daily_reminder',
        screen: 'book_detail',
      },
    }),
  }
);
```

### 요청 파라미터

- `userId` (선택): 사용자 ID. 제공되면 해당 사용자의 모든 FCM 토큰에 전송
- `token` (선택): 단일 FCM 토큰. `userId`와 함께 사용 불가
- `title` (필수): 알림 제목
- `body` (필수): 알림 본문
- `data` (선택): 추가 데이터 (딥링크, 화면 이동 등)

### 응답 형식

```json
{
  "success": true,
  "sent": 2,
  "failed": 0,
  "total": 2
}
```

## 데이터베이스 스케줄러 설정 (선택)

매일 정해진 시간에 자동으로 푸시를 보내려면 Supabase의 `pg_cron` 확장을 사용할 수 있습니다:

```sql
-- pg_cron 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 매일 오후 9시에 푸시 전송 (예시)
SELECT cron.schedule(
  'daily-reading-reminder',
  '0 21 * * *', -- 매일 21:00
  $$
  SELECT
    net.http_post(
      url := 'https://your-project.supabase.co/functions/v1/send-fcm-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'userId', user_id,
        'title', '오늘 독서는 어땠나요?',
        'body', '현황을 업데이트해주세요!'
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

## 트러블슈팅

### "FCM_SERVER_KEY not configured" 에러
- Supabase 시크릿에 `FCM_SERVER_KEY`가 설정되었는지 확인

### "No FCM tokens found" 에러
- `fcm_tokens` 테이블에 해당 사용자의 토큰이 있는지 확인
- 앱에서 토큰이 제대로 저장되었는지 확인

### 푸시가 전송되지 않음
- Firebase 서버 키가 올바른지 확인
- FCM 토큰이 유효한지 확인 (토큰은 만료될 수 있음)
- 앱이 알림 권한을 받았는지 확인





