# Push Notification 고도화 실행 계획

> **목표:** PRD_SMART_NUDGE.md 기반 스마트 넛지 시스템 완성 + 웹 어드민
> **시작일:** 2025-12-24
> **관련 문서:** `PRD_SMART_NUDGE.md`, `PUSH_NOTIFICATION_WORKFLOW.md`

---

## 프로젝트 구조

```
book-golas/
├── app/                    # Flutter 모바일 앱
├── web/                    # Next.js 웹 (랜딩 + 어드민)
│   ├── src/
│   │   ├── app/
│   │   │   ├── (public)/   # 랜딩 페이지
│   │   │   │   └── page.tsx
│   │   │   ├── (admin)/    # 어드민 대시보드
│   │   │   │   ├── layout.tsx
│   │   │   │   ├── dashboard/
│   │   │   │   ├── push-templates/
│   │   │   │   └── push-logs/
│   │   │   └── layout.tsx
│   │   ├── components/
│   │   │   └── ui/         # shadcn/ui
│   │   └── lib/
│   │       └── supabase.ts
│   ├── package.json
│   └── vercel.json
└── supabase/               # Edge Functions & Migrations
```

---

## 현재 상태 요약 (2025-12-25 업데이트)

### Phase 1: 푸시 관리 인프라 ✅ 완료
- [x] 기본 FCM 인프라 (send-fcm-push, send-smart-nudge, send-batch-nudge)
- [x] 사용자별 알림 시간 설정 (preferred_hour)
- [x] 알림 ON/OFF 토글
- [x] 넛지 타입: inactive, deadline, progress, streak, achievement
- [x] Deep Link 처리 (bookId → 상세 화면)
- [x] push_logs 테이블 (발송/클릭 이력)
- [x] push_templates 테이블 (메시지 관리)
- [x] 클릭 이벤트 수집 API (log-push-click)
- [ ] Flutter 클릭 이벤트 전송 (앱 작업 필요)

### Phase 4: 웹 어드민 ✅ 거의 완료
- [x] Next.js 16 + shadcn/ui 프로젝트 구축
- [x] Supabase 연동
- [x] 대시보드 (/admin) - 오늘 발송량, CTR, 타입별 분포
- [x] 푸시 템플릿 CRUD (/admin/push-templates)
- [x] 발송 로그 조회 (/admin/push-logs)
- [x] 테스트 발송 (/admin/test-push) - 추가 구현
- [x] Vercel 배포
- [ ] 관리자 인증 (middleware)

### 미구현
- [ ] Anti-Nudge (3회 미클릭 시 중단)
- [ ] Time Currency (남은 시간 계산)
- [ ] 랜딩 페이지

---

## Phase 1: 푸시 관리 인프라 (1-2일)

### 1.1 push_templates 테이블 생성
> 코드 수정 없이 메시지 변경 가능하게

```sql
CREATE TABLE push_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT UNIQUE NOT NULL,  -- inactive, deadline, progress, streak, achievement
  title TEXT NOT NULL,
  body_template TEXT NOT NULL,  -- 변수: {bookTitle}, {days}, {percent}
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 100,  -- 낮을수록 우선
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 템플릿 삽입
INSERT INTO push_templates (type, title, body_template, priority) VALUES
('inactive', '독서를 잊지 마세요! 📚', '{days}일째 독서를 안 했네요. 다시 시작해볼까요?', 10),
('deadline', '목표 완료까지 얼마 안 남았어요! ⏰', '"{bookTitle}" 완독까지 {days}일 남았습니다.', 20),
('progress', '목표 달성까지 조금만 더! 🎯', '"{bookTitle}" {percent}% 완독했습니다. 조금만 더 화이팅!', 30),
('streak', '독서 연속일을 이어가세요! 🔥', '독서 연속일이 {days}일입니다! 오늘도 읽어볼까요?', 40),
('achievement', '목표를 달성했어요! 🎉', '"{bookTitle}" 완독을 축하합니다!', 50);
```

