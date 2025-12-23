# 개인 데이터 기반 스마트 넛지 푸시 구현 가이드

> **목표**: 사용자의 독서 상태를 분석하여 맞춤형 넛지 알림 전송
> **작성일**: 2025-12-14

---

## ✅ 네, 서버 푸시가 필요합니다!

개인 데이터에 맞춘 넛지 푸시를 위해서는 **서버 푸시가 필수**입니다.

### 이유

1. **실시간 데이터 분석 필요**
   - 마지막 독서 시간
   - 진행률 계산
   - 연속일 계산
   - 목표 달성률

2. **복잡한 비즈니스 로직**
   - 여러 조건 조합
   - 우선순위 결정
   - 맞춤형 메시지 생성

3. **중앙 집중식 관리**
   - 여러 기기 동기화
   - A/B 테스트 가능
   - 알림 최적화

---

## 🏗️ 구현 완료 사항

### 1. 스마트 넛지 Edge Function 생성

**파일**: `supabase/functions/send-smart-nudge/index.ts`

**기능:**
- 사용자의 독서 상태 실시간 분석
- 5가지 넛지 타입 지원
- 맞춤형 메시지 생성
- 자동 우선순위 결정

### 2. 넛지 타입

#### 1. 비활성 넛지 (`inactive`)
```
조건: 3일 이상 독서를 안 한 경우
메시지: "3일째 독서를 안 했네요. 다시 시작해볼까요?"
```

#### 2. 마감일 임박 (`deadline`)
```
조건: 목표 완료일까지 3일 이하 남음
메시지: "목표 완료까지 2일 남았습니다."
```

#### 3. 진행률 넛지 (`progress`)
```
조건: 진행률 80% 이상 100% 미만
메시지: "목표 달성률이 85%입니다! 조금만 더!"
```

#### 4. 연속일 넛지 (`streak`)
```
조건: 독서 연속일 1일 이상 7일 미만
메시지: "독서 연속일이 5일입니다! 계속 화이팅!"
```

#### 5. 달성 축하 (`achievement`)
```
조건: 책 완독
메시지: "완독을 축하합니다! 🎉"
```

---

## 🚀 사용 방법

### 1. Edge Function 배포

```bash
# Supabase CLI로 배포
supabase functions deploy send-smart-nudge
```

### 2. Flutter에서 호출

```dart
// 사용자에게 스마트 넛지 전송
final supabase = Supabase.instance.client;
final userId = supabase.auth.currentUser?.id;

if (userId != null) {
  final response = await supabase.functions.invoke(
    'send-smart-nudge',
    body: {
      'userId': userId,
      // 'forceType': 'inactive', // 선택사항: 특정 타입 강제
    },
  );
  
  print('넛지 전송 결과: ${response.data}');
}
```

### 3. 자동 스케줄링 (선택)

매일 정해진 시간에 자동으로 넛지를 보내려면:

```sql
-- pg_cron 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron;

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
    -- 3일 이상 독서 안 한 사용자
    SELECT DISTINCT b.user_id
    FROM books b
    WHERE NOT EXISTS (
      SELECT 1 FROM reading_progress_history rph
      WHERE rph.book_id = b.id
      AND rph.created_at > NOW() - INTERVAL '3 days'
    )
  );
  $$
);
```

---

## 📊 넛지 우선순위

Edge Function은 다음 우선순위로 넛지를 결정합니다:

1. **비활성** (3일 이상 독서 안 함) - 최우선
2. **마감일 임박** (3일 이하 남음)
3. **진행률** (80% 이상)
4. **연속일** (1-7일)

넛지가 필요하지 않은 사용자에게는 알림을 보내지 않습니다.

---

## 🎯 사용 시나리오

### 시나리오 1: 사용자가 3일째 독서를 안 함

```dart
// 서버에서 자동 감지 후 넛지 전송
// 또는 수동 호출
await supabase.functions.invoke('send-smart-nudge', body: {
  'userId': userId,
});
```

**결과:**
- 넛지 타입: `inactive`
- 메시지: "3일째 독서를 안 했네요. 다시 시작해볼까요?"

### 시나리오 2: 목표 완료일까지 2일 남음

```dart
await supabase.functions.invoke('send-smart-nudge', body: {
  'userId': userId,
});
```

**결과:**
- 넛지 타입: `deadline`
- 메시지: "목표 완료까지 2일 남았습니다."

### 시나리오 3: 특정 넛지 타입 강제 전송

```dart
// 테스트용: 특정 타입 강제
await supabase.functions.invoke('send-smart-nudge', body: {
  'userId': userId,
  'forceType': 'progress', // 진행률 넛지 강제
});
```

---

## 🔄 로컬 알림 vs 스마트 넛지

| 기능 | 로컬 알림 | 스마트 넛지 (서버 푸시) |
|------|----------|----------------------|
| **고정 메시지** | ✅ | ❌ |
| **맞춤형 메시지** | ❌ | ✅ |
| **상태 기반** | ❌ | ✅ |
| **실시간 분석** | ❌ | ✅ |
| **복잡한 로직** | ❌ | ✅ |

### 권장 사용법

- **기본 일일 알림**: 로컬 알림 사용
- **스마트 넛지**: 서버 푸시 사용

---

## 📱 알림 수신 처리

앱에서 스마트 넛지를 받으면:

```dart
// fcm_service.dart에서 자동 처리
void _handleForegroundMessage(RemoteMessage message) {
  if (message.data['type'] == 'smart_nudge') {
    final nudgeType = message.data['nudgeType'];
    final bookId = message.data['bookId'];
    
    // 넛지 타입에 따라 다른 화면으로 이동
    if (bookId != null) {
      // 책 상세 페이지로 이동
      Navigator.push(...);
    }
  }
}
```

---

## ✅ 체크리스트

- [x] 스마트 넛지 Edge Function 생성
- [x] 5가지 넛지 타입 구현
- [x] 우선순위 로직 구현
- [ ] Edge Function 배포
- [ ] 자동 스케줄링 설정 (선택)
- [ ] 테스트 및 검증

---

## 🎉 결론

**개인 데이터 기반 넛지 푸시는 서버 푸시가 필수입니다!**

이제 사용자의 독서 상태를 실시간으로 분석하여 맞춤형 넛지 알림을 보낼 수 있습니다.

---

**마지막 업데이트**: 2025-12-14





