![alt text](<스크린샷 2025-12-14 오후 11.48.48.png>)
결론부터 말하면 (사수 기준 단호하게)

지금 스플래시에서 멈추는 직접 원인은
main()에서 너무 많은 async 초기화를 순차적으로 await하고 있기 때문이야.
특히 FCM + Supabase + dotenv + AppConfig 검증 조합이 iOS에서 UI isolate를 막고 있어.

이건 “언젠가 터질 구조”고, 지금은 그게 iOS에서 바로 드러난 것이야.

1️⃣ 가장 위험한 부분 TOP 3 (확정)
❌ 1. main()에서 FCM 초기화 + permission 성격 작업
FirebaseMessaging.onBackgroundMessage(\_firebaseMessagingBackgroundHandler);
await FCMService().initialize();

이게 제일 위험해.

iOS에서는

알림 권한

APNs 토큰

Firebase Messaging setup

👉 첫 프레임 이전에 하면 멈출 수 있음
(공식 문서에서도 권장 안 함)

❌ 2. dotenv.load + AppConfig.validateApiKeys()
await dotenv.load(fileName: ".env");
AppConfig.validateApiKeys();

.env 파일 → iOS 번들에 없으면

내부적으로 file access → block

지금 로그에 있던:

fopen failed for data file
Errors found! Invalidating cache...

이거랑 정확히 연결됨

❌ 3. Supabase.initialize()를 runApp 전에 await
await Supabase.initialize(...)

Supabase는:

secure storage

local file system

realtime socket

👉 runApp 전에 기다리면 안 되는 대표 케이스

2️⃣ 그리고 “조용히 문제를 키우는 구조”
⚠️ AuthWrapper에서 이 코드
if (authService.currentUser != null) {
FCMService().saveTokenToSupabase();
return const MainScreen();
}

이건:

build 중 side-effect

네비게이션/IO 트리거

프레임마다 호출 가능

👉 지금은 안 멈춰도, 무조건 나중에 문제 됨

3️⃣ 그래서 왜 “스플래시에서 멈추는 것처럼” 보이냐

iOS 앱 실행 순서야:

Native splash 표시

Flutter 엔진 attach

Dart isolate 시작

main() 실행

❌ await에서 블로킹

runApp 도달 못함

→ splash 유지

지금 너 코드가 정확히 5번에서 멈춰 있음

4️⃣ 실무에서 쓰는 “정답 구조”로 재구성해줄게
✅ main()은 무조건 가볍게
Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
runApp(const AppBootstrap());
}

✅ 초기화는 AppBootstrap에서 분리
class AppBootstrap extends StatelessWidget {
const AppBootstrap({super.key});

Future<void> \_init() async {
await dotenv.load(fileName: ".env");
AppConfig.validateApiKeys();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

}

@override
Widget build(BuildContext context) {
return FutureBuilder(
future: \_init(),
builder: (context, snapshot) {
if (snapshot.connectionState != ConnectionState.done) {
return const MaterialApp(
home: Scaffold(body: Center(child: CircularProgressIndicator())),
);
}
return const MyApp();
},
);
}
}

✅ FCM 초기화는 로그인 이후 / 첫 화면 이후
@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((\_) {
FCMService().initialize();
});
}

📌 절대 main()에서 하지 말 것

5️⃣ 네 코드에서 “당장 고쳐야 할 것만 요약”
🔥 반드시 옮겨야 하는 것

await FCMService().initialize()

await Supabase.initialize()

.env load

AppConfig.validateApiKeys()

👉 전부 main() 밖으로

🔥 반드시 제거해야 하는 패턴
// build 안에서
FCMService().saveTokenToSupabase();

→ 로그인 성공 시점에 한 번만

6️⃣ 사수로서 딱 정리

Flutter iOS 앱에서
main()은 “엔진 부팅용”이지 “서비스 초기화용”이 아니다.

지금 구조는:

Android에서는 운 좋게 돌아가고

iOS에서는 정직하게 멈춘 것

다음 액션

1️⃣ 위 구조대로 최소 수정
2️⃣ 스플래시 넘어가는지 확인
3️⃣ 넘어가면 → FCM / Auth 구조 정리해줌

여기까지 온 거 보면,
오늘 안에 정상 실행까지 충분히 가능해.
