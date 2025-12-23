# 넛지(Nudge) & 인게이지먼트(Engagement) 푸시 알림 전략

> **질문**: 넛지, 인게이지먼트를 위한 푸시도 로컬 푸시로 충분해?

---

## 📊 넛지/인게이지먼트 알림의 종류

### 1. 단순 스케줄 알림 (로컬 알림으로 충분 ✅)

**예시:**
- "매일 오전 9시: 오늘의 독서 목표를 설정해주세요!"
- "매일 오후 9시: 오늘 독서는 어땠나요?"

**특징:**
- 시간 기반
- 고정된 메시지
- 사용자 상태와 무관

**결론: 로컬 알림으로 충분** ✅

---

### 2. 상태 기반 맞춤형 알림 (서버 푸시 권장 ⚠️)

**예시:**
- "3일째 독서를 안 했네요. 다시 시작해볼까요?"
- "목표 달성률이 80%입니다! 조금만 더!"
- "독서 연속일이 끊길 뻔했어요. 오늘도 읽어볼까요?"
- "목표 완료까지 5일 남았습니다!"

**특징:**
- 사용자의 현재 상태 기반 (마지막 독서 시간, 진행률 등)
- 동적 메시지 생성 필요
- 복잡한 비즈니스 로직 필요

**결론: 서버 푸시 권장** ⚠️

---

## 🔍 로컬 알림의 한계

### 문제점 1: 실시간 데이터 부족

```dart
// ❌ 로컬 알림의 한계
// 사용자가 앱을 사용하지 않으면 최신 상태를 알 수 없음

// 예: "3일째 독서를 안 했네요" 알림
// - 마지막 독서 시간을 클라이언트에서 추적해야 함
// - 앱이 종료되면 상태 업데이트 불가
// - 여러 기기에서 사용 시 동기화 문제
```

### 문제점 2: 복잡한 로직 처리

```dart
// ❌ 클라이언트에서 복잡한 로직 처리
Future<void> scheduleSmartNudge() async {
  // 1. 마지막 독서 시간 확인
  final lastReading = await getLastReadingTime();
  
  // 2. 목표 달성률 계산
  final progress = await calculateProgress();
  
  // 3. 연속일 계산
  final streak = await calculateStreak();
  
  // 4. 조건에 따라 다른 메시지 생성
  String message;
  if (lastReading.difference(DateTime.now()).inDays >= 3) {
    message = "3일째 독서를 안 했네요. 다시 시작해볼까요?";
  } else if (progress < 0.5) {
    message = "목표 달성률이 ${(progress * 100).toInt()}%입니다!";
  } else if (streak > 0 && streak < 7) {
    message = "독서 연속일이 ${streak}일입니다! 계속 화이팅!";
  }
  
  // 5. 알림 스케줄링
  // ... 하지만 이 모든 로직을 클라이언트에서 처리하는 것은 비효율적
}
```

### 문제점 3: 여러 기기 동기화

- 사용자가 여러 기기에서 앱을 사용하는 경우
- 한 기기에서 독서했지만 다른 기기에서는 알 수 없음
- 서버에서 중앙 집중식으로 관리해야 함

---

## ✅ 서버 푸시의 장점

### 장점 1: 실시간 데이터 분석

```typescript
// ✅ 서버에서 사용자 상태 실시간 분석
async function sendSmartNudge(userId: string) {
  // 1. 서버에서 최신 데이터 조회
  const lastReading = await getLastReadingTime(userId);
  const progress = await calculateProgress(userId);
  const streak = await calculateStreak(userId);
  
  // 2. 조건에 따라 맞춤형 메시지 생성
  let message = "";
  if (lastReading.difference(now).inDays >= 3) {
    message = "3일째 독서를 안 했네요. 다시 시작해볼까요?";
  } else if (progress < 0.5) {
    message = `목표 달성률이 ${(progress * 100).toInt()}%입니다! 조금만 더!`;
  }
  
  // 3. 푸시 전송
  await sendFCMPush(userId, {
    title: "독서를 잊지 마세요!",
    body: message,
  });
}
```

### 장점 2: 중앙 집중식 관리

- 모든 사용자 데이터를 서버에서 관리
- 여러 기기에서 동기화된 알림 전송
- A/B 테스트, 알림 최적화 가능

### 장점 3: 복잡한 비즈니스 로직

```typescript
// ✅ 서버에서 복잡한 로직 처리
async function analyzeUserEngagement(userId: string) {
  const user = await getUser(userId);
  const books = await getActiveBooks(userId);
  const readingHistory = await getReadingHistory(userId);
  
  // 독서 패턴 분석
  const pattern = analyzeReadingPattern(readingHistory);
  
  // 최적의 알림 시간 계산
  const bestTime = calculateOptimalNotificationTime(pattern);
  
  // 맞춤형 메시지 생성
  const message = generatePersonalizedMessage(user, books, pattern);
  
  return { time: bestTime, message };
}
```

---

## 🎯 권장 전략

