# FCM 서버 푸시 알림 설정 가이드

서버에서 스마트 넛지 푸시 알림을 보내기 위한 설정 가이드입니다.

> **중요**: 기존 레거시 API(서버 키)가 아닌 **FCM HTTP v1 API**(서비스 계정)를 사용합니다.

---

## 1. Firebase 서비스 계정 키 생성

### 1.1 Firebase Console에서 서비스 계정 키 다운로드

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (book-golas)
3. **프로젝트 설정** (톱니바퀴 아이콘) → **서비스 계정** 탭
4. **새 비공개 키 생성** 버튼 클릭
5. JSON 파일 다운로드 (예: `book-golas-firebase-adminsdk-xxxxx.json`)

> ⚠️ **주의**: 이 JSON 파일은 절대 Git에 커밋하거나 공유하지 마세요!

### 1.2 다운로드한 JSON 파일 내용 확인

```json
{
  "type": "service_account",
  "project_id": "book-golas",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@book-golas.iam.gserviceaccount.com",
  "client_id": "...",
  ...
}
```

---

## 2. Supabase Secrets 설정

### 2.1 Supabase CLI 설치 (최초 1회)

```bash
npm install -g supabase
```

### 2.2 로그인 및 프로젝트 연결

```bash
supabase login
supabase link --project-ref enyxrgxixrnoazzgqyyd
```

### 2.3 서비스 계정 JSON 설정

JSON 파일 내용을 **한 줄로** 변환하여 설정:

```bash
# JSON 파일을 한 줄로 변환 (macOS/Linux)
SERVICE_ACCOUNT=$(cat path/to/book-golas-firebase-adminsdk-xxxxx.json | tr -d '\n')

# Supabase Secret 설정
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$SERVICE_ACCOUNT"
```

또는 직접 입력:
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"book-golas",...}'
```

### 2.4 설정 확인

```bash
supabase secrets list
```

`FIREBASE_SERVICE_ACCOUNT`가 목록에 있으면 성공입니다.

---

## 3. Edge Functions 배포

```bash
cd /path/to/book-golas

# 모든 Edge Functions 배포
supabase functions deploy send-fcm-push
supabase functions deploy send-smart-nudge
supabase functions deploy send-batch-nudge

# 배포 확인
supabase functions list
```

---

## 4. GitHub Secrets 설정 (스케줄러용)

1. GitHub 리포지토리 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. 다음 시크릿 추가:

| Name | Value |
|------|-------|
| `SUPABASE_URL` | `https://enyxrgxixrnoazzgqyyd.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard → Settings → API → service_role key |

---

## 5. 테스트

### 5.1 배치 넛지 테스트 (모든 사용자)

```bash
curl -X POST "https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-batch-nudge" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

### 5.2 개별 사용자 넛지 테스트

```bash
curl -X POST "https://enyxrgxixrnoazzgqyyd.supabase.co/functions/v1/send-smart-nudge" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userId": "사용자-UUID"}'
```

### 5.3 GitHub Actions 수동 실행

1. GitHub 리포지토리 → **Actions** 탭
2. **Daily Smart Nudge** 워크플로우 선택
3. **Run workflow** 클릭

---

## 6. 알림 스케줄

GitHub Actions가 자동 실행:

| UTC | KST | 설명 |
|-----|-----|------|
| 00:00 | 09:00 | 오전 넛지 |
| 12:00 | 21:00 | 저녁 넛지 |

---

## 7. 넛지 타입

| 타입 | 조건 | 메시지 |
|------|------|--------|
| `inactive` | 3일+ 독서 안 함 | "N일째 독서를 안 했네요..." |
| `deadline` | 목표일 3일 이하 | "목표 완료까지 N일 남았습니다" |
| `progress` | 진행률 80%+ | "목표 달성률이 N%입니다!" |
| `streak` | 연속일 1-7일 | "독서 연속일이 N일입니다!" |

---

## 트러블슈팅

### "FIREBASE_SERVICE_ACCOUNT not configured" 에러
- Supabase Secrets에 `FIREBASE_SERVICE_ACCOUNT`가 설정되었는지 확인
- Edge Function 재배포: `supabase functions deploy send-batch-nudge`

### "Invalid FIREBASE_SERVICE_ACCOUNT format" 에러
- JSON이 올바른 형식인지 확인
- 줄바꿈 없이 한 줄로 입력되었는지 확인

### "Failed to get access token" 에러
- 서비스 계정 JSON의 `private_key`가 올바른지 확인
- Firebase 프로젝트에서 Cloud Messaging API가 활성화되었는지 확인

### GitHub Actions 실패
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` 시크릿 확인
- Actions 탭에서 로그 확인

---

## 관련 파일

- `supabase/functions/send-batch-nudge/index.ts` - 배치 넛지 함수
- `supabase/functions/send-smart-nudge/index.ts` - 개별 스마트 넛지
- `supabase/functions/send-fcm-push/index.ts` - 기본 FCM 푸시
- `.github/workflows/daily-nudge.yml` - 스케줄러
