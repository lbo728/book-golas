# 스마트 넛지 푸시 알림 Edge Function

사용자의 개인 독서 데이터를 분석하여 맞춤형 넛지 알림을 전송하는 Edge Function입니다.

## 기능

### 분석하는 데이터
- 마지막 독서 시간
- 독서 진행률
- 목표 완료까지 남은 일수
- 독서 연속일 (Streak)
- 활성 책 목록

### 넛지 타입

1. **비활성 넛지** (`inactive`)
   - 3일 이상 독서를 안 한 경우
   - 예: "3일째 독서를 안 했네요. 다시 시작해볼까요?"

2. **마감일 임박** (`deadline`)
   - 목표 완료일까지 3일 이하 남은 경우
   - 예: "목표 완료까지 2일 남았습니다."

3. **진행률 넛지** (`progress`)
   - 진행률이 80% 이상 100% 미만인 경우
   - 예: "목표 달성률이 85%입니다! 조금만 더!"

4. **연속일 넛지** (`streak`)
   - 독서 연속일이 1일 이상 7일 미만인 경우
   - 예: "독서 연속일이 5일입니다! 계속 화이팅!"

5. **달성 축하** (`achievement`)
   - 책 완독 시
   - 예: "완독을 축하합니다! 🎉"

## 사용 방법

### 1. Edge Function 배포

```bash
supabase functions deploy send-smart-nudge
```

### 2. API 호출

```typescript
// 특정 사용자에게 스마트 넛지 전송
const response = await fetch(
  'https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-smart-nudge',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    },
    body: JSON.stringify({
      userId: 'user-uuid-here',
      // forceType: 'inactive', // 선택사항: 특정 타입 강제
    }),
  }
);
```

### 3. Flutter에서 호출

```dart
final supabase = Supabase.instance.client;

final response = await supabase.functions.invoke(
  'send-smart-nudge',
  body: {
    'userId': userId,
    // 'forceType': 'inactive', // 선택사항
  },
);
```

## 자동 스케줄링 설정

매일 정해진 시간에 자동으로 스마트 넛지를 보내려면 `pg_cron`을 사용할 수 있습니다:

```sql
-- 매일 오후 6시에 비활성 사용자에게 넛지 전송
SELECT cron.schedule(
  'daily-smart-nudge',
  '0 18 * * *', -- 매일 18:00
  $$
  SELECT
    net.http_post(
      url := 'https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-smart-nudge',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'userId', user_id
      )
    )
  FROM fcm_tokens
  WHERE user_id IN (
    SELECT DISTINCT user_id FROM books
    WHERE updated_at < NOW() - INTERVAL '1 day'
  );
  $$
);
```

## 응답 형식

```json
{
  "success": true,
  "nudgeType": "inactive",
  "sent": 1,
  "failed": 0,
  "total": 1
}
```

## 넛지 우선순위

1. **비활성** (3일 이상 독서 안 함)
2. **마감일 임박** (3일 이하 남음)
3. **진행률** (80% 이상)
4. **연속일** (1-7일)

## 참고

- 넛지가 필요하지 않은 사용자에게는 알림을 보내지 않습니다.
- 여러 기기에 등록된 토큰이 있으면 모두 전송합니다.
- 무효한 토큰은 자동으로 정리됩니다.





