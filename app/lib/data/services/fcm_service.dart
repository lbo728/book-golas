import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // 알림 터치 콜백
  Function()? onNotificationTap;

  // 초기화
  Future<void> initialize() async {
    // 타임존 데이터 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // FCM 권한 요청
    await _requestPermission();

    // FCM 토큰 가져오기
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // 토큰 갱신 리스너
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      // TODO: 서버에 새 토큰 저장
      saveTokenToSupabase();
    });

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 메시지 처리는 main.dart에서 설정
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  // FCM 권한 요청
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // 로컬 알림으로 표시
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
      );
    }
  }

  // 알림 탭 처리
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('📱 알림 탭: ${response.payload}');
    // 콜백 호출 (현재 읽고 있는 책 페이지로 이동)
    onNotificationTap?.call();
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reading Reminder',
      channelDescription: '매일 독서 목표 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // 매일 정해진 시간에 알림 스케줄링
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    debugPrint('📅 알림 스케줄링: ${hour}시 ${minute}분');
    debugPrint('📅 다음 알림 시간: $scheduledTime');

    await _localNotifications.zonedSchedule(
      0, // notification id
      '오늘의 독서 목표',
      '오늘도 힘차게 독서를 시작해보아요!\n목표 페이지 수를 설정해주세요!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reading Reminder',
          channelDescription: '매일 독서 목표 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ 알림 스케줄링 완료');

    // SharedPreferences에 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', hour);
    await prefs.setInt('notification_minute', minute);
    await prefs.setBool('notification_enabled', true);
  }

  // 다음 알림 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // 알림 취소
  Future<void> cancelDailyNotification() async {
    await _localNotifications.cancel(0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', false);
  }

  // 알림 설정 상태 가져오기
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notification_enabled') ?? false,
      'hour': prefs.getInt('notification_hour') ?? 21,
      'minute': prefs.getInt('notification_minute') ?? 0,
    };
  }

  // 테스트용 알림 (30초 후)
  Future<void> scheduleTestNotification({int seconds = 30}) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _localNotifications.zonedSchedule(
      999, // 테스트용 notification id
      '🔔 테스트 알림',
      '알림이 정상적으로 작동합니다!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: '테스트 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('테스트 알림 예약 완료: ${seconds}초 후 ($scheduledTime)');
  }

  // 오후 9시 고정 알림 (독서 현황 업데이트 알림)
  Future<void> scheduleEveningReflectionNotification() async {
    const hour = 21; // 오후 9시
    const minute = 0;

    final scheduledTime = _nextInstanceOfTime(hour, minute);
    debugPrint('📅 오후 9시 알림 스케줄링');
    debugPrint('📅 다음 알림 시간: $scheduledTime');

    await _localNotifications.zonedSchedule(
      1, // notification id (사용자 설정 알림과 구분하기 위해 1 사용)
      '오늘 독서는 어땠나요?',
      '현황을 업데이트해주세요!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_reflection',
          'Evening Reading Reflection',
          channelDescription: '저녁 독서 현황 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ 오후 9시 알림 스케줄링 완료');
  }

  // FCM 토큰을 Supabase에 저장
  Future<void> saveTokenToSupabase() async {
    if (_fcmToken == null) {
      print('FCM token is null');
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      print('User not logged in');
      return;
    }

    try {
      // 디바이스 타입 결정
      String deviceType;
      if (kIsWeb) {
        deviceType = 'web';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else if (Platform.isAndroid) {
        deviceType = 'android';
      } else {
        deviceType = 'unknown';
      }

      // 기존 토큰 확인
      final existing = await supabase
          .from('fcm_tokens')
          .select()
          .eq('user_id', userId)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (existing != null) {
        // 토큰 업데이트
        await supabase.from('fcm_tokens').update({
          'token': _fcmToken,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        print('FCM token updated');
      } else {
        // 새 토큰 삽입
        await supabase.from('fcm_tokens').insert({
          'user_id': userId,
          'token': _fcmToken,
          'device_type': deviceType,
        });
        print('FCM token saved');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // 알림 권한 상태 확인
  Future<bool> isNotificationPermissionGranted() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // 권한 요청 (설정 화면 열기 안내)
  Future<void> requestNotificationPermission() async {
    final hasPermission = await isNotificationPermissionGranted();

    if (!hasPermission) {
      // iOS에서는 한 번 거부하면 앱 설정에서 수동으로 켜야 함
      // 사용자에게 안내 다이얼로그 표시
      print('Please enable notifications in Settings');
    }
  }
}
