import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:book_golas/ui/reading/widgets/reading_chart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:book_golas/ui/book/widgets/book_list_screen.dart';
import 'package:book_golas/ui/reading/widgets/reading_start_screen.dart';
import 'package:book_golas/config/app_config.dart';
import 'package:book_golas/data/repositories/book_repository.dart';
import 'package:book_golas/data/services/book_service.dart';
import 'package:book_golas/ui/home/view_model/home_view_model.dart';
import 'package:book_golas/ui/core/view_model/theme_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/services/auth_service.dart';
import 'data/services/fcm_service.dart';
import 'ui/auth/widgets/login_screen.dart';
import 'ui/auth/widgets/my_page_screen.dart';
import 'domain/models/book.dart';
import 'ui/book/widgets/book_detail_screen_redesigned.dart';

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
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        '초기화 중 오류가 발생했습니다',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        Provider<BookService>(
          create: (_) => BookService(),
        ),
        Provider<BookRepository>(
          create: (context) => BookRepositoryImpl(
            context.read<BookService>(),
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<BookRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()),
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
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[50],
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
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
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.currentUser != null) {
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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDropdownOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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
                builder: (context) => BookDetailScreenRedesigned(book: targetBook),
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
        const BookListScreen(),
        const ReadingChartScreen(),
        const MyPageScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildLiquidGlassBottomBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.88),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // 슬라이딩 배경 인디케이터
            Positioned(
              top: 4,
              bottom: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 부모 컨테이너의 너비를 가져오기 위해 MediaQuery 사용
                  final containerWidth = MediaQuery.of(context).size.width - 32 - 24; // margin + padding
                  final itemWidth = containerWidth / 3;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                      itemWidth * _selectedIndex + 4,
                      0,
                      0,
                    ),
                    width: itemWidth - 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  );
                },
              ),
            ),
            // 네비게이션 아이템들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, '홈'),
                _buildNavItem(1, CupertinoIcons.chart_bar_square_fill, CupertinoIcons.chart_bar_square, '독서 상태'),
                _buildNavItem(2, CupertinoIcons.person_crop_circle_fill, CupertinoIcons.person_crop_circle, '마이페이지'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_isDropdownOpen) {
            _onItemTapped(index);
            _animationController.forward(from: 0.0);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          body: _pages[_selectedIndex],
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          extendBody: true,
          bottomNavigationBar: _buildLiquidGlassBottomBar(),
        ),
        if (_isDropdownOpen)
          AnimatedOpacity(
            opacity: _isDropdownOpen ? 1.0 : 0.0,
            duration: const Duration(
              milliseconds: 200,
            ),
            curve: Curves.easeInOut,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDropdownOpen = false;
                });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color.fromRGBO(0, 0, 0, 0.3),
              ),
            ),
          ),
        Positioned(
          bottom: 108,
          right: 16,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedOpacity(
                opacity: _isDropdownOpen ? 1.0 : 0.0,
                duration: const Duration(
                  milliseconds: 200,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 64,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          offset: Offset(0, 4),
                          blurRadius: 24,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDropdownOpen = false;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReadingStartScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 16,
                                top: 8,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.book,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    '새 독서 시작',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: isDark ? Colors.white : Colors.black,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // GestureDetector(
                          //   onTap: () {
                          //     setState(() {
                          //       _isDropdownOpen = false;
                          //     });
                          //   },
                          //   child: Container(
                          //     padding: const EdgeInsets.only(
                          //       left: 12,
                          //       right: 16,
                          //       top: 8,
                          //       bottom: 8,
                          //     ),
                          //     child: const Row(
                          //       children: [
                          //         Icon(
                          //           Icons.camera_alt,
                          //           color: Colors.black,
                          //         ),
                          //         SizedBox(
                          //           width: 8,
                          //         ),
                          //         Text(
                          //           '사진 추가',
                          //           style: TextStyle(
                          //             fontSize: 16,
                          //             fontWeight: FontWeight.w400,
                          //             color: Colors.black,
                          //             decoration: TextDecoration.none,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FloatingActionButton(
                backgroundColor: Colors.blue,
                elevation: 2,
                shape: const CircleBorder(),
                onPressed: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                  });
                },
                child: Icon(
                  _isDropdownOpen ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