**구현 작업:**
- [ ] Migration 파일 생성
- [ ] send-smart-nudge에서 템플릿 조회하도록 수정
- [ ] 변수 치환 로직 추가

---

### 1.2 push_logs 테이블 생성
> 발송 이력 및 클릭 추적

```sql
CREATE TABLE push_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  push_type TEXT NOT NULL,
  book_id UUID,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  is_clicked BOOLEAN DEFAULT false,
  clicked_at TIMESTAMPTZ,

  -- 인덱스
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE INDEX idx_push_logs_user_sent ON push_logs(user_id, sent_at DESC);
CREATE INDEX idx_push_logs_clicked ON push_logs(user_id, is_clicked);
```

**구현 작업:**
- [ ] Migration 파일 생성
- [ ] send-batch-nudge에서 발송 시 로그 저장
- [ ] 클릭 업데이트 Edge Function 생성

---

### 1.3 클릭 이벤트 수집 API

**Edge Function: `log-push-click`**
```typescript
// 클라이언트에서 푸시 탭 시 호출
POST /functions/v1/log-push-click
{ "logId": "xxx" } 또는 { "userId": "xxx", "pushType": "inactive" }
```

**Flutter 클라이언트 수정:**
- [ ] 푸시 탭 시 log-push-click 호출
- [ ] payload에 logId 포함

---

## Phase 2: Anti-Nudge 구현 (1일)

### 2.1 3회 미클릭 감지 로직

```typescript
// send-batch-nudge 내 추가
async function shouldSkipUser(supabase, userId): Promise<boolean> {
  const { data: recentPushes } = await supabase
    .from('push_logs')
    .select('is_clicked')
    .eq('user_id', userId)
    .order('sent_at', { ascending: false })
    .limit(3);

  if (recentPushes?.length === 3) {
    const allIgnored = recentPushes.every(p => !p.is_clicked);
    return allIgnored;
  }
  return false;
}
```

**구현 작업:**
- [ ] shouldSkipUser 함수 추가
- [ ] 스킵된 사용자 카운트 로깅
- [ ] D+3 "책 변경 제안" 로직 (별도 타입)

---

## Phase 3: Time Currency 구현 (2일)

### 3.1 독서 속도 계산

**필요 데이터:**
- reading_sessions 테이블 (또는 기존 books의 updated_at 활용)
- 세션당 읽은 페이지 수 / 소요 시간

**간소화 버전 (Phase 3.1):**
```typescript
// 기본 속도: 1페이지당 2분 (업계 평균)
const DEFAULT_PAGE_PER_MINUTE = 0.5;

const remainingPages = totalPages - currentPage;
const remainingMinutes = remainingPages / DEFAULT_PAGE_PER_MINUTE;

if (remainingMinutes <= 30) {
  // "잠들기 전 딱 N분만 투자하세요" 발송
}
```

**구현 작업:**
- [ ] time_currency 넛지 타입 추가
- [ ] 발송 조건: 오늘 독서 기록 없음 + 30분 이내 완독 가능
- [ ] 22:00 KST 전용 스케줄 (또는 preferred_hour 활용)

---

## Phase 4: 웹 어드민 구축 (2-3일)

### 4.0 기술 스택
- **Framework:** Next.js 15 (App Router)
- **UI:** shadcn/ui + Tailwind CSS
- **Database:** Supabase (기존 프로젝트 연동)
- **Auth:** Supabase Auth (관리자 전용)
- **Deployment:** Vercel

### 4.1 프로젝트 초기화

```bash
cd /Users/byungskersmacbook/Documents/GitHub/book-golas
npx create-next-app@latest web --typescript --tailwind --eslint --app --src-dir
cd web
npx shadcn@latest init
npx shadcn@latest add button card table input select badge
npm install @supabase/supabase-js @supabase/ssr
```

### 4.2 어드민 페이지 구성

