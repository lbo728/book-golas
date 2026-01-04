import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:book_golas/ui/reading_chart/widgets/reading_chart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:book_golas/ui/book_list/widgets/book_list_screen.dart';
import 'package:book_golas/ui/core/widgets/liquid_glass_bottom_bar.dart';
import 'package:book_golas/ui/core/widgets/liquid_glass_search_overlay.dart';
import 'package:book_golas/ui/calendar/widgets/calendar_screen.dart';
import 'package:book_golas/ui/reading_start/widgets/reading_start_screen.dart';
import 'package:book_golas/config/app_config.dart';
import 'package:book_golas/data/repositories/book_repository.dart';
import 'package:book_golas/data/repositories/auth_repository.dart';
import 'package:book_golas/data/repositories/notification_settings_repository.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/ui/home/view_model/home_view_model.dart';
import 'package:book_golas/ui/book_list/view_model/book_list_view_model.dart';
import 'package:book_golas/ui/core/view_model/theme_view_model.dart';
import 'package:book_golas/ui/core/view_model/auth_view_model.dart';
import 'package:book_golas/ui/core/view_model/notification_settings_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/services/auth_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/notification_settings_service.dart';
import 'data/services/reading_progress_service.dart';
import 'ui/auth/widgets/login_screen.dart';
import 'ui/auth/widgets/my_page_screen.dart';
import 'domain/models/book.dart';
import 'ui/book_detail/book_detail_screen.dart';

