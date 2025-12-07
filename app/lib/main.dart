import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:lit_goal/ui/reading/widgets/reading_chart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:lit_goal/ui/book/widgets/book_list_screen.dart';
import 'package:lit_goal/ui/reading/widgets/reading_start_screen.dart';
import 'package:lit_goal/config/app_config.dart';
import 'package:lit_goal/data/repositories/book_repository.dart';
import 'package:lit_goal/data/services/book_service.dart';
import 'package:lit_goal/ui/home/view_model/home_view_model.dart';
import 'package:lit_goal/ui/core/view_model/theme_view_model.dart';
import 'data/services/auth_service.dart';
import 'ui/auth/widgets/login_screen.dart';
import 'ui/auth/widgets/my_page_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  AppConfig.validateApiKeys();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  ).then((_) {
    debugPrint('Supabase 초기화 성공');
  }).catchError((error) {
    debugPrint('Supabase 초기화 실패: $error');
  });

  runApp(const MyApp());
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
