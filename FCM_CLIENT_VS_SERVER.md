# 클라이언트 vs 서버: FCM 푸시 알림 전송

> **질문**: 클라이언트에서 FCM 푸시를 보낼 수 있나요? 꼭 서버에서 해야 하나요?

---

## 🚫 클라이언트에서 직접 FCM 푸시 전송은 권장하지 않습니다

### 보안 문제

```dart
// ❌ 절대 하지 마세요!
final serverKey = "AAAA..."; // Firebase 서버 키
await http.post(
  Uri.parse('https://fcm.googleapis.com/fcm/send'),
  headers: {
    'Authorization': 'key=$serverKey', // 서버 키 노출!
  },
  body: jsonEncode({
    'to': fcmToken,
    'notification': {'title': '알림', 'body': '내용'},
  }),
);
```

**문제점:**
1. **서버 키 노출**: 앱을 디컴파일하면 서버 키가 노출됨
2. **무단 사용**: 누구나 다른 사용자에게 스팸 알림을 보낼 수 있음
3. **Firebase 정책 위반**: Firebase는 서버 키를 서버 사이드에서만 사용하도록 권장

---

## ✅ 대안 1: 로컬 알림 사용 (현재 구현됨)

현재 앱은 이미 **로컬 알림**을 사용하고 있어서 클라이언트에서 직접 알림을 보낼 수 있습니다!

### 로컬 알림의 장점

```dart
// ✅ 이미 구현되어 있음 - 서버 키 불필요!
FCMService().scheduleDailyNotification(
  hour: 21,
  minute: 0,
);
```

- ✅ **서버 키 불필요** (보안 문제 없음)
- ✅ **인터넷 연결 불필요**
- ✅ **배터리 효율적**
- ✅ **앱이 종료되어도 작동**
- ✅ **클라이언트에서 완전히 제어 가능**

### 사용 예시

```dart
// 매일 정해진 시간에 알림
await FCMService().scheduleDailyNotification(
  hour: 9,
  minute: 0,
);

// 즉시 알림 표시
await FCMService()._showLocalNotification(
  title: '알림 제목',
  body: '알림 내용',
);

// 테스트 알림 (30초 후)
await FCMService().scheduleTestNotification(seconds: 30);
```

---

## ✅ 대안 2: 서버 푸시 (필요한 경우만)

서버 푸시는 다음 경우에만 필요합니다:

### 서버 푸시가 필요한 경우

1. **다른 사용자에게 알림 전송**
   - 친구 초대
   - 메시지 수신
   - 추천 알림

2. **서버에서 계산/트리거하는 알림**
   - 목표 달성 축하 (서버에서 계산)
   - 관리자 공지
   - 이벤트 알림

3. **앱이 삭제되어도 알림 전송**
   - 중요 공지
   - 계정 관련 알림

### 서버 푸시 사용 예시

```dart
// 서버에서 푸시 전송 (Supabase Edge Function 사용)
final supabase = Supabase.instance.client;
await supabase.functions.invoke(
  'send-fcm-push',
  body: {
    'userId': targetUserId,
    'title': '친구 초대',
    'body': '친구가 당신을 초대했습니다!',
  },
);
```

---

## 📊 비교표

| 기능 | 로컬 알림 | 서버 푸시 |
|------|----------|----------|
| **서버 키 필요** | ❌ | ✅ |
| **인터넷 연결** | ❌ | ✅ |
| **보안** | ✅ 안전 | ⚠️ 서버에서 관리 필요 |
| **배터리** | ✅ 효율적 | ⚠️ 네트워크 사용 |
| **다른 사용자에게 전송** | ❌ | ✅ |
| **서버 제어** | ❌ | ✅ |
| **앱 삭제 후 알림** | ❌ | ✅ |
| **구현 복잡도** | ✅ 간단 | ⚠️ 서버 필요 |

---

## 💡 현재 앱의 권장 사용법

### 현재 구현 (로컬 알림) - 계속 사용 ✅

```dart
// 매일 오전 9시 알림
FCMService().scheduleDailyNotification(hour: 9, minute: 0);

// 매일 오후 9시 알림
FCMService().scheduleEveningReflectionNotification();
```

**이유:**
- ✅ 서버 인프라 불필요
- ✅ 보안 문제 없음
- ✅ 사용자가 직접 제어 가능
- ✅ 대부분의 일일 알림에 충분

### 향후 확장 시 (서버 푸시) - 선택사항

```dart
// 친구 기능 추가 시
await supabase.functions.invoke('send-fcm-push', body: {
  'userId': friendUserId,
  'title': '새로운 친구 요청',
  'body': '친구가 당신을 추가했습니다!',
});
```

---

## 🎯 결론

### 질문: 클라이언트에서 FCM 푸시를 보낼 수 있나요?

**답변:**
- ❌ **FCM 서버 푸시**: 클라이언트에서 직접 보내면 안 됨 (보안 문제)
- ✅ **로컬 알림**: 클라이언트에서 직접 보낼 수 있음 (현재 구현됨)

### 질문: 꼭 서버에서 해야 하나요?

**답변:**
- **일반적인 일일 알림**: ❌ 서버 불필요 → 로컬 알림 사용
- **다른 사용자에게 알림**: ✅ 서버 필요 → 서버 푸시 사용
- **서버 트리거 알림**: ✅ 서버 필요 → 서버 푸시 사용

### 현재 앱의 경우

현재 앱의 **매일 독서 알림**은 **로컬 알림으로 충분**합니다. 서버 푸시는 향후 확장 기능(친구 기능, 관리자 공지 등)을 위해 준비해둔 것입니다.

---

## 📚 참고

- [로컬 알림 구현](app/lib/data/services/fcm_service.dart)
- [서버 푸시 구현](supabase/functions/send-fcm-push/index.ts)
- [Firebase 보안 가이드](https://firebase.google.com/docs/cloud-messaging/server#choose)





