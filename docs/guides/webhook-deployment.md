# RevenueCat Webhook Edge Function 배포 가이드

## 📋 개요

RevenueCat webhook을 수신하여 Supabase DB를 동기화하는 Edge Function을 배포하는 방법입니다.

---

## 🔧 사전 준비

### 1. Supabase CLI 설치 확인

```bash
supabase --version
```

설치되지 않았다면:
```bash
brew install supabase/tap/supabase
```

### 2. Supabase 프로젝트 연결

```bash
cd /path/to/book-golas
supabase link --project-ref reoiqefoymdsqzpbouxi
```

---

## 🚀 배포 단계

### Step 1: Edge Function 배포

```bash
cd /path/to/book-golas
supabase functions deploy revenuecat-webhook
```

**예상 출력:**
```
Deploying revenuecat-webhook (project ref: reoiqefoymdsqzpbouxi)
Bundled revenuecat-webhook size: 5.2 KB
Deployed revenuecat-webhook to https://reoiqefoymdsqzpbouxi.supabase.co/functions/v1/revenuecat-webhook
```

### Step 2: Webhook URL 복사

배포 완료 후 출력되는 URL을 복사합니다:
```
https://reoiqefoymdsqzpbouxi.supabase.co/functions/v1/revenuecat-webhook
```

### Step 3: RevenueCat Webhook 인증 키 생성

1. RevenueCat 대시보드 접속: https://app.revenuecat.com
2. 프로젝트 선택
3. **Settings** → **Integrations** → **Webhooks** 클릭
4. **Add Webhook** 버튼 클릭
5. **Authorization Header** 섹션에서 키 생성 (자동 생성됨)
6. 생성된 키 복사 (예: `sk_abc123...`)

### Step 4: Supabase Secret 설정

```bash
supabase secrets set REVENUECAT_WEBHOOK_AUTH_KEY=sk_abc123...
```

**주의**: `sk_abc123...` 부분을 실제 생성된 키로 교체하세요.

### Step 5: RevenueCat Webhook URL 설정

1. RevenueCat 대시보드에서 Webhook 설정 계속
2. **Webhook URL** 입력:
   ```
   https://reoiqefoymdsqzpbouxi.supabase.co/functions/v1/revenuecat-webhook
   ```
3. **Authorization Header** 입력:
   ```
   Bearer sk_abc123...
   ```
4. **Events to send** 선택:
   - ✅ Initial Purchase
   - ✅ Renewal
   - ✅ Cancellation
   - ✅ Expiration
   - ✅ Refund
   - ✅ Billing Issue
5. **Save** 버튼 클릭

---

## ✅ 배포 검증

### 1. Function 로그 확인

```bash
supabase functions logs revenuecat-webhook
```

### 2. Test Webhook 전송

RevenueCat 대시보드에서:
1. **Webhooks** 설정 페이지
2. 방금 생성한 Webhook 선택
3. **Send Test Event** 버튼 클릭
4. Event Type: `INITIAL_PURCHASE` 선택
5. **Send** 클릭

### 3. Supabase DB 확인

```sql
-- subscription_events 테이블 확인
SELECT * FROM subscription_events ORDER BY created_at DESC LIMIT 10;

-- users 테이블 구독 상태 확인
SELECT id, email, subscription_status, subscription_expires_at 
FROM users 
WHERE revenuecat_user_id IS NOT NULL;
```

---

## 🔄 재배포

코드 수정 후 재배포:

```bash
cd /path/to/book-golas
supabase functions deploy revenuecat-webhook
```

Secret은 재설정 불필요 (이미 저장됨).

---

## 🚨 문제 해결

### "Function not found" 에러

**원인**: 프로젝트 연결이 안 되어 있음

**해결**:
```bash
supabase link --project-ref reoiqefoymdsqzpbouxi
```

### "Unauthorized" 에러 (401)

**원인**: Authorization 헤더가 잘못됨

**해결**:
1. RevenueCat에서 Authorization Header 재확인
2. Supabase Secret 재설정:
   ```bash
   supabase secrets set REVENUECAT_WEBHOOK_AUTH_KEY=<new-key>
   ```

### "User not found" 에러 (404)

**원인**: `revenuecat_user_id`가 DB에 없음

**해결**:
1. 앱에서 RevenueCat 초기화 시 user ID 전달 확인
2. DB에서 user 확인:
   ```sql
   SELECT id, email, revenuecat_user_id FROM users WHERE id = '<user-id>';
   ```
3. 필요 시 수동 업데이트:
   ```sql
   UPDATE users SET revenuecat_user_id = '<revenuecat-id>' WHERE id = '<user-id>';
   ```

### Webhook이 호출되지 않음

**원인**: RevenueCat Webhook URL이 잘못됨

**해결**:
1. RevenueCat 대시보드에서 Webhook URL 재확인
2. URL 형식: `https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook`
3. HTTPS 필수 (HTTP 불가)

---

## 📊 모니터링

### Function 로그 실시간 확인

```bash
supabase functions logs revenuecat-webhook --follow
```

### Webhook 이벤트 통계

```sql
-- 이벤트 타입별 통계
SELECT event_type, COUNT(*) as count
FROM subscription_events
GROUP BY event_type
ORDER BY count DESC;

-- 최근 24시간 이벤트
SELECT event_type, user_id, created_at
FROM subscription_events
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## 📚 참고 자료

- [Supabase Edge Functions 문서](https://supabase.com/docs/guides/functions)
- [RevenueCat Webhooks 문서](https://www.revenuecat.com/docs/webhooks)
- [RevenueCat Event Types](https://www.revenuecat.com/docs/webhooks/event-types)

---

**작성일**: 2026-01-28  
**작성자**: Atlas (Orchestrator Agent)  
**버전**: 1.0