// 백그라운드 메시지 핸들러 (main 함수 밖에 정의)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📨 백그라운드 메시지 수신: ${message.notification?.title}');
  debugPrint('📦 데이터 페이로드: ${message.data}');

  // 백그라운드에서도 데이터 페이로드를 활용할 수 있음
  // 예: 로컬 알림 스케줄링, 데이터 저장 등
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  Future<void> _init() async {
    try {
      debugPrint('🚀 초기화 시작');

      // .env 파일 로드
      debugPrint('📄 .env 파일 로드 시작');
      try {
        await dotenv.load(fileName: ".env");
        debugPrint('✅ .env 파일 로드 완료');
      } catch (e) {
        debugPrint('⚠️ .env 파일 로드 실패: $e');
        // .env 파일이 없어도 계속 진행 (환경변수로 대체 가능)
      }

      debugPrint('🔑 API 키 검증 시작');
      try {
        AppConfig.validateApiKeys();
        debugPrint('✅ API 키 검증 완료');
      } catch (e) {
        debugPrint('⚠️ API 키 검증 실패: $e');
      }

      // Firebase 초기화 (이미 초기화되어 있으면 스킵)
      debugPrint('🔥 Firebase 초기화 시작');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase 초기화 완료');
      } else {
        debugPrint('✅ Firebase 이미 초기화됨');
      }

      // 백그라운드 메시지 핸들러 등록
      debugPrint('📱 FCM 백그라운드 핸들러 등록');
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      debugPrint('✅ FCM 백그라운드 핸들러 등록 완료');

      // Supabase 초기화
      debugPrint('🗄️ Supabase 초기화 시작');
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      debugPrint('✅ Supabase 초기화 성공');

      debugPrint('🎉 모든 초기화 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 초기화 중 에러 발생: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (context, snapshot) {
        // 에러 발생 시
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        '초기화 중 오류가 발생했습니다',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 초기화 중
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('앱을 초기화하는 중...'),
                  ],
                ),
              ),
            ),
          );
        }

        // 초기화 완료
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // === Services (Pure) ===
        Provider<BookService>(
          create: (_) => BookService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<NotificationSettingsService>(
          create: (_) => NotificationSettingsService(),
        ),
        Provider<ReadingProgressService>(
          create: (_) => ReadingProgressService(),
        ),
        // === Repositories ===
        Provider<BookRepository>(
          create: (context) => BookRepositoryImpl(
            context.read<BookService>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            context.read<AuthService>(),
          ),
        ),
        Provider<NotificationSettingsRepository>(
          create: (context) => NotificationSettingsRepositoryImpl(
            context.read<NotificationSettingsService>(),
          ),
        ),
        // === ViewModels ===
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<BookRepository>(),
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<NotificationSettingsViewModel>(
          create: (context) => NotificationSettingsViewModel(
            context.read<NotificationSettingsRepository>(),
          ),
        ),
        ChangeNotifierProvider<BookListViewModel>(
          create: (_) => BookListViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, child) {
          return MaterialApp(
            title: 'LitGoal',
            debugShowCheckedModeBanner: false,
            themeMode: themeViewModel.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5B7FFF),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[50],
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5B7FFF),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7FFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5B7FFF),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5B7FFF),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5B7FFF),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7FFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5B7FFF),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isAuthenticated) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // FCM 초기화를 첫 프레임 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FCMService().initialize();
      debugPrint('FCM 서비스 초기화 완료');

      // 알림 터치 시 책 상세 페이지로 이동 (딥링크 지원)
      FCMService().onNotificationTap = (Map<String, dynamic>? payload) async {
        debugPrint('📚 알림 터치: payload=$payload');

        try {
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser?.id;

          if (userId == null) {
            debugPrint('❌ 사용자 로그인되지 않음');
            return;
          }

          Book? book;
          final String? bookId = payload?['bookId'];

          // 1. bookId가 있으면 해당 책 조회
          if (bookId != null) {
            debugPrint('📖 딥링크: 특정 책 조회 (bookId: $bookId)');
            final response = await supabase
                .from('books')
                .select()
                .eq('id', bookId)
                .eq('user_id', userId)
                .maybeSingle();

            if (response != null) {
              book = Book.fromJson(response);
              debugPrint('✅ 책 찾음: ${book.title}');
            } else {
              debugPrint('⚠️ bookId로 책을 찾지 못함, 기본 로직 실행');
            }
          }

          // 2. bookId가 없거나 책을 찾지 못한 경우: 현재 읽고 있는 책 조회
          if (book == null) {
            debugPrint('📖 기본 로직: 현재 읽고 있는 책 조회');
            final response = await supabase
                .from('books')
                .select()
                .eq('user_id', userId)
                .order('updated_at', ascending: false);

            if (response.isEmpty) {
              debugPrint('❌ 책이 없습니다');
              return;
            }

            // 완독하지 않은 책 찾기
            final unfinishedBooks = (response as List)
                .where((bookData) =>
                    (bookData['current_page'] as int) <
                    (bookData['total_pages'] as int))
                .toList();

            if (unfinishedBooks.isEmpty) {
              debugPrint('❌ 현재 읽고 있는 책이 없습니다');
              if (mounted) {
                setState(() {
                  _selectedIndex = 0;
                });
              }
              return;
            }

            book = Book.fromJson(unfinishedBooks.first);
          }

          // 3. 책 상세 페이지로 이동
          if (mounted) {
            final targetBook = book; // non-null 보장
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookDetailScreen(book: targetBook),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ 책 조회 중 에러: $e');
        }
      };

      // 로그인된 사용자의 토큰을 Supabase에 저장
      FCMService().saveTokenToSupabase();

      // 오후 9시 고정 알림 스케줄링
      FCMService().scheduleEveningReflectionNotification();
    });
  }

  List<Widget> get _pages => [
        const BookListScreen(),
        const ReadingChartScreen(),
        const CalendarScreen(),
        const MyPageScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSearchTap(Offset searchButtonPosition, double searchButtonSize) {
    // HIG: 검색 필드에 초점을 맞춘 상태로 시작 (키보드 즉시 표시)
    showLiquidGlassSearchOverlay(
      context,
      searchButtonPosition: searchButtonPosition,
      searchButtonSize: searchButtonSize,
      onSearch: (query) {
        // 검색 결과로 ReadingStartScreen 이동 (title 파라미터로 검색어 전달)
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReadingStartScreen(title: query),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_selectedIndex],
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      extendBody: true,
      bottomNavigationBar: LiquidGlassBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
        onSearchTap: _onSearchTap,
      ),
    );
  }
}
