import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// App title
  ///
  /// In ko, this message translates to:
  /// **'북골라스'**
  String get appTitle;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// Confirm button
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// Change button
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get commonChange;

  /// Complete button
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get commonComplete;

  /// Close button
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// Retry button
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// Next button
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// Skip button
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get commonSkip;

  /// Start button
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get commonStart;

  /// Home navigation
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// Library navigation
  ///
  /// In ko, this message translates to:
  /// **'서재'**
  String get navLibrary;

  /// Stats navigation
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get navStats;

  /// Calendar navigation
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navCalendar;

  /// Book count with unit
  ///
  /// In ko, this message translates to:
  /// **'{count}권'**
  String booksCount(int count);

  /// Day count with unit
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String daysCount(int count);

  /// Page count with unit
  ///
  /// In ko, this message translates to:
  /// **'{count}페이지'**
  String pagesCount(int count);

  /// Monday short
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// Tuesday short
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// Wednesday short
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// Thursday short
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// Friday short
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// Saturday short
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// Sunday short
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// AM
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get timeAm;

  /// PM
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get timePm;

  /// Year unit
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get unitYear;

  /// Month unit
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get unitMonth;

  /// Day unit
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get unitDay;

  /// Hour unit
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get unitHour;

  /// Minute unit
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get unitMinute;

  /// Reading status
  ///
  /// In ko, this message translates to:
  /// **'독서 중'**
  String get statusReading;

  /// Planned to read status
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get statusPlanned;

  /// Completed status
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get statusCompleted;

  /// Reread status
  ///
  /// In ko, this message translates to:
  /// **'다시 읽을 책'**
  String get statusReread;

  /// Urgent priority
  ///
  /// In ko, this message translates to:
  /// **'긴급'**
  String get priorityUrgent;

  /// High priority
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get priorityHigh;

  /// Medium priority
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get priorityMedium;

  /// Low priority
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get priorityLow;

  /// Highlight type
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get contentTypeHighlight;

  /// Memo type
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get contentTypeMemo;

  /// Photo type
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get contentTypePhoto;

  /// Language setting label
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageSettingLabel;

  /// Book list title on home screen
  ///
  /// In ko, this message translates to:
  /// **'독서 목록'**
  String get homeBookList;

  /// No reading books message
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서가 없습니다. 먼저 책을 등록해주세요.'**
  String get homeNoReadingBooks;

  /// No reading books short message
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서가 없습니다'**
  String get homeNoReadingBooksShort;

  /// View all books button
  ///
  /// In ko, this message translates to:
  /// **'전체 독서 보기'**
  String get homeViewAllBooks;

  /// View reading only button
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서만 보기'**
  String get homeViewReadingOnly;

  /// Switched to view all books message
  ///
  /// In ko, this message translates to:
  /// **'전체 독서 보기로 전환되었습니다.'**
  String get homeViewAllBooksMessage;

  /// Switched to view reading books message
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서 보기로 전환되었습니다.'**
  String get homeViewReadingMessage;

  /// Reading tab
  ///
  /// In ko, this message translates to:
  /// **'독서 중'**
  String get bookListTabReading;

  /// Planned tab
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get bookListTabPlanned;

  /// Completed tab
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get bookListTabCompleted;

  /// Reread tab
  ///
  /// In ko, this message translates to:
  /// **'다시 읽을 책'**
  String get bookListTabReread;

  /// All tab
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get bookListTabAll;

  /// All filter
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get bookListFilterAll;

  /// Error loading data
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get bookListErrorLoadFailed;

  /// Network check message
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get bookListErrorNetworkCheck;

  /// No reading books
  ///
  /// In ko, this message translates to:
  /// **'현재 읽고 있는 책이 없습니다'**
  String get bookListEmptyReading;

  /// No planned books
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정인 책이 없습니다'**
  String get bookListEmptyPlanned;

  /// No completed books
  ///
  /// In ko, this message translates to:
  /// **'완독한 책이 없습니다'**
  String get bookListEmptyCompleted;

  /// No paused books
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가는 책이 없습니다'**
  String get bookListEmptyPaused;

  /// No reading started
  ///
  /// In ko, this message translates to:
  /// **'아직 시작한 독서가 없습니다'**
  String get bookListEmptyAll;

  /// Record tab
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get bookDetailTabRecord;

  /// History tab
  ///
  /// In ko, this message translates to:
  /// **'히스토리'**
  String get bookDetailTabHistory;

  /// Review tab
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get bookDetailTabReview;

  /// Detail tab
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get bookDetailTabDetail;

  /// Start date label
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get bookDetailStartDate;

  /// Target date label
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get bookDetailTargetDate;

  /// Review written status
  ///
  /// In ko, this message translates to:
  /// **'작성됨'**
  String get bookDetailReviewWritten;

  /// Review not written status
  ///
  /// In ko, this message translates to:
  /// **'아직 작성되지 않음'**
  String get bookDetailReviewNotWritten;

  /// Achieved legend
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get bookDetailLegendAchieved;

  /// Missed legend
  ///
  /// In ko, this message translates to:
  /// **'미달성'**
  String get bookDetailLegendMissed;

  /// Scheduled legend
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get bookDetailLegendScheduled;

  /// Later button
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get bookDetailLater;

  /// My library title
  ///
  /// In ko, this message translates to:
  /// **'나의 서재'**
  String get myLibraryTitle;

  /// Reading tab in my library
  ///
  /// In ko, this message translates to:
  /// **'독서'**
  String get myLibraryTabReading;

  /// Review tab in my library
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get myLibraryTabReview;

  /// Record tab in my library
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get myLibraryTabRecord;

  /// Search hint text
  ///
  /// In ko, this message translates to:
  /// **'제목, 저자로 검색'**
  String get myLibrarySearchHint;

  /// No search results message
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get myLibraryNoSearchResults;

  /// No books registered message
  ///
  /// In ko, this message translates to:
  /// **'등록된 책이 없습니다'**
  String get myLibraryNoBooks;

  /// No books with reviews message
  ///
  /// In ko, this message translates to:
  /// **'독후감이 있는 책이 없습니다'**
  String get myLibraryNoReviewBooks;

  /// No records message
  ///
  /// In ko, this message translates to:
  /// **'기록이 없습니다'**
  String get myLibraryNoRecords;

  /// AI search all records button
  ///
  /// In ko, this message translates to:
  /// **'모든 기록에서 AI 검색'**
  String get myLibraryAiSearch;

  /// All filter option
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get myLibraryFilterAll;

  /// Highlight filter option
  ///
  /// In ko, this message translates to:
  /// **'✨ 하이라이트'**
  String get myLibraryFilterHighlight;

  /// Memo filter option
  ///
  /// In ko, this message translates to:
  /// **'📝 메모'**
  String get myLibraryFilterMemo;

  /// Photo filter option
  ///
  /// In ko, this message translates to:
  /// **'📷 사진'**
  String get myLibraryFilterPhoto;

  /// Reading chart title
  ///
  /// In ko, this message translates to:
  /// **'나의 독서 상태'**
  String get chartTitle;

  /// Overview tab
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get chartTabOverview;

  /// Analysis tab
  ///
  /// In ko, this message translates to:
  /// **'분석'**
  String get chartTabAnalysis;

  /// Activity tab
  ///
  /// In ko, this message translates to:
  /// **'활동'**
  String get chartTabActivity;

  /// Daily period
  ///
  /// In ko, this message translates to:
  /// **'일별'**
  String get chartPeriodDaily;

  /// Weekly period
  ///
  /// In ko, this message translates to:
  /// **'주별'**
  String get chartPeriodWeekly;

  /// Monthly period
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get chartPeriodMonthly;

  /// Daily average
  ///
  /// In ko, this message translates to:
  /// **'일평균'**
  String get chartDailyAverage;

  /// Increase/decrease
  ///
  /// In ko, this message translates to:
  /// **'증감'**
  String get chartIncrease;

  /// Less
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get chartLess;

  /// More
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get chartMore;

  /// Error loading data
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get chartErrorLoadFailed;

  /// Retry button
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get chartErrorRetry;

  /// Total pages read
  ///
  /// In ko, this message translates to:
  /// **'총 읽은 페이지'**
  String get chartTotalPages;

  /// Daily average pages
  ///
  /// In ko, this message translates to:
  /// **'일평균'**
  String get chartDailyAvgPages;

  /// Best record
  ///
  /// In ko, this message translates to:
  /// **'최고 기록'**
  String get chartMaxDaily;

  /// Lowest record
  ///
  /// In ko, this message translates to:
  /// **'최저 기록'**
  String get chartMinDaily;

  /// Consecutive reading days
  ///
  /// In ko, this message translates to:
  /// **'연속 독서'**
  String get chartConsecutiveDays;

  /// Today's goal
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표'**
  String get chartTodayGoal;

  /// Reading progress chart
  ///
  /// In ko, this message translates to:
  /// **'독서 진행 차트'**
  String get chartReadingProgress;

  /// Daily pages
  ///
  /// In ko, this message translates to:
  /// **'일별 페이지'**
  String get chartDailyPages;

  /// Cumulative pages
  ///
  /// In ko, this message translates to:
  /// **'누적 페이지'**
  String get chartCumulativePages;

  /// No data yet
  ///
  /// In ko, this message translates to:
  /// **'아직 데이터가 없어요'**
  String get chartNoData;

  /// Pages
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get chartDailyReadPages;

  /// Reading statistics
  ///
  /// In ko, this message translates to:
  /// **'독서 통계'**
  String get chartReadingStats;

  /// AI insight
  ///
  /// In ko, this message translates to:
  /// **'AI 인사이트'**
  String get chartAiInsight;

  /// Completion rate
  ///
  /// In ko, this message translates to:
  /// **'완독률'**
  String get chartCompletionRate;

  /// Records/highlights
  ///
  /// In ko, this message translates to:
  /// **'기록/하이라이트'**
  String get chartRecordsHighlights;

  /// Genre analysis
  ///
  /// In ko, this message translates to:
  /// **'장르 분석'**
  String get chartGenreAnalysis;

  /// No reading records
  ///
  /// In ko, this message translates to:
  /// **'읽은 기록이 없어요'**
  String get chartNoReadingRecords;

  /// My page title
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get myPageTitle;

  /// Settings
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get myPageSettings;

  /// Change avatar
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get myPageChangeAvatar;

  /// Logout
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get myPageLogout;

  /// Delete account
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get myPageDeleteAccount;

  /// Delete account confirmation message
  ///
  /// In ko, this message translates to:
  /// **'정말로 계정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.'**
  String get myPageDeleteAccountConfirm;

  /// Account deleted successfully
  ///
  /// In ko, this message translates to:
  /// **'계정이 성공적으로 삭제되었습니다.'**
  String get myPageDeleteAccountSuccess;

  /// Failed to delete account
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제에 실패했습니다. 다시 시도해주세요.'**
  String get myPageDeleteAccountFailed;

  /// Error message when deleting account
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String myPageDeleteAccountError(String error);

  /// Set notification time
  ///
  /// In ko, this message translates to:
  /// **'알림 시간 설정'**
  String get myPageNotificationTimeTitle;

  /// No nickname
  ///
  /// In ko, this message translates to:
  /// **'닉네임 없음'**
  String get myPageNoNickname;

  /// Nickname hint
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get myPageNicknameHint;

  /// Dark mode
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get myPageDarkMode;

  /// Daily reading goal notification
  ///
  /// In ko, this message translates to:
  /// **'매일 독서 목표 알림'**
  String get myPageDailyReadingNotification;

  /// Notification time display
  ///
  /// In ko, this message translates to:
  /// **'매일 {time}에 알림'**
  String myPageNotificationTime(String time);

  /// No notifications
  ///
  /// In ko, this message translates to:
  /// **'알림을 받지 않습니다'**
  String get myPageNoNotification;

  /// Notifications enabled
  ///
  /// In ko, this message translates to:
  /// **'알림이 활성화되었습니다'**
  String get myPageNotificationEnabled;

  /// Notifications disabled
  ///
  /// In ko, this message translates to:
  /// **'알림이 비활성화되었습니다'**
  String get myPageNotificationDisabled;

  /// Failed to change notification settings
  ///
  /// In ko, this message translates to:
  /// **'알림 설정 변경에 실패했습니다'**
  String get myPageNotificationChangeFailed;

  /// Test notification
  ///
  /// In ko, this message translates to:
  /// **'테스트 알림 (30초 후)'**
  String get myPageTestNotification;

  /// Test notification sent message
  ///
  /// In ko, this message translates to:
  /// **'30초 후에 테스트 알림이 발송됩니다!'**
  String get myPageTestNotificationSent;

  /// Avatar changed
  ///
  /// In ko, this message translates to:
  /// **'프로필 이미지가 변경되었습니다'**
  String get myPageAvatarChanged;

  /// Error message when changing avatar
  ///
  /// In ko, this message translates to:
  /// **'프로필 이미지 변경 실패: {error}'**
  String myPageAvatarChangeFailed(String error);

  /// App name on login screen
  ///
  /// In ko, this message translates to:
  /// **'북골라스'**
  String get loginAppName;

  /// Email label
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get loginEmailLabel;

  /// Password label
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get loginPasswordLabel;

  /// Nickname label
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get loginNicknameLabel;

  /// Or divider
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get loginOrDivider;

  /// Login button
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginButton;

  /// Signup button
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get loginSignupButton;

  /// Sign in description
  ///
  /// In ko, this message translates to:
  /// **'오늘도 한 페이지,\n당신의 독서를 응원합니다'**
  String get loginDescriptionSignIn;

  /// Sign up description
  ///
  /// In ko, this message translates to:
  /// **'북골라스와 함께\n독서 습관을 시작해보세요'**
  String get loginDescriptionSignUp;

  /// Forgot password description
  ///
  /// In ko, this message translates to:
  /// **'가입하신 이메일로\n재설정 링크를 보내드립니다'**
  String get loginDescriptionForgotPassword;

  /// Email hint
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get loginEmailHint;

  /// Password hint
  ///
  /// In ko, this message translates to:
  /// **'6자 이상 입력해주세요'**
  String get loginPasswordHint;

  /// Nickname hint
  ///
  /// In ko, this message translates to:
  /// **'앱에서 사용할 이름'**
  String get loginNicknameHint;

  /// Email required error
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get loginEmailRequired;

  /// Invalid email error
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 주소를 입력해주세요'**
  String get loginEmailInvalid;

  /// Password required error
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get loginPasswordRequired;

  /// Password too short error
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다'**
  String get loginPasswordTooShort;

  /// Nickname required error
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get loginNicknameRequired;

  /// Forgot password button
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get loginForgotPassword;

  /// No account sign up button
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? 회원가입'**
  String get loginNoAccount;

  /// Have account login button
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인'**
  String get loginHaveAccount;

  /// Back to sign in button
  ///
  /// In ko, this message translates to:
  /// **'로그인으로 돌아가기'**
  String get loginBackToSignIn;

  /// Save email checkbox
  ///
  /// In ko, this message translates to:
  /// **'이메일 저장'**
  String get loginSaveEmail;

  /// Sign up success message
  ///
  /// In ko, this message translates to:
  /// **'회원가입이 완료되었습니다. 이메일을 확인해주세요.'**
  String get loginSignupSuccess;

  /// Reset password success message
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일을 보냈습니다.'**
  String get loginResetPasswordSuccess;

  /// Unexpected error message
  ///
  /// In ko, this message translates to:
  /// **'예상치 못한 오류가 발생했습니다.'**
  String get loginUnexpectedError;

  /// Invalid credentials error
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 올바르지 않습니다.'**
  String get loginErrorInvalidCredentials;

  /// Email not confirmed error
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 완료되지 않았습니다.'**
  String get loginErrorEmailNotConfirmed;

  /// Email already registered error
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 이메일입니다.'**
  String get loginErrorEmailAlreadyRegistered;

  /// Password too short error
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다.'**
  String get loginErrorPasswordTooShort;

  /// Review title
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get reviewTitle;

  /// Save review
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get reviewSave;

  /// Replace review
  ///
  /// In ko, this message translates to:
  /// **'대체하기'**
  String get reviewReplace;

  /// Exit review
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get reviewExit;

  /// Draft loaded message
  ///
  /// In ko, this message translates to:
  /// **'임시 저장된 내용을 불러왔습니다.'**
  String get reviewDraftLoaded;

  /// Review copied message
  ///
  /// In ko, this message translates to:
  /// **'독후감이 복사되었습니다.'**
  String get reviewCopied;

  /// Book not found error
  ///
  /// In ko, this message translates to:
  /// **'책 정보를 찾을 수 없습니다.'**
  String get reviewBookNotFound;

  /// Save failed error
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다. 다시 시도해주세요.'**
  String get reviewSaveFailed;

  /// Save error
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류가 발생했습니다.'**
  String get reviewSaveError;

  /// Replace confirmation message
  ///
  /// In ko, this message translates to:
  /// **'현재 작성 중인 내용이 있습니다.\nAI 초안으로 대체하시겠습니까?'**
  String get reviewReplaceConfirm;

  /// Replace button
  ///
  /// In ko, this message translates to:
  /// **'대체하기'**
  String get reviewReplaceButton;

  /// AI draft generated message
  ///
  /// In ko, this message translates to:
  /// **'AI 초안이 생성되었습니다. 자유롭게 수정해주세요!'**
  String get reviewAIDraftGenerated;

  /// AI draft failed error
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성에 실패했습니다. 다시 시도해주세요.'**
  String get reviewAIDraftFailed;

  /// AI draft error
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성 중 오류가 발생했습니다.'**
  String get reviewAIDraftError;

  /// Save complete message
  ///
  /// In ko, this message translates to:
  /// **'독후감이 저장되었습니다!'**
  String get reviewSaveComplete;

  /// Save complete detail message
  ///
  /// In ko, this message translates to:
  /// **'저장한 독후감은 \'독후감\' 탭 또는\n\'나의 서재 > 독후감\'에서 확인할 수 있어요.'**
  String get reviewSaveCompleteMessage;

  /// Exit confirmation message
  ///
  /// In ko, this message translates to:
  /// **'작성 중단하고 나가시겠어요?'**
  String get reviewExitConfirm;

  /// Exit detail message
  ///
  /// In ko, this message translates to:
  /// **'작성 중이던 독후감은 임시 저장됩니다.'**
  String get reviewExitMessage;

  /// Review text field hint
  ///
  /// In ko, this message translates to:
  /// **'이 책을 읽고 느낀 점, 인상 깊었던 부분, 나에게 준 영감 등을 자유롭게 적어보세요.'**
  String get reviewHint;

  /// Set start date
  ///
  /// In ko, this message translates to:
  /// **'시작일 지정'**
  String get readingStartSetDate;

  /// Undetermined
  ///
  /// In ko, this message translates to:
  /// **'미정'**
  String get readingStartUndetermined;

  /// Start reading title
  ///
  /// In ko, this message translates to:
  /// **'독서 시작하기'**
  String get readingStartTitle;

  /// Start reading subtitle
  ///
  /// In ko, this message translates to:
  /// **'독서를 시작할 책을 검색해보세요.'**
  String get readingStartSubtitle;

  /// No search results
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get readingStartNoResults;

  /// Analyzing reading patterns
  ///
  /// In ko, this message translates to:
  /// **'독서 패턴을 분석하고 있어요...'**
  String get readingStartAnalyzing;

  /// AI personalized recommendation
  ///
  /// In ko, this message translates to:
  /// **'AI 맞춤 추천'**
  String get readingStartAiRecommendation;

  /// AI recommendation description
  ///
  /// In ko, this message translates to:
  /// **'{userName}님의 독서 패턴을 분석하여 추천하는 책들이에요'**
  String readingStartAiRecommendationDesc(String userName);

  /// Search hint
  ///
  /// In ko, this message translates to:
  /// **'책 제목을 입력해주세요.'**
  String get readingStartSearchHint;

  /// Selection complete
  ///
  /// In ko, this message translates to:
  /// **'선택 완료'**
  String get readingStartSelectionComplete;

  /// Confirm button
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get readingStartConfirm;

  /// Total pages display
  ///
  /// In ko, this message translates to:
  /// **'{totalPages}페이지'**
  String readingStartPages(int totalPages);

  /// Planned reading start date
  ///
  /// In ko, this message translates to:
  /// **'독서 시작 예정일'**
  String get readingStartPlannedDate;

  /// Starting today
  ///
  /// In ko, this message translates to:
  /// **'오늘부터 시작합니다'**
  String get readingStartToday;

  /// Target deadline
  ///
  /// In ko, this message translates to:
  /// **'목표 마감일'**
  String get readingStartTargetDate;

  /// Target date note
  ///
  /// In ko, this message translates to:
  /// **'독서 시작 후에도 목표일을 변경할 수 있습니다'**
  String get readingStartTargetDateNote;

  /// Save error
  ///
  /// In ko, this message translates to:
  /// **'독서 정보 저장에 실패했습니다.'**
  String get readingStartSaveError;

  /// Reserve reading
  ///
  /// In ko, this message translates to:
  /// **'독서 예약하기'**
  String get readingStartReserve;

  /// Begin reading
  ///
  /// In ko, this message translates to:
  /// **'독서 시작'**
  String get readingStartBegin;

  /// Opacity
  ///
  /// In ko, this message translates to:
  /// **'투명도'**
  String get dialogOpacity;

  /// Thickness
  ///
  /// In ko, this message translates to:
  /// **'굵기'**
  String get dialogThickness;

  /// Take photo
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get dialogTakePhoto;

  /// Replace image
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get dialogReplaceImage;

  /// View full
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get dialogViewFull;

  /// Copy
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get dialogCopy;

  /// Edit
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get dialogEdit;

  /// Saved message
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get dialogSaved;

  /// Saving message
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get dialogSaving;

  /// Upload
  ///
  /// In ko, this message translates to:
  /// **'업로드'**
  String get dialogUpload;

  /// Select
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get dialogSelect;

  /// Apply
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get dialogApply;

  /// Extract
  ///
  /// In ko, this message translates to:
  /// **'추출하기'**
  String get dialogExtract;

  /// Okay
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get dialogOkay;

  /// Extract it
  ///
  /// In ko, this message translates to:
  /// **'추출할게요'**
  String get dialogExtractIt;

  /// Think about it
  ///
  /// In ko, this message translates to:
  /// **'고민해볼게요'**
  String get dialogThinkAboutIt;

  /// Novel genre
  ///
  /// In ko, this message translates to:
  /// **'소설'**
  String get genreNovel;

  /// Literature genre
  ///
  /// In ko, this message translates to:
  /// **'문학'**
  String get genreLiterature;

  /// Self-help genre
  ///
  /// In ko, this message translates to:
  /// **'자기계발'**
  String get genreSelfHelp;

  /// Business genre
  ///
  /// In ko, this message translates to:
  /// **'경제경영'**
  String get genreBusiness;

  /// Humanities genre
  ///
  /// In ko, this message translates to:
  /// **'인문학'**
  String get genreHumanities;

  /// Science genre
  ///
  /// In ko, this message translates to:
  /// **'과학'**
  String get genreScience;

  /// History genre
  ///
  /// In ko, this message translates to:
  /// **'역사'**
  String get genreHistory;

  /// Essay genre
  ///
  /// In ko, this message translates to:
  /// **'에세이'**
  String get genreEssay;

  /// Poetry genre
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get genrePoetry;

  /// Comic genre
  ///
  /// In ko, this message translates to:
  /// **'만화'**
  String get genreComic;

  /// Uncategorized genre
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get genreUncategorized;

  /// Initialization failed error
  ///
  /// In ko, this message translates to:
  /// **'초기화 중 오류가 발생했습니다'**
  String get errorInitFailed;

  /// Load failed error
  ///
  /// In ko, this message translates to:
  /// **'불러오기 실패'**
  String get errorLoadFailed;

  /// No records error
  ///
  /// In ko, this message translates to:
  /// **'기록이 없습니다'**
  String get errorNoRecords;

  /// Initializing app message
  ///
  /// In ko, this message translates to:
  /// **'앱을 초기화하는 중...'**
  String get loadingInit;

  /// Month selection title
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get calendarMonthSelect;

  /// Pages read on this day
  ///
  /// In ko, this message translates to:
  /// **'{count}페이지 읽음'**
  String calendarPagesRead(int count);

  /// Completed reading badge
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get calendarCompleted;

  /// Onboarding screen title 1
  ///
  /// In ko, this message translates to:
  /// **'나만의 독서 여정을 기록하세요'**
  String get onboardingTitle1;

  /// Onboarding screen description 1
  ///
  /// In ko, this message translates to:
  /// **'읽고 싶은 책을 등록하고,\n독서 목표와 진행 상황을 한눈에 관리하세요.'**
  String get onboardingDescription1;

  /// Onboarding screen title 2
  ///
  /// In ko, this message translates to:
  /// **'AI로 독서 기록을 검색하세요'**
  String get onboardingTitle2;

  /// Onboarding screen description 2
  ///
  /// In ko, this message translates to:
  /// **'기억나는 내용을 검색하면\nAI가 관련된 메모와 책을 찾아드립니다.'**
  String get onboardingDescription2;

  /// Onboarding screen title 3
  ///
  /// In ko, this message translates to:
  /// **'다음 읽을 책을 추천받으세요'**
  String get onboardingTitle3;

  /// Onboarding screen description 3
  ///
  /// In ko, this message translates to:
  /// **'지금까지 읽은 책을 바탕으로\n당신의 취향에 맞는 책을 AI가 추천합니다.'**
  String get onboardingDescription3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