| 경로 | 기능 | 우선순위 |
|------|------|----------|
| `/admin` | 대시보드 (오늘 발송량, CTR, 활성 사용자) | 🔴 |
| `/admin/push-templates` | 푸시 템플릿 CRUD | 🔴 |
| `/admin/push-logs` | 발송 이력 조회 (필터, 페이지네이션) | 🟡 |
| `/admin/users` | 사용자 목록 (FCM 토큰 상태) | 🟢 |
| `/` | 랜딩 페이지 | 🟢 |

### 4.3 대시보드 화면

```
┌─────────────────────────────────────────────────────────────┐
│  📊 Push Notification Dashboard                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ 오늘 발송 │  │   CTR    │  │ 활성유저  │  │ 미클릭3+  │     │
│  │   127    │  │  8.2%    │  │   89     │  │   12     │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 타입별 발송 현황                                      │    │
│  │ inactive  ████████████  45 (CTR 12%)                │    │
│  │ deadline  ██████        22 (CTR 9%)                 │    │
│  │ progress  ████████      30 (CTR 6%)                 │    │
│  │ streak    ████████      30 (CTR 5%)                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 최근 발송 로그                              [더보기 →] │    │
│  │ 14:23  inactive  user@example.com  ✅ clicked       │    │
│  │ 14:22  deadline  user2@example.com ⏳ pending       │    │
│  │ 14:20  progress  user3@example.com ❌ ignored       │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 4.4 푸시 템플릿 관리

```
┌─────────────────────────────────────────────────────────────┐
│  📝 Push Templates                            [+ 새 템플릿]  │
├─────────────────────────────────────────────────────────────┤
│ Type       │ Title              │ Active │ Priority │ Edit  │
├────────────┼────────────────────┼────────┼──────────┼───────┤
│ inactive   │ 독서를 잊지 마세요! │  ✅    │   10     │  ✏️   │
│ deadline   │ 목표 완료까지...   │  ✅    │   20     │  ✏️   │
│ progress   │ 목표 달성까지...   │  ✅    │   30     │  ✏️   │
│ streak     │ 독서 연속일을...   │  ✅    │   40     │  ✏️   │
│ anti_nudge │ 책 변경 제안       │  ❌    │    1     │  ✏️   │
└─────────────────────────────────────────────────────────────┘

[편집 모달]
┌─────────────────────────────────────────┐
│ 템플릿 수정: inactive                    │
├─────────────────────────────────────────┤
│ Title:  [독서를 잊지 마세요! 📚      ]  │
│ Body:   [{days}일째 독서를 안 했네요. ] │
│         [다시 시작해볼까요?           ] │
│ Active: [✅]  Priority: [10]           │
│                                         │
│ 사용 가능 변수:                          │
│ {days}, {bookTitle}, {percent}          │
│                                         │
│         [취소]  [저장]                  │
└─────────────────────────────────────────┘
```

### 4.5 인증 (Supabase Auth)

```typescript
// middleware.ts - 어드민 경로 보호
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'

export async function middleware(req) {
  if (req.nextUrl.pathname.startsWith('/admin')) {
    const supabase = createMiddlewareClient({ req, res })
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      return NextResponse.redirect(new URL('/login', req.url))
    }

    // 관리자 체크 (users 테이블에 is_admin 컬럼)
    const { data: user } = await supabase
      .from('users')
      .select('is_admin')
      .eq('id', session.user.id)
      .single()

    if (!user?.is_admin) {
      return NextResponse.redirect(new URL('/', req.url))
    }
  }
}
```

---

## Phase 5: 푸시 현황 조회 SQL (참고용)

```sql
-- 오늘 발송 통계
SELECT
  push_type,
  COUNT(*) as sent,
  SUM(CASE WHEN is_clicked THEN 1 ELSE 0 END) as clicked,
  ROUND(100.0 * SUM(CASE WHEN is_clicked THEN 1 ELSE 0 END) / COUNT(*), 2) as ctr
FROM push_logs
WHERE sent_at >= CURRENT_DATE
GROUP BY push_type;

-- 알림 피로도 높은 사용자 (최근 5회 모두 미클릭)
SELECT user_id, COUNT(*) as ignored_count
FROM push_logs
WHERE is_clicked = false
  AND sent_at >= NOW() - INTERVAL '7 days'
