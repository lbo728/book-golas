# 푸시 알림 작업 흐름 가이드

## 시스템 아키텍처

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐
│ GitHub Actions  │────▶│ Supabase Edge    │────▶│ Firebase    │────▶ 사용자 기기
│ (매 시간 실행)   │     │ Functions        │     │ FCM         │
└─────────────────┘     └──────────────────┘     └─────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │ Supabase DB      │
                        │ (fcm_tokens)     │
                        │ - preferred_hour │
                        │ - notification_  │
                        │   enabled        │
                        └──────────────────┘
```

## 사용자별 맞춤 시간 동작 원리

1. GitHub Actions가 **매 시간 정각**에 `send-batch-nudge` 호출
2. Edge Function에서 **현재 KST 시간** 계산
3. `fcm_tokens` 테이블에서 **preferred_hour = 현재시간** 인 사용자만 조회
4. 해당 사용자들에게만 스마트 넛지 푸시 전송

---

## Edge Functions 목록

| 함수명 | 용도 | 호출 방식 |
|--------|------|-----------|
| `send-fcm-push` | 단일 사용자에게 푸시 전송 | 직접 호출 |
| `send-smart-nudge` | 스마트 넛지 (비활성/마감임박/진척률) | 직접 호출 |
| `send-batch-nudge` | 시간대별 사용자 배치 처리 | GitHub Actions |

---

## 새 푸시 알림 만들기

### 1. 단순 메시지 푸시 (기존 함수 활용)

```bash
curl -X POST "https://your-project.supabase.co/functions/v1/send-fcm-push" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "사용자_FCM_토큰",
    "title": "알림 제목",
    "body": "알림 내용",
    "data": { "bookId": "xxx" }
  }'
```

### 2. 새로운 넛지 타입 추가

**Step 1**: `send-smart-nudge/index.ts` 수정
```typescript
// 기존 타입: inactive, deadline, progress, streak, achievement
// 새 타입 예시: "weekly_summary"
case "weekly_summary":
  title = "이번 주 독서 요약";
  body = `${pagesRead}페이지를 읽었어요!`;
  break;
```

**Step 2**: 배포
```bash
npx supabase functions deploy send-smart-nudge --project-ref YOUR_PROJECT_REF
```

### 3. 완전히 새로운 Edge Function 만들기

```bash
# 1. 함수 생성
npx supabase functions new my-new-push

# 2. 코드 작성
# supabase/functions/my-new-push/index.ts

# 3. 배포
npx supabase functions deploy my-new-push --project-ref YOUR_PROJECT_REF
```

---

## 테스트 방법

### 로컬 테스트
```bash
# Edge Function 로컬 실행
npx supabase functions serve

# 다른 터미널에서 호출
curl -X POST "http://localhost:54321/functions/v1/send-fcm-push" \
  -H "Content-Type: application/json" \
  -d '{ ... }'
```

### 프로덕션 테스트
- Supabase Dashboard > Edge Functions > 함수 선택 > Logs 확인
- GitHub Actions > Hourly Smart Nudge > Run workflow (수동 실행)

---

## 주요 파일 경로

```
book-golas/
├── supabase/
│   ├── functions/
│   │   ├── send-fcm-push/index.ts       # 단일 푸시
│   │   ├── send-smart-nudge/index.ts    # 개인 스마트 넛지
│   │   └── send-batch-nudge/index.ts    # 시간대별 배치 처리
│   └── migrations/
│       ├── 20251222_create_fcm_tokens.sql
│       └── 20251224_add_notification_settings.sql
├── .github/workflows/
│   └── daily-nudge.yml                  # 매 시간 스케줄러
└── app/lib/data/services/
    ├── fcm_service.dart                 # FCM 토큰 관리
    └── notification_settings_service.dart # 알림 설정 관리
```

---

## DB 스키마 (fcm_tokens)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | UUID | Primary Key |
| user_id | UUID | 사용자 ID (auth.users FK) |
| token | TEXT | FCM 토큰 |
| device_type | TEXT | ios / android / web |
| **preferred_hour** | INTEGER | 알림 받을 시간 (0-23, KST) |
| **notification_enabled** | BOOLEAN | 알림 활성화 여부 |
| created_at | TIMESTAMPTZ | 생성일 |
| updated_at | TIMESTAMPTZ | 수정일 |

---

## 환경 변수

### Supabase Secrets
| 변수명 | 용도 |
|--------|------|
| `FIREBASE_SERVICE_ACCOUNT` | FCM 인증용 서비스 계정 JSON |

### GitHub Secrets
| 변수명 | 용도 |
|--------|------|
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_SERVICE_ROLE_KEY` | 서비스 역할 키 |

---

## 스마트 넛지 타입

| 타입 | 조건 | 메시지 예시 |
|------|------|-------------|
| `inactive` | 3일 이상 미독서 | "3일째 독서를 안 했네요" |
| `deadline` | 목표일 3일 이내 | "완독까지 2일 남았습니다" |
| `progress` | 80% 이상 진행 | "90% 완독했습니다" |
| `streak` | 연속 독서 중 | "연속일이 5일입니다" |
| `achievement` | 목표 달성 | "완독을 축하합니다" |

---

## 앱에서 알림 설정 변경

```dart
// NotificationSettingsService 사용
final service = NotificationSettingsService();

// 설정 로드
await service.loadSettings();

// 알림 시간 변경 (0-23)
await service.updatePreferredHour(21); // 오후 9시

// 알림 ON/OFF
await service.updateNotificationEnabled(false);

// 사용 가능한 시간 목록
final hours = NotificationSettingsService.getAvailableHours();
// [{'hour': 0, 'label': '오전 12시'}, {'hour': 1, 'label': '오전 1시'}, ...]
```

---

## 배포 체크리스트

- [ ] Supabase Migration 실행 (`20251224_add_notification_settings.sql`)
- [ ] Edge Function 배포 (`send-batch-nudge`)
- [ ] GitHub Actions 확인 (매 시간 실행)
- [ ] 앱에서 NotificationSettingsService Provider 등록
- [ ] 마이페이지에 알림 설정 UI 추가