### 하이브리드 접근법 (권장)

#### 1. 기본 알림: 로컬 알림 사용 ✅

```dart
// 매일 정해진 시간에 기본 알림
FCMService().scheduleDailyNotification(
  hour: 9,
  minute: 0,
);
```

**이유:**
- 간단하고 효율적
- 서버 부하 없음
- 배터리 효율적

#### 2. 스마트 넛지: 서버 푸시 사용 ⚠️

```typescript
// 서버에서 사용자 상태 분석 후 푸시 전송
// 예: 3일째 독서 안 함 감지 → 넛지 알림
```

**이유:**
- 실시간 데이터 기반
- 맞춤형 메시지
- 복잡한 로직 처리 가능

---

## 💡 구현 예시

### 시나리오 1: 단순 일일 알림 (로컬 알림)

```dart
// ✅ 로컬 알림으로 충분
await FCMService().scheduleDailyNotification(
  hour: 9,
  minute: 0,
);
```

### 시나리오 2: 독서 슬럼프 감지 (서버 푸시)

```typescript
// ✅ 서버에서 처리
// pg_cron으로 매일 오후 6시에 실행
SELECT cron.schedule(
  'detect-reading-slump',
  '0 18 * * *',
  $$
  -- 3일 이상 독서 안 한 사용자 찾기
  WITH inactive_users AS (
    SELECT DISTINCT user_id
    FROM books b
    WHERE b.user_id IN (
      SELECT user_id FROM fcm_tokens
    )
    AND NOT EXISTS (
      SELECT 1 FROM reading_progress_history rph
      WHERE rph.book_id = b.id
      AND rph.created_at > NOW() - INTERVAL '3 days'
    )
  )
  SELECT net.http_post(
    url := 'https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-fcm-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object(
      'userId', user_id,
      'title', '독서를 잊지 마세요!',
      'body', '3일째 독서를 안 했네요. 다시 시작해볼까요?',
      'data', jsonb_build_object(
        'type', 'nudge',
        'screen', 'book_detail'
      )
    )
  )
  FROM inactive_users;
  $$
);
```

### 시나리오 3: 목표 달성률 알림 (서버 푸시)

```typescript
// ✅ 서버에서 진행률 계산 후 푸시
async function sendProgressNudge(userId: string) {
  const books = await getActiveBooks(userId);
  
  for (const book of books) {
    const progress = book.currentPage / book.totalPages;
    
    if (progress >= 0.8 && progress < 0.9) {
      await sendFCMPush(userId, {
        title: "목표 달성까지 조금만!",
        body: `"${book.title}" 완독까지 ${book.totalPages - book.currentPage}페이지 남았어요!`,
        data: {
          type: 'progress_nudge',
          bookId: book.id,
        },
      });
    }
  }
}
```

---

## 📊 비교표

| 알림 유형 | 로컬 알림 | 서버 푸시 | 권장 |
|----------|----------|----------|------|
| **매일 정해진 시간 알림** | ✅ | ⚠️ | 로컬 알림 |
| **3일째 독서 안 함 감지** | ❌ | ✅ | 서버 푸시 |
| **목표 달성률 알림** | ❌ | ✅ | 서버 푸시 |
| **독서 연속일 알림** | ❌ | ✅ | 서버 푸시 |
| **목표 완료까지 남은 일수** | ❌ | ✅ | 서버 푸시 |
| **맞춤형 메시지** | ❌ | ✅ | 서버 푸시 |

---

## 🎯 결론

### 넛지/인게이지먼트 푸시는 목적에 따라 다릅니다

#### 로컬 알림으로 충분한 경우 ✅
- 매일 정해진 시간에 고정 메시지
- 단순 스케줄 알림
- 사용자 상태와 무관한 알림

#### 서버 푸시가 필요한 경우 ⚠️
- 사용자 상태 기반 맞춤형 알림
- 복잡한 비즈니스 로직 필요
- 실시간 데이터 분석 필요
- 여러 기기 동기화 필요

### 현재 앱의 경우

**현재 구현 (로컬 알림):**
- ✅ 매일 오전 9시: "오늘의 독서 목표"
- ✅ 매일 오후 9시: "오늘 독서는 어땠나요?"

**향후 확장 시 (서버 푸시):**
- ⚠️ "3일째 독서를 안 했네요" 넛지
- ⚠️ "목표 달성률 80%" 인게이지먼트
- ⚠️ "독서 연속일" 알림
- ⚠️ "목표 완료까지 N일" 알림

---

## 🚀 구현 우선순위

### Phase 1: 현재 (로컬 알림 유지) ✅
- 매일 정해진 시간 알림
- 간단하고 효율적

### Phase 2: 향후 (서버 푸시 추가) ⚠️
- 독서 슬럼프 감지
- 목표 달성률 알림
- 독서 연속일 알림

> 💡 **결론**: 기본 알림은 로컬 알림으로 충분하지만, **스마트한 넛지/인게이지먼트**를 위해서는 서버 푸시가 필요합니다.