GROUP BY user_id
HAVING COUNT(*) >= 5;
```

### 4.2 Supabase Studio 활용
- `push_templates` 테이블에서 직접 메시지 수정
- `push_logs`에서 발송 이력 확인
- SQL Editor에서 통계 쿼리 실행

---

## 병렬 작업 전략

```
Day 1: 기반 작업
├── [Backend] push_templates + push_logs 마이그레이션
└── [Frontend] Next.js 프로젝트 초기화 + shadcn/ui

Day 2: 핵심 기능
├── [Backend] send-batch-nudge 로그 저장 + log-push-click
└── [Frontend] 어드민 대시보드 + 푸시 템플릿 CRUD

Day 3: 고급 기능
├── [Backend] Anti-Nudge 로직
├── [Frontend] 발송 로그 조회 페이지
└── [Deploy] Vercel 배포

Day 4+: 확장
├── [Backend] Time Currency
├── [Frontend] 랜딩 페이지
└── [Flutter] 클릭 이벤트 전송
```

---

## 우선순위 정리

| 순서 | 작업 | 예상 시간 | 영향도 |
|------|------|----------|--------|
| 1 | push_templates 테이블 | 30분 | 메시지 관리 편의성 |
| 2 | push_logs 테이블 | 30분 | 모든 분석의 기반 |
| 3 | 발송 시 로그 저장 | 1시간 | Phase 2-3 전제조건 |
| 4 | 클릭 이벤트 수집 | 1시간 | CTR 측정 가능 |
| 5 | **Next.js 프로젝트 초기화** | 1시간 | 웹 인프라 구축 |
| 6 | **어드민 대시보드** | 3시간 | 실시간 현황 파악 |
| 7 | **푸시 템플릿 CRUD** | 2시간 | 배포 없이 메시지 수정 |
| 8 | Anti-Nudge | 2시간 | 알림 피로도 감소 |
| 9 | Time Currency | 2시간 | 완독률 증가 |
| 10 | 랜딩 페이지 | 3시간 | 마케팅 |

---

## 체크리스트 (2025-12-25 업데이트)

### Phase 1: 푸시 관리 인프라
- [x] push_templates 마이그레이션
- [x] push_logs 마이그레이션
- [x] send-batch-nudge 로그 저장 추가
- [x] log-push-click Edge Function
- [ ] Flutter 클릭 이벤트 전송

### Phase 2: Anti-Nudge
- [ ] shouldSkipUser 로직
- [ ] anti_nudge 타입 추가 (책 변경 제안)

### Phase 3: Time Currency
- [ ] time_currency 타입 추가
- [ ] 남은 시간 계산 로직

### Phase 4: 웹 어드민
- [x] Next.js 프로젝트 초기화
- [x] shadcn/ui 설치 및 설정
- [x] Supabase 연동
- [ ] 관리자 인증 (middleware)
- [x] 대시보드 페이지 (/admin)
- [x] 푸시 템플릿 CRUD (/admin/push-templates)
- [x] 발송 로그 조회 (/admin/push-logs)
- [x] 테스트 발송 (/admin/test-push)
- [x] Vercel 배포

### Phase 5: 랜딩 페이지 (선택)
- [ ] 랜딩 페이지 디자인
- [ ] 앱스토어 링크
- [ ] 기능 소개

---

## 참고: 푸시 타입 전체 목록

| 타입 | 조건 | 우선순위 | 상태 |
|------|------|----------|------|
| `anti_nudge` | 3회 연속 미클릭 | 1 | ❌ |
| `inactive` | 3일+ 미독서 | 2 | ✅ |
| `deadline` | 목표일 3일 이내 | 3 | ✅ |
| `time_currency` | 30분 이내 완독 가능 | 4 | ❌ |
| `progress` | 80%+ 진행 | 5 | ✅ |
| `streak` | 연속 독서 중 | 6 | ✅ |
| `achievement` | 완독 | 7 | ✅ |
