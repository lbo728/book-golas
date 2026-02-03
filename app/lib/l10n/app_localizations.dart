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

  /// Highlight content type
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get contentTypeHighlight;

  /// Memo type
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get contentTypeMemo;

  /// Photo content type
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get contentTypePhoto;

  /// Language setting label
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageSettingLabel;

  /// Book list label on home screen
  ///
  /// In ko, this message translates to:
  /// **'독서 목록'**
  String get homeBookList;

  /// Reading tab in book list
  ///
  /// In ko, this message translates to:
  /// **'독서 중'**
  String get bookListTabReading;

  /// Planned tab in book list
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get bookListTabPlanned;

  /// Completed tab in book list
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get bookListTabCompleted;

  /// Reread tab in book list
  ///
  /// In ko, this message translates to:
  /// **'다시 읽을 책'**
  String get bookListTabReread;

  /// All tab in book list
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get bookListTabAll;

  /// All filter in book list
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get bookListFilterAll;

  /// Record tab in book detail
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get bookDetailTabRecord;

  /// History tab in book detail
  ///
  /// In ko, this message translates to:
  /// **'히스토리'**
  String get bookDetailTabHistory;

  /// Review tab in book detail
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get bookDetailTabReview;

  /// Detail tab in book detail
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get bookDetailTabDetail;

  /// Start date label in book detail
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get bookDetailStartDate;

  /// Target date label in book detail
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get bookDetailTargetDate;

  /// Review written status in book detail
  ///
  /// In ko, this message translates to:
  /// **'작성됨'**
  String get bookDetailReviewWritten;

  /// Review not written status in book detail
  ///
  /// In ko, this message translates to:
  /// **'아직 작성되지 않음'**
  String get bookDetailReviewNotWritten;

  /// Achieved legend in book detail
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get bookDetailLegendAchieved;

  /// Missed legend in book detail
  ///
  /// In ko, this message translates to:
  /// **'미달성'**
  String get bookDetailLegendMissed;

  /// Scheduled legend in book detail
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get bookDetailLegendScheduled;

  /// Later button in book detail
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get bookDetailLater;

  /// My library screen title
  ///
  /// In ko, this message translates to:
  /// **'나의 서재'**
  String get myLibraryTitle;

  /// Reading chart screen title
  ///
  /// In ko, this message translates to:
  /// **'나의 독서 상태'**
  String get chartTitle;

  /// Overview tab in reading chart
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get chartTabOverview;

  /// Analysis tab in reading chart
  ///
  /// In ko, this message translates to:
  /// **'분석'**
  String get chartTabAnalysis;

  /// Activity tab in reading chart
  ///
  /// In ko, this message translates to:
  /// **'활동'**
  String get chartTabActivity;

  /// Daily period in reading chart
  ///
  /// In ko, this message translates to:
  /// **'일별'**
  String get chartPeriodDaily;

  /// Weekly period in reading chart
  ///
  /// In ko, this message translates to:
  /// **'주별'**
  String get chartPeriodWeekly;

  /// Monthly period in reading chart
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get chartPeriodMonthly;

  /// Daily average in reading chart
  ///
  /// In ko, this message translates to:
  /// **'일평균'**
  String get chartDailyAverage;

  /// Increase/decrease in reading chart
  ///
  /// In ko, this message translates to:
  /// **'증감'**
  String get chartIncrease;

  /// Less in reading chart
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get chartLess;

  /// More in reading chart
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get chartMore;

  /// My page screen title
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get myPageTitle;

  /// Settings in my page
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get myPageSettings;

  /// Change avatar in my page
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get myPageChangeAvatar;

  /// Logout in my page
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get myPageLogout;

  /// App name in login screen
  ///
  /// In ko, this message translates to:
  /// **'북골라스'**
  String get loginAppName;

  /// Email label in login screen
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get loginEmailLabel;

  /// Password label in login screen
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get loginPasswordLabel;

  /// Nickname label in login screen
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get loginNicknameLabel;

  /// Or divider in login screen
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get loginOrDivider;

  /// Login button in login screen
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginButton;

  /// Sign up button in login screen
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get loginSignupButton;

  /// Description text for sign in mode
  ///
  /// In ko, this message translates to:
  /// **'오늘도 한 페이지,\n당신의 독서를 응원합니다'**
  String get loginDescriptionSignIn;

  /// Description text for sign up mode
  ///
  /// In ko, this message translates to:
  /// **'북골라스와 함께\n독서 습관을 시작해보세요'**
  String get loginDescriptionSignUp;

  /// Description text for forgot password mode
  ///
  /// In ko, this message translates to:
  /// **'가입하신 이메일로\n재설정 링크를 보내드립니다'**
  String get loginDescriptionForgotPassword;

  /// Email required validation message
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get loginEmailRequired;

  /// Email invalid validation message
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 주소를 입력해주세요'**
  String get loginEmailInvalid;

  /// Password hint text
  ///
  /// In ko, this message translates to:
  /// **'6자 이상 입력해주세요'**
  String get loginPasswordHint;

  /// Password required validation message
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get loginPasswordRequired;

  /// Password minimum length validation message
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다'**
  String get loginPasswordMinLength;

  /// Nickname hint text
  ///
  /// In ko, this message translates to:
  /// **'앱에서 사용할 이름'**
  String get loginNicknameHint;

  /// Nickname required validation message
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get loginNicknameRequired;

  /// Forgot password button text
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get loginForgotPasswordButton;

  /// Sign up prompt text
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? 회원가입'**
  String get loginSignupPrompt;

  /// Sign in prompt text
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인'**
  String get loginSigninPrompt;

  /// Back to login button text
  ///
  /// In ko, this message translates to:
  /// **'로그인으로 돌아가기'**
  String get loginBackButton;

  /// Save email checkbox label
  ///
  /// In ko, this message translates to:
  /// **'이메일 저장'**
  String get loginSaveEmail;

  /// Reset password button text
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일 보내기'**
  String get loginResetPasswordButton;

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

  /// Invalid credentials error message
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 올바르지 않습니다.'**
  String get loginInvalidCredentials;

  /// Email not confirmed error message
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 완료되지 않았습니다.'**
  String get loginEmailNotConfirmed;

  /// Email already registered error message
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 이메일입니다.'**
  String get loginEmailAlreadyRegistered;

  /// Password too short error message
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다.'**
  String get loginPasswordTooShort;

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

  /// Email input hint
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력하세요'**
  String get loginEmailHint;

  /// Forgot password link
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get loginForgotPassword;

  /// No account prompt
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get loginNoAccount;

  /// Have account prompt
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요?'**
  String get loginHaveAccount;

  /// Back to sign in button
  ///
  /// In ko, this message translates to:
  /// **'로그인으로 돌아가기'**
  String get loginBackToSignIn;

  /// Delete account button
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get myPageDeleteAccount;

  /// Delete account error with error message
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제에 실패했습니다: {error}'**
  String myPageDeleteAccountError(String error);

  /// Notification time setting with time
  ///
  /// In ko, this message translates to:
  /// **'{time}에 알림 설정됨'**
  String myPageNotificationTime(String time);

  /// Notification change failed
  ///
  /// In ko, this message translates to:
  /// **'알림 설정 변경에 실패했습니다'**
  String get myPageNotificationChangeFailed;

  /// Avatar changed message
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 변경되었습니다'**
  String get myPageAvatarChanged;

  /// Avatar change failed with error message
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 변경에 실패했습니다: {error}'**
  String myPageAvatarChangeFailed(String error);

  /// Nickname input hint
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get myPageNicknameHint;

  /// Korean language
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// English language
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language change confirmation title
  ///
  /// In ko, this message translates to:
  /// **'언어 변경'**
  String get languageChangeConfirmTitle;

  /// Language change confirmation message with language name
  ///
  /// In ko, this message translates to:
  /// **'{language}(으)로 언어를 변경하시겠습니까?'**
  String languageChangeConfirmMessage(String language);

  /// No notification label
  ///
  /// In ko, this message translates to:
  /// **'알림 없음'**
  String get myPageNoNotification;

  /// Notifications enabled label
  ///
  /// In ko, this message translates to:
  /// **'알림 활성화됨'**
  String get myPageNotificationEnabled;

  /// Book review screen title
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get reviewTitle;

  /// Save button in review screen
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get reviewSave;

  /// Replace button in review screen
  ///
  /// In ko, this message translates to:
  /// **'대체하기'**
  String get reviewReplace;

  /// Exit button in review screen
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get reviewExit;

  /// Set start date in reading start screen
  ///
  /// In ko, this message translates to:
  /// **'시작일 지정'**
  String get readingStartSetDate;

  /// Undetermined in reading start screen
  ///
  /// In ko, this message translates to:
  /// **'미정'**
  String get readingStartUndetermined;

  /// Opacity in dialog
  ///
  /// In ko, this message translates to:
  /// **'투명도'**
  String get dialogOpacity;

  /// Thickness in dialog
  ///
  /// In ko, this message translates to:
  /// **'굵기'**
  String get dialogThickness;

  /// Take photo in dialog
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get dialogTakePhoto;

  /// Replace image in dialog
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get dialogReplaceImage;

  /// View full in dialog
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get dialogViewFull;

  /// Copy in dialog
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get dialogCopy;

  /// Edit in dialog
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get dialogEdit;

  /// Saved in dialog
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get dialogSaved;

  /// Saving in dialog
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get dialogSaving;

  /// Upload in dialog
  ///
  /// In ko, this message translates to:
  /// **'업로드'**
  String get dialogUpload;

  /// Select in dialog
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get dialogSelect;

  /// Apply in dialog
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get dialogApply;

  /// Extract in dialog
  ///
  /// In ko, this message translates to:
  /// **'추출하기'**
  String get dialogExtract;

  /// Okay in dialog
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get dialogOkay;

  /// Extract it in dialog
  ///
  /// In ko, this message translates to:
  /// **'추출할게요'**
  String get dialogExtractIt;

  /// Think about it in dialog
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

  /// App initialization loading message
  ///
  /// In ko, this message translates to:
  /// **'앱을 초기화하는 중...'**
  String get loadingInit;

  /// Message when no reading books available
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서가 없습니다. 먼저 책을 등록해주세요.'**
  String get homeNoReadingBooks;

  /// Short message when no reading books available
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서가 없습니다'**
  String get homeNoReadingBooksShort;

  /// Message when switched to all books view
  ///
  /// In ko, this message translates to:
  /// **'전체 독서 보기로 전환되었습니다.'**
  String get homeSwitchToAllBooks;

  /// Message when switched to reading detail view
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서 보기로 전환되었습니다.'**
  String get homeSwitchToReadingDetail;

  /// Toggle button label for all books view
  ///
  /// In ko, this message translates to:
  /// **'전체 독서 보기'**
  String get homeToggleAllBooks;

  /// Toggle button label for reading only view
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 독서만 보기'**
  String get homeToggleReadingOnly;

  /// Error message when book list fails to load
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get bookListErrorLoadFailed;

  /// Error message to check network connection
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get bookListErrorCheckNetwork;

  /// Empty state message for planned books
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정인 책이 없습니다'**
  String get bookListEmptyPlanned;

  /// Empty state message for paused books
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가는 책이 없습니다'**
  String get bookListEmptyPaused;

  /// Empty state message for all books
  ///
  /// In ko, this message translates to:
  /// **'아직 시작한 독서가 없습니다'**
  String get bookListEmptyAll;

  /// Empty state message for reading books
  ///
  /// In ko, this message translates to:
  /// **'현재 읽고 있는 책이 없습니다'**
  String get bookListEmptyReading;

  /// Empty state message for completed books
  ///
  /// In ko, this message translates to:
  /// **'완독한 책이 없습니다'**
  String get bookListEmptyCompleted;

  /// Empty state message for a specific status
  ///
  /// In ko, this message translates to:
  /// **'{status} 책이 없습니다'**
  String bookListEmptyStatus(String status);

  /// Book detail screen title
  ///
  /// In ko, this message translates to:
  /// **'독서 상세'**
  String get bookDetailScreenTitle;

  /// Congratulations on finishing
  ///
  /// In ko, this message translates to:
  /// **'완독을 축하합니다!'**
  String get bookDetailCompletionCongrats;

  /// Prompt to write review after completion
  ///
  /// In ko, this message translates to:
  /// **'독서의 여운이 남아있을 때\n독후감을 작성해보시겠어요?'**
  String get bookDetailCompletionPrompt;

  /// Write review button
  ///
  /// In ko, this message translates to:
  /// **'독후감 쓰러가기'**
  String get bookDetailWriteReview;

  /// Edit review button
  ///
  /// In ko, this message translates to:
  /// **'독후감 수정하기'**
  String get bookDetailEditReview;

  /// Review description for new review
  ///
  /// In ko, this message translates to:
  /// **'책을 읽고 느낀 점을 기록해보세요'**
  String get bookDetailReviewDescription;

  /// Review description for existing review
  ///
  /// In ko, this message translates to:
  /// **'작성한 독후감을 다시 확인하고 수정해보세요'**
  String get bookDetailReviewEditDescription;

  /// Continue reading button
  ///
  /// In ko, this message translates to:
  /// **'독서 다시 시작하기'**
  String get bookDetailContinueReading;

  /// Continue reading description
  ///
  /// In ko, this message translates to:
  /// **'이번에도 몰입해서 독서 목표를 달성해보아요!'**
  String get bookDetailContinueReadingDesc;

  /// Restart reading button
  ///
  /// In ko, this message translates to:
  /// **'이어서 독서하기'**
  String get bookDetailRestartReading;

  /// Planned start date label
  ///
  /// In ko, this message translates to:
  /// **'독서 시작 예정'**
  String get bookDetailPlannedStartDate;

  /// Start date undetermined
  ///
  /// In ko, this message translates to:
  /// **'시작일 미정'**
  String get bookDetailPlannedStartDateUndetermined;

  /// Plan updated message
  ///
  /// In ko, this message translates to:
  /// **'독서 계획이 수정되었습니다'**
  String get bookDetailPlanUpdated;

  /// Paused reading position
  ///
  /// In ko, this message translates to:
  /// **'중단 위치: {currentPage}p / {totalPages}p ({percentage}%)'**
  String bookDetailPausedPosition(
      int currentPage, int totalPages, int percentage);

  /// Attempt start message
  ///
  /// In ko, this message translates to:
  /// **'{attemptNumber}번째 도전을 시작합니다'**
  String bookDetailAttemptStart(int attemptNumber);

  /// Attempt start with days left
  ///
  /// In ko, this message translates to:
  /// **'{attemptNumber}번째 도전 시작! D-{daysLeft}'**
  String bookDetailAttemptStartWithDays(int attemptNumber, int daysLeft);

  /// Attempt start encouragement
  ///
  /// In ko, this message translates to:
  /// **'{attemptNumber}번째 도전 시작! 화이팅!'**
  String bookDetailAttemptStartEncouragement(int attemptNumber);

  /// Goal achieved message
  ///
  /// In ko, this message translates to:
  /// **'목표 달성!'**
  String get bookDetailGoalAchieved;

  /// Pages read message with remaining
  ///
  /// In ko, this message translates to:
  /// **'+{pagesRead} 페이지! 오늘 목표까지 {pagesLeft}p 남음'**
  String bookDetailPagesRead(int pagesRead, int pagesLeft);

  /// Pages reached message
  ///
  /// In ko, this message translates to:
  /// **'+{pagesRead} 페이지! {currentPage}p 도달'**
  String bookDetailPagesReached(int pagesRead, int currentPage);

  /// Record saved message
  ///
  /// In ko, this message translates to:
  /// **'기록이 저장되었습니다'**
  String get bookDetailRecordSaved;

  /// Upload failed title
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패'**
  String get bookDetailUploadFailed;

  /// Network error message
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요.\n연결 상태가 양호하면 다시 시도해주세요.'**
  String get bookDetailNetworkError;

  /// Upload error message
  ///
  /// In ko, this message translates to:
  /// **'기록을 저장하는 중 오류가 발생했습니다.\n업로드 버튼을 눌러 다시 시도해주세요.'**
  String get bookDetailUploadError;

  /// Image replaced message
  ///
  /// In ko, this message translates to:
  /// **'이미지가 교체되었습니다'**
  String get bookDetailImageReplaced;

  /// Delete reading confirmation title
  ///
  /// In ko, this message translates to:
  /// **'독서를 삭제하시겠습니까?'**
  String get bookDetailDeleteConfirmTitle;

  /// Delete reading confirmation message
  ///
  /// In ko, this message translates to:
  /// **'삭제된 독서 기록은 복구할 수 없습니다.'**
  String get bookDetailDeleteConfirmMessage;

  /// Reading deleted message
  ///
  /// In ko, this message translates to:
  /// **'독서가 삭제되었습니다'**
  String get bookDetailDeleteSuccess;

  /// Delete image confirmation title
  ///
  /// In ko, this message translates to:
  /// **'삭제하시겠습니까?'**
  String get bookDetailDeleteImageConfirmTitle;

  /// Delete image confirmation message
  ///
  /// In ko, this message translates to:
  /// **'이 항목을 삭제하면 복구할 수 없습니다.'**
  String get bookDetailDeleteImageConfirmMessage;

  /// Items deleted message
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목이 삭제되었습니다'**
  String bookDetailItemsDeleted(int count);

  /// Pause reading message
  ///
  /// In ko, this message translates to:
  /// **'독서를 잠시 쉬어갑니다. 언제든 다시 시작하세요!'**
  String get bookDetailPauseReadingMessage;

  /// New journey start message
  ///
  /// In ko, this message translates to:
  /// **'새로운 독서 여정을 시작합니다! 화이팅! 📚'**
  String get bookDetailNewJourneyStart;

  /// Note structure button
  ///
  /// In ko, this message translates to:
  /// **'노트 구조화'**
  String get bookDetailNoteStructure;

  /// Urgent priority
  ///
  /// In ko, this message translates to:
  /// **'긴급'**
  String get bookDetailPriorityUrgent;

  /// High priority
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get bookDetailPriorityHigh;

  /// Medium priority
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get bookDetailPriorityMedium;

  /// Low priority
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get bookDetailPriorityLow;

  /// Error message
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get bookDetailError;

  /// Select month dialog title
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get calendarMonthSelect;

  /// Cancel button in calendar
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get calendarCancel;

  /// Confirm button in calendar
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get calendarConfirm;

  /// Pages read on a day
  ///
  /// In ko, this message translates to:
  /// **'{pages}페이지 읽음'**
  String calendarPagesRead(int pages);

  /// Completed badge in calendar
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get calendarCompleted;

  /// Select month label
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get calendarSelectMonth;

  /// All filter in calendar
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get calendarFilterAll;

  /// Reading filter in calendar
  ///
  /// In ko, this message translates to:
  /// **'읽고 있는 책'**
  String get calendarFilterReading;

  /// Completed filter in calendar
  ///
  /// In ko, this message translates to:
  /// **'완독한 책'**
  String get calendarFilterCompleted;

  /// Error loading calendar data
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오는데 실패했습니다'**
  String get calendarLoadError;

  /// Delete account dialog title
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get myPageDeleteAccountTitle;

  /// Delete account confirmation message
  ///
  /// In ko, this message translates to:
  /// **'정말로 계정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.'**
  String get myPageDeleteAccountConfirm;

  /// Account deleted successfully message
  ///
  /// In ko, this message translates to:
  /// **'계정이 성공적으로 삭제되었습니다.'**
  String get myPageDeleteAccountSuccess;

  /// Account deletion failed message
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제에 실패했습니다. 다시 시도해주세요.'**
  String get myPageDeleteAccountFailed;

  /// Error occurred message
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String myPageErrorOccurred(String error);

  /// Notification time setting title
  ///
  /// In ko, this message translates to:
  /// **'알림 시간 설정'**
  String get myPageNotificationTimeTitle;

  /// Dark mode setting
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get myPageDarkMode;

  /// Daily reading goal notification setting
  ///
  /// In ko, this message translates to:
  /// **'매일 독서 목표 알림'**
  String get myPageDailyReadingNotification;

  /// No notifications message
  ///
  /// In ko, this message translates to:
  /// **'알림을 받지 않습니다'**
  String get myPageNoNotifications;

  /// Notifications enabled message
  ///
  /// In ko, this message translates to:
  /// **'알림이 활성화되었습니다'**
  String get myPageNotificationsEnabled;

  /// Notifications disabled message
  ///
  /// In ko, this message translates to:
  /// **'알림이 비활성화되었습니다'**
  String get myPageNotificationsDisabled;

  /// Notification settings change failed message
  ///
  /// In ko, this message translates to:
  /// **'알림 설정 변경에 실패했습니다'**
  String get myPageNotificationSettingsFailed;

  /// Test notification button
  ///
  /// In ko, this message translates to:
  /// **'테스트 알림 (30초 후)'**
  String get myPageTestNotification;

  /// Test notification scheduled message
  ///
  /// In ko, this message translates to:
  /// **'30초 후에 테스트 알림이 발송됩니다!'**
  String get myPageTestNotificationScheduled;

  /// No nickname message
  ///
  /// In ko, this message translates to:
  /// **'닉네임 없음'**
  String get myPageNoNickname;

  /// Enter nickname hint
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get myPageEnterNickname;

  /// Profile image changed message
  ///
  /// In ko, this message translates to:
  /// **'프로필 이미지가 변경되었습니다'**
  String get myPageProfileImageChanged;

  /// Profile image change failed message
  ///
  /// In ko, this message translates to:
  /// **'프로필 이미지 변경 실패: {error}'**
  String myPageProfileImageChangeFailed(String error);

  /// Korean language option
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get myPageLanguageKorean;

  /// English language option
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get myPageLanguageEnglish;

  /// Delete account button text
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get myPageDeleteAccountButton;

  /// Notification time changed message
  ///
  /// In ko, this message translates to:
  /// **'알림 시간이 {time}으로 변경되었습니다'**
  String myPageNotificationTimeChanged(String time);

  /// Notification time change failed message
  ///
  /// In ko, this message translates to:
  /// **'알림 시간 변경에 실패했습니다'**
  String get myPageNotificationTimeChangeFailed;

  /// Daily reading notification subtitle with time
  ///
  /// In ko, this message translates to:
  /// **'매일 {time}에 알림'**
  String myPageDailyReadingNotificationSubtitle(String time);

  /// Draft loaded message in review screen
  ///
  /// In ko, this message translates to:
  /// **'임시 저장된 내용을 불러왔습니다.'**
  String get reviewDraftLoaded;

  /// Review copied message
  ///
  /// In ko, this message translates to:
  /// **'독후감이 복사되었습니다.'**
  String get reviewCopied;

  /// Book not found error in review screen
  ///
  /// In ko, this message translates to:
  /// **'책 정보를 찾을 수 없습니다.'**
  String get reviewBookNotFound;

  /// Save failed message in review screen
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다. 다시 시도해주세요.'**
  String get reviewSaveFailed;

  /// Save error message in review screen
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류가 발생했습니다.'**
  String get reviewSaveError;

  /// Replace confirmation title in review screen
  ///
  /// In ko, this message translates to:
  /// **'현재 작성 중인 내용이 있습니다.\nAI 초안으로 대체하시겠습니까?'**
  String get reviewReplaceConfirmTitle;

  /// AI draft generated message
  ///
  /// In ko, this message translates to:
  /// **'AI 초안이 생성되었습니다. 자유롭게 수정해주세요!'**
  String get reviewAIDraftGenerated;

  /// AI draft generation failed message
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성에 실패했습니다. 다시 시도해주세요.'**
  String get reviewAIDraftGenerateFailed;

  /// AI draft generation error message
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성 중 오류가 발생했습니다.'**
  String get reviewAIDraftGenerateError;

  /// Save complete title in review screen
  ///
  /// In ko, this message translates to:
  /// **'독후감이 저장되었습니다!'**
  String get reviewSaveCompleteTitle;

  /// Save complete message in review screen
  ///
  /// In ko, this message translates to:
  /// **'저장한 독후감은 \'독후감\' 탭 또는\n\'나의 서재 > 독후감\'에서 확인할 수 있어요.'**
  String get reviewSaveCompleteMessage;

  /// Exit confirmation title in review screen
  ///
  /// In ko, this message translates to:
  /// **'작성 중단하고 나가시겠어요?'**
  String get reviewExitConfirmTitle;

  /// Exit confirmation subtitle in review screen
  ///
  /// In ko, this message translates to:
  /// **'작성 중이던 독후감은 임시 저장됩니다.'**
  String get reviewExitConfirmSubtitle;

  /// AI generating message in review screen
  ///
  /// In ko, this message translates to:
  /// **'AI가 초안을 작성하고 있어요...'**
  String get reviewAIGenerating;

  /// AI button label in review screen
  ///
  /// In ko, this message translates to:
  /// **'AI로 독후감 초안 작성하기'**
  String get reviewAIButtonLabel;

  /// Text field hint in review screen
  ///
  /// In ko, this message translates to:
  /// **'이 책을 읽고 느낀 점, 인상 깊었던 부분, 나에게 준 영감 등을 자유롭게 적어보세요.'**
  String get reviewTextFieldHint;

  /// Reading start screen title
  ///
  /// In ko, this message translates to:
  /// **'독서 시작하기'**
  String get readingStartTitle;

  /// Reading start screen subtitle
  ///
  /// In ko, this message translates to:
  /// **'독서를 시작할 책을 검색해보세요.'**
  String get readingStartSubtitle;

  /// No search results message
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get readingStartNoResults;

  /// Analyzing reading patterns message
  ///
  /// In ko, this message translates to:
  /// **'독서 패턴을 분석하고 있어요...'**
  String get readingStartAnalyzing;

  /// AI personalized recommendation section title
  ///
  /// In ko, this message translates to:
  /// **'AI 맞춤 추천'**
  String get readingStartAIRecommendation;

  /// AI recommendation description
  ///
  /// In ko, this message translates to:
  /// **'{userName}님의 독서 패턴을 분석하여 추천하는 책들이에요'**
  String readingStartAIRecommendationDesc(String userName);

  /// Search input hint text
  ///
  /// In ko, this message translates to:
  /// **'책 제목을 입력해주세요.'**
  String get readingStartSearchHint;

  /// Selection complete button text
  ///
  /// In ko, this message translates to:
  /// **'선택 완료'**
  String get readingStartSelectionComplete;

  /// Planned reading start date label
  ///
  /// In ko, this message translates to:
  /// **'독서 시작 예정일'**
  String get readingStartPlannedStartDate;

  /// Starting from today message
  ///
  /// In ko, this message translates to:
  /// **'오늘부터 시작합니다'**
  String get readingStartStartingToday;

  /// Target deadline label
  ///
  /// In ko, this message translates to:
  /// **'목표 마감일'**
  String get readingStartTargetDeadline;

  /// Note about changing target deadline
  ///
  /// In ko, this message translates to:
  /// **'독서 시작 후에도 목표일을 변경할 수 있습니다'**
  String get readingStartTargetDeadlineNote;

  /// Barcode scanner screen title
  ///
  /// In ko, this message translates to:
  /// **'ISBN 바코드 스캔'**
  String get barcodeScannerTitle;

  /// Instruction text for barcode scanning
  ///
  /// In ko, this message translates to:
  /// **'책 뒷면의 ISBN 바코드를 스캔해주세요'**
  String get barcodeScannerInstruction;

  /// Hint text to align barcode in frame
  ///
  /// In ko, this message translates to:
  /// **'바코드를 프레임 안에 맞춰주세요'**
  String get barcodeScannerFrameHint;

  /// Error message when camera permission is denied
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 필요합니다\n설정에서 권한을 허용해주세요'**
  String get scannerErrorPermissionDenied;

  /// Error message when camera is initializing
  ///
  /// In ko, this message translates to:
  /// **'카메라를 초기화하는 중입니다'**
  String get scannerErrorInitializing;

  /// General camera error message
  ///
  /// In ko, this message translates to:
  /// **'카메라 오류가 발생했습니다\n다시 시도해주세요'**
  String get scannerErrorGeneral;

  /// Record tab label in book detail
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get bookDetailTabRecordLabel;

  /// History tab label in book detail
  ///
  /// In ko, this message translates to:
  /// **'히스토리'**
  String get bookDetailTabHistoryLabel;

  /// Detail tab label in book detail
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get bookDetailTabDetailLabel;

  /// Opacity label for highlight
  ///
  /// In ko, this message translates to:
  /// **'투명도'**
  String get highlightOpacity;

  /// Thickness label for highlight
  ///
  /// In ko, this message translates to:
  /// **'굵기'**
  String get highlightThickness;

  /// Today's goal setting title
  ///
  /// In ko, this message translates to:
  /// **'오늘의 분량 설정'**
  String get todayGoalSettingTitle;

  /// Start page label
  ///
  /// In ko, this message translates to:
  /// **'시작 페이지'**
  String get todayGoalStartPageLabel;

  /// Target page label
  ///
  /// In ko, this message translates to:
  /// **'목표 페이지'**
  String get todayGoalTargetPageLabel;

  /// Book completed status
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get bookStatusCompleted;

  /// Book planned status
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get bookStatusPlanned;

  /// Book reread status
  ///
  /// In ko, this message translates to:
  /// **'다시 읽을 책'**
  String get bookStatusReread;

  /// Book reading status
  ///
  /// In ko, this message translates to:
  /// **'독서 중'**
  String get bookStatusReading;

  /// Book completion congratulations
  ///
  /// In ko, this message translates to:
  /// **'완독을 축하합니다!'**
  String get bookCompletionCongrats;

  /// Book completion question
  ///
  /// In ko, this message translates to:
  /// **'이 책은 어땠나요?'**
  String get bookCompletionQuestion;

  /// One-line review placeholder
  ///
  /// In ko, this message translates to:
  /// **'한줄평 (선택사항)'**
  String get reviewOneLinePlaceholder;

  /// One-line review hint
  ///
  /// In ko, this message translates to:
  /// **'이 책을 한 마디로 표현하면...'**
  String get reviewOneLineHint;

  /// Later button in completion
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get bookCompletionLater;

  /// Done button in completion
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get bookCompletionDone;

  /// Bad rating
  ///
  /// In ko, this message translates to:
  /// **'아쉬웠어요 😢'**
  String get ratingBad;

  /// Okay rating
  ///
  /// In ko, this message translates to:
  /// **'그저 그랬어요 😐'**
  String get ratingOkay;

  /// Good rating
  ///
  /// In ko, this message translates to:
  /// **'괜찮았어요 🙂'**
  String get ratingGood;

  /// Great rating
  ///
  /// In ko, this message translates to:
  /// **'재미있었어요! 😊'**
  String get ratingGreat;

  /// Excellent rating
  ///
  /// In ko, this message translates to:
  /// **'최고였어요! 🤩'**
  String get ratingExcellent;

  /// Record search
  ///
  /// In ko, this message translates to:
  /// **'기록 검색'**
  String get recordSearch;

  /// Page update
  ///
  /// In ko, this message translates to:
  /// **'페이지 업데이트'**
  String get pageUpdate;

  /// Day labels for week
  ///
  /// In ko, this message translates to:
  /// **'일,월,화,수,목,금,토'**
  String get dayLabels;

  /// Streak achieved message
  ///
  /// In ko, this message translates to:
  /// **'{streak}일 연속 달성!'**
  String streakAchieved(int streak);

  /// First record message
  ///
  /// In ko, this message translates to:
  /// **'오늘 첫 기록을 남겨보세요'**
  String get streakFirstRecord;

  /// Insufficient data for mindmap
  ///
  /// In ko, this message translates to:
  /// **'독서 기록이 부족합니다.\n최소 5개 이상의 하이라이트나 메모가 필요합니다.'**
  String get mindmapInsufficientData;

  /// Highlight badge
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get contentBadgeHighlight;

  /// Memo badge
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get contentBadgeMemo;

  /// Photo OCR badge
  ///
  /// In ko, this message translates to:
  /// **'사진 OCR'**
  String get contentBadgeOCR;

  /// Start date label
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get readingScheduleStartDate;

  /// Target date label
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get readingScheduleTargetDate;

  /// Total days label
  ///
  /// In ko, this message translates to:
  /// **'({totalDays}일)'**
  String readingScheduleTotalDays(int totalDays);

  /// Attempt count
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번째'**
  String readingScheduleAttempt(int attemptCount);

  /// Page update dialog title
  ///
  /// In ko, this message translates to:
  /// **'현재 페이지 업데이트'**
  String get pageUpdateDialogTitle;

  /// Page validation required
  ///
  /// In ko, this message translates to:
  /// **'숫자를 입력해주세요'**
  String get pageUpdateValidationRequired;

  /// Page validation non-negative
  ///
  /// In ko, this message translates to:
  /// **'0 이상의 페이지를 입력해주세요'**
  String get pageUpdateValidationNonNegative;

  /// Page validation exceeds total
  ///
  /// In ko, this message translates to:
  /// **'총 페이지({totalPages})를 초과할 수 없습니다'**
  String pageUpdateValidationExceedsTotal(int totalPages);

  /// Page validation less than current
  ///
  /// In ko, this message translates to:
  /// **'현재 페이지({currentPage}) 이하입니다'**
  String pageUpdateValidationLessThanCurrent(int currentPage);

  /// Current page label
  ///
  /// In ko, this message translates to:
  /// **'현재 {currentPage}p'**
  String pageUpdateCurrentPage(int currentPage);

  /// Total pages label
  ///
  /// In ko, this message translates to:
  /// **' / 총 {totalPages}p'**
  String pageUpdateTotalPages(int totalPages);

  /// New page number label
  ///
  /// In ko, this message translates to:
  /// **'새 페이지 번호'**
  String get pageUpdateNewPageLabel;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get pageUpdateCancel;

  /// Update button
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get pageUpdateButton;

  /// Document scan option
  ///
  /// In ko, this message translates to:
  /// **'문서 스캔'**
  String get imageSourceDocumentScan;

  /// Auto correction option
  ///
  /// In ko, this message translates to:
  /// **'평탄화 및 자동 보정'**
  String get imageSourceAutoCorrection;

  /// Simulator camera error
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이터에서는 카메라를 사용할 수 없습니다'**
  String get imageSourceSimulatorError;

  /// Take photo option
  ///
  /// In ko, this message translates to:
  /// **'카메라 촬영하기'**
  String get imageSourceTakePhoto;

  /// General photo option
  ///
  /// In ko, this message translates to:
  /// **'일반 촬영'**
  String get imageSourceGeneralPhoto;

  /// From library option
  ///
  /// In ko, this message translates to:
  /// **'라이브러리에서 가져오기'**
  String get imageSourceFromLibrary;

  /// Select saved image option
  ///
  /// In ko, this message translates to:
  /// **'저장된 이미지 선택'**
  String get imageSourceSelectSaved;

  /// Replace image title
  ///
  /// In ko, this message translates to:
  /// **'이미지 교체'**
  String get imageSourceReplaceTitle;

  /// Take photo title
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get imageSourceCameraTitle;

  /// Select from gallery title
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get imageSourceGalleryTitle;

  /// Replace image confirmation
  ///
  /// In ko, this message translates to:
  /// **'이미지를 교체하시겠습니까?'**
  String get imageSourceReplaceConfirmation;

  /// Replace image warning
  ///
  /// In ko, this message translates to:
  /// **'기존에 추출한 텍스트가 사라집니다.'**
  String get imageSourceReplaceWarning;

  /// Daily target dialog title
  ///
  /// In ko, this message translates to:
  /// **'일일 목표 페이지 변경'**
  String get dailyTargetDialogTitle;

  /// Expected schedule header
  ///
  /// In ko, this message translates to:
  /// **'예상 스케줄'**
  String get dailyTargetScheduleHeader;

  /// Pages per day label
  ///
  /// In ko, this message translates to:
  /// **'페이지/일'**
  String get dailyTargetPagesPerDay;

  /// Pages left label
  ///
  /// In ko, this message translates to:
  /// **'{pagesLeft}페이지'**
  String dailyTargetPagesLeft(int pagesLeft);

  /// Days left label
  ///
  /// In ko, this message translates to:
  /// **' 남았어요 · D-{daysLeft}'**
  String dailyTargetDaysLeft(int daysLeft);

  /// Change button
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get dailyTargetChangeButton;

  /// Book info not found
  ///
  /// In ko, this message translates to:
  /// **'도서 정보를 찾을 수 없습니다'**
  String get dailyTargetNotFound;

  /// Daily target update success
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표: {newDailyTarget}p로 변경되었습니다'**
  String dailyTargetUpdateSuccess(int newDailyTarget);

  /// Daily target update error
  ///
  /// In ko, this message translates to:
  /// **'목표 변경에 실패했습니다: {error}'**
  String dailyTargetUpdateError(String error);

  /// Edit planned book title
  ///
  /// In ko, this message translates to:
  /// **'독서 계획 수정'**
  String get editPlannedBookTitle;

  /// Planned start date label
  ///
  /// In ko, this message translates to:
  /// **'시작 예정일'**
  String get editPlannedBookStartDate;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get editPlannedBookCancel;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get editPlannedBookSave;

  /// Update target date title
  ///
  /// In ko, this message translates to:
  /// **'목표일 변경'**
  String get updateTargetDateTitle;

  /// Attempt change message
  ///
  /// In ko, this message translates to:
  /// **'{nextAttemptCount}번째 도전으로 변경됩니다'**
  String updateTargetDateAttempt(int nextAttemptCount);

  /// Formatted date
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String updateTargetDateFormatted(int year, int month, int day);

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get updateTargetDateCancel;

  /// Change button
  ///
  /// In ko, this message translates to:
  /// **'변경하기'**
  String get updateTargetDateButton;

  /// Related links section title
  ///
  /// In ko, this message translates to:
  /// **'관련 링크'**
  String get reviewLinkSectionTitle;

  /// View on Aladin title
  ///
  /// In ko, this message translates to:
  /// **'알라딘에서 보기'**
  String get reviewLinkAladinTitle;

  /// Book details subtitle
  ///
  /// In ko, this message translates to:
  /// **'도서 상세 정보'**
  String get reviewLinkAladinSubtitle;

  /// View review button
  ///
  /// In ko, this message translates to:
  /// **'독후감 보기'**
  String get reviewLinkViewButton;

  /// Add review link button
  ///
  /// In ko, this message translates to:
  /// **'독후감 링크 추가'**
  String get reviewLinkAddButton;

  /// My written review description
  ///
  /// In ko, this message translates to:
  /// **'내가 작성한 독후감'**
  String get reviewLinkViewDescription;

  /// Add review link description
  ///
  /// In ko, this message translates to:
  /// **'블로그, 노션 등 독후감 링크를 추가하세요'**
  String get reviewLinkAddDescription;

  /// Review link dialog title
  ///
  /// In ko, this message translates to:
  /// **'독후감 링크'**
  String get reviewLinkDialogTitle;

  /// Review link dialog hint
  ///
  /// In ko, this message translates to:
  /// **'블로그, 노션, 브런치 등 독후감 링크를 입력하세요'**
  String get reviewLinkDialogHint;

  /// Invalid URL error
  ///
  /// In ko, this message translates to:
  /// **'올바른 URL을 입력해주세요'**
  String get reviewLinkInvalidUrl;

  /// Review URL label
  ///
  /// In ko, this message translates to:
  /// **'독후감 URL'**
  String get reviewLinkUrlLabel;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get reviewLinkDeleteButton;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get reviewLinkSaveButton;

  /// Editing content warning
  ///
  /// In ko, this message translates to:
  /// **'수정 중인 내용이 있습니다.'**
  String get existingImageEditingWarning;

  /// Discard changes button
  ///
  /// In ko, this message translates to:
  /// **'변경사항 무시'**
  String get existingImageDiscardChanges;

  /// Continue editing button
  ///
  /// In ko, this message translates to:
  /// **'이어서 하기'**
  String get existingImageContinueEditing;

  /// Exceeds total pages error
  ///
  /// In ko, this message translates to:
  /// **'총 페이지 수({totalPages})를 초과할 수 없습니다'**
  String existingImageExceedsTotal(int totalPages);

  /// Saved message
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get existingImageSaved;

  /// Close button
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get existingImageCloseButton;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get existingImageCancelButton;

  /// Page not set label
  ///
  /// In ko, this message translates to:
  /// **'페이지 미설정'**
  String get existingImagePageNotSet;

  /// Saving button
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get existingImageSavingButton;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get existingImageSaveButton;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get existingImageDeleteButton;

  /// Text input hint
  ///
  /// In ko, this message translates to:
  /// **'텍스트를 입력하세요...'**
  String get existingImageTextHint;

  /// Highlight count
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 {count}'**
  String existingImageHighlightCount(int count);

  /// Highlight label
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get existingImageHighlightLabel;

  /// Extract text button
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출'**
  String get existingImageExtractText;

  /// Replace button
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get existingImageReplaceButton;

  /// Record text label
  ///
  /// In ko, this message translates to:
  /// **'기록 문구'**
  String get existingImageRecordText;

  /// View all button
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get existingImageViewAll;

  /// Text copied message
  ///
  /// In ko, this message translates to:
  /// **'텍스트가 복사되었습니다.'**
  String get existingImageCopyMessage;

  /// Copy button
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get existingImageCopyButton;

  /// Edit button
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get existingImageEditButton;

  /// Clear all button
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get existingImageClearAllButton;

  /// No recorded text message
  ///
  /// In ko, this message translates to:
  /// **'기록된 문구가 없습니다.'**
  String get existingImageNoRecordedText;

  /// Credit warning
  ///
  /// In ko, this message translates to:
  /// **'소모된 크레딧은 복구되지 않습니다.'**
  String get addMemorablePageCreditWarning;

  /// Exceeds total pages error
  ///
  /// In ko, this message translates to:
  /// **'총 페이지 수({totalPages})를 초과할 수 없습니다'**
  String addMemorablePageExceedsTotal(int totalPages);

  /// Exceeds pages error
  ///
  /// In ko, this message translates to:
  /// **'전체 페이지 수를 초과할 수 없습니다.'**
  String get addMemorablePageExceedsError;

  /// Reset confirmation
  ///
  /// In ko, this message translates to:
  /// **'내용을 정말 초기화하시겠어요?'**
  String get addMemorablePageResetConfirm;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get addMemorablePageResetCancel;

  /// Reset button
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get addMemorablePageResetButton;

  /// Add record title
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get addMemorablePageTitle;

  /// Reset title
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get addMemorablePageResetTitle;

  /// Highlight count
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 ({count})'**
  String addMemorablePageHighlightCount(int count);

  /// Highlight label
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get addMemorablePageHighlightLabel;

  /// Extract text button
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출'**
  String get addMemorablePageExtractText;

  /// Replace button
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get addMemorablePageReplaceButton;

  /// Add image prompt
  ///
  /// In ko, this message translates to:
  /// **'터치하여 이미지 추가'**
  String get addMemorablePageAddImage;

  /// Optional label
  ///
  /// In ko, this message translates to:
  /// **'(선택사항)'**
  String get addMemorablePageOptional;

  /// Page count label
  ///
  /// In ko, this message translates to:
  /// **'페이지 수'**
  String get addMemorablePagePageCount;

  /// Text input hint
  ///
  /// In ko, this message translates to:
  /// **'인상 깊은 대목을 기록해보세요.'**
  String get addMemorablePageTextHint;

  /// Record text label
  ///
  /// In ko, this message translates to:
  /// **'기록 문구'**
  String get addMemorablePageRecordText;

  /// View all button
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get addMemorablePageViewAll;

  /// Clear all button
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get addMemorablePageClearAll;

  /// Upload button
  ///
  /// In ko, this message translates to:
  /// **'업로드'**
  String get addMemorablePageUploadButton;

  /// Uploading message
  ///
  /// In ko, this message translates to:
  /// **'업로드 중...'**
  String get addMemorablePageUploading;

  /// Pause reading title
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가기'**
  String get pauseReadingTitle;

  /// Pause reading message
  ///
  /// In ko, this message translates to:
  /// **'현재 진행률 {progress}% ({currentPage} / {totalPages} 페이지)에서\n독서를 잠시 중단합니다.'**
  String pauseReadingMessage(int progress, int currentPage, int totalPages);

  /// Pause reading encouragement
  ///
  /// In ko, this message translates to:
  /// **'언제든지 다시 시작할 수 있어요!'**
  String get pauseReadingEncouragement;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get pauseReadingCancel;

  /// Pause reading button
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가기'**
  String get pauseReadingButton;

  /// Reading management title
  ///
  /// In ko, this message translates to:
  /// **'독서 관리'**
  String get readingManagementTitle;

  /// Reading progress message
  ///
  /// In ko, this message translates to:
  /// **'현재 {progress}% 진행 중이에요 ({currentPage} / {totalPages} 페이지)'**
  String readingManagementProgress(
      int progress, int currentPage, int totalPages);

  /// Pause label
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가기'**
  String get readingManagementPauseLabel;

  /// Pause description
  ///
  /// In ko, this message translates to:
  /// **'나중에 다시 읽을 수 있어요'**
  String get readingManagementPauseDesc;

  /// Delete label
  ///
  /// In ko, this message translates to:
  /// **'삭제하기'**
  String get readingManagementDeleteLabel;

  /// Delete description
  ///
  /// In ko, this message translates to:
  /// **'독서 기록이 삭제됩니다'**
  String get readingManagementDeleteDesc;

  /// Think about it button
  ///
  /// In ko, this message translates to:
  /// **'고민해볼게요'**
  String get readingManagementThinkAbout;

  /// No review message
  ///
  /// In ko, this message translates to:
  /// **'아직 독후감이 없습니다'**
  String get bookReviewTabNoReview;

  /// Review description
  ///
  /// In ko, this message translates to:
  /// **'책을 읽고 느낀 점을 기록해보세요'**
  String get bookReviewTabDescription;

  /// Write review button
  ///
  /// In ko, this message translates to:
  /// **'독후감 작성하기'**
  String get bookReviewTabWriteButton;

  /// My review label
  ///
  /// In ko, this message translates to:
  /// **'나의 독후감'**
  String get bookReviewTabMyReview;

  /// Edit review button
  ///
  /// In ko, this message translates to:
  /// **'독후감 수정하기'**
  String get bookReviewTabEditButton;

  /// Pages left label
  ///
  /// In ko, this message translates to:
  /// **'{pagesLeft}페이지'**
  String dashboardProgressPagesLeft(int pagesLeft);

  /// Remaining label
  ///
  /// In ko, this message translates to:
  /// **' 남았어요'**
  String get dashboardProgressRemaining;

  /// Daily target label
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표: {dailyTarget}p'**
  String dashboardProgressDailyTarget(int dailyTarget);

  /// Goal achieved label
  ///
  /// In ko, this message translates to:
  /// **'목표 달성'**
  String get dashboardProgressAchieved;

  /// Reading management label
  ///
  /// In ko, this message translates to:
  /// **'독서 관리'**
  String get detailTabManagement;

  /// Management description
  ///
  /// In ko, this message translates to:
  /// **'쉬어가기, 삭제 등'**
  String get detailTabManagementDesc;

  /// Delete reading label
  ///
  /// In ko, this message translates to:
  /// **'독서 삭제'**
  String get detailTabDeleteReading;

  /// Review label
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get detailTabReview;

  /// Written status
  ///
  /// In ko, this message translates to:
  /// **'작성됨'**
  String get detailTabReviewWritten;

  /// Not written status
  ///
  /// In ko, this message translates to:
  /// **'아직 작성되지 않음'**
  String get detailTabReviewNotWritten;

  /// Review description
  ///
  /// In ko, this message translates to:
  /// **'책을 읽고 느낀 점을 기록해보세요'**
  String get detailTabReviewDescription;

  /// Reading schedule label
  ///
  /// In ko, this message translates to:
  /// **'독서 일정'**
  String get detailTabSchedule;

  /// Start date label
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get detailTabScheduleStartDate;

  /// Target date label
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get detailTabScheduleTargetDate;

  /// Attempt label
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번째 · {attemptEncouragement}'**
  String detailTabAttempt(int attemptCount, String attemptEncouragement);

  /// Change button
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get detailTabChangeButton;

  /// Goal achievement label
  ///
  /// In ko, this message translates to:
  /// **'목표 달성 현황'**
  String get detailTabGoalAchievement;

  /// Achievement stats
  ///
  /// In ko, this message translates to:
  /// **'{passedDays}일 중 {achievedCount}일 달성'**
  String detailTabAchievementStats(int passedDays, int achievedCount);

  /// Achieved legend
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get detailTabLegendAchieved;

  /// Missed legend
  ///
  /// In ko, this message translates to:
  /// **'미달성'**
  String get detailTabLegendMissed;

  /// Scheduled legend
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get detailTabLegendScheduled;

  /// No images message
  ///
  /// In ko, this message translates to:
  /// **'아직 추가된 사진이 없습니다'**
  String get memorablePagesNoImages;

  /// Add prompt
  ///
  /// In ko, this message translates to:
  /// **'하단 + 버튼으로 추가해보세요'**
  String get memorablePagesAddPrompt;

  /// Selected count
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String memorablePagesSelected(int count);

  /// Sort by page descending
  ///
  /// In ko, this message translates to:
  /// **'페이지 높은순'**
  String get memorablePagesSortPageDesc;

  /// Sort by page ascending
  ///
  /// In ko, this message translates to:
  /// **'페이지 낮은순'**
  String get memorablePagesSortPageAsc;

  /// Sort by date descending
  ///
  /// In ko, this message translates to:
  /// **'최근 기록순'**
  String get memorablePagesSortDateDesc;

  /// Sort by date ascending
  ///
  /// In ko, this message translates to:
  /// **'오래된 기록순'**
  String get memorablePagesSortDateAsc;

  /// Sort by page
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get memorablePagesSortType;

  /// Sort by date
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get memorablePagesSortDate;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get memorablePagesDeleteButton;

  /// Complete button
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get memorablePagesCompleteButton;

  /// Select button
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get memorablePagesSelectButton;

  /// Preview hint
  ///
  /// In ko, this message translates to:
  /// **'탭하여 상세 보기'**
  String get memorablePagesPreviewHint;

  /// Book title label
  ///
  /// In ko, this message translates to:
  /// **'도서 제목'**
  String get fullTitleSheetTitle;

  /// Title copied message
  ///
  /// In ko, this message translates to:
  /// **'제목이 복사되었습니다'**
  String get fullTitleSheetCopyMessage;

  /// Copy button
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get fullTitleSheetCopyButton;

  /// View in store button
  ///
  /// In ko, this message translates to:
  /// **'서점에서 보기'**
  String get fullTitleSheetStoreButton;

  /// Delete confirmation message
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목을 삭제하시겠습니까?'**
  String deleteConfirmationItemCount(int count);

  /// Delete warning
  ///
  /// In ko, this message translates to:
  /// **'삭제한 항목은 복구할 수 없습니다.'**
  String get deleteConfirmationWarning;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get deleteConfirmationCancel;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteConfirmationButton;

  /// No progress records message
  ///
  /// In ko, this message translates to:
  /// **'진행률 기록이 없습니다'**
  String get progressHistoryNoRecords;

  /// Cumulative pages label
  ///
  /// In ko, this message translates to:
  /// **'📈 누적 페이지'**
  String get progressHistoryCumulativePages;

  /// Attempt label
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번째 · {attemptEncouragement}'**
  String progressHistoryAttempt(int attemptCount, String attemptEncouragement);

  /// Record days label
  ///
  /// In ko, this message translates to:
  /// **'{recordCount}일 기록'**
  String progressHistoryRecordDays(int recordCount);

  /// Cumulative legend
  ///
  /// In ko, this message translates to:
  /// **'누적 페이지'**
  String get progressHistoryLegendCumulative;

  /// Daily legend
  ///
  /// In ko, this message translates to:
  /// **'일일 페이지'**
  String get progressHistoryLegendDaily;

  /// Cumulative chart label
  ///
  /// In ko, this message translates to:
  /// **'누적: {cumulativePage} p\n'**
  String progressHistoryChartCumulative(int cumulativePage);

  /// Daily chart label
  ///
  /// In ko, this message translates to:
  /// **'일일: +{dailyPage} p'**
  String progressHistoryChartDaily(int dailyPage);

  /// First completion milestone
  ///
  /// In ko, this message translates to:
  /// **'드디어 완독!'**
  String get progressHistoryMilestoneFirstCompletion;

  /// First completion message
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번의 도전 끝에 완독에 성공했어요. 포기하지 않은 당신이 멋져요!'**
  String progressHistoryMilestoneFirstCompletionMsg(int attemptCount);

  /// Completion milestone
  ///
  /// In ko, this message translates to:
  /// **'완독 축하해요!'**
  String get progressHistoryMilestoneCompletion;

  /// Completion message
  ///
  /// In ko, this message translates to:
  /// **'목표를 달성했어요. 다음 책도 함께 읽어볼까요?'**
  String get progressHistoryMilestoneCompletionMsg;

  /// Retry milestone
  ///
  /// In ko, this message translates to:
  /// **'이번엔 완주해봐요'**
  String get progressHistoryMilestoneRetry;

  /// Retry message
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번째 도전이에요. 목표일을 재설정하고 끝까지 읽어볼까요?'**
  String progressHistoryMilestoneRetryMsg(int attemptCount);

  /// Deadline passed milestone
  ///
  /// In ko, this message translates to:
  /// **'목표일이 지났어요'**
  String get progressHistoryMilestoneDeadlinePassed;

  /// Deadline passed message
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요, 새 목표일을 설정하고 다시 시작해봐요!'**
  String get progressHistoryMilestoneDeadlinePassedMsg;

  /// Fast pace milestone
  ///
  /// In ko, this message translates to:
  /// **'놀라운 속도예요!'**
  String get progressHistoryMilestoneFastPace;

  /// Fast pace message
  ///
  /// In ko, this message translates to:
  /// **'예상보다 훨씬 빠르게 읽고 있어요. 이 페이스면 일찍 완독할 수 있겠어요!'**
  String get progressHistoryMilestoneFastPaceMsg;

  /// On track milestone
  ///
  /// In ko, this message translates to:
  /// **'순조롭게 진행 중!'**
  String get progressHistoryMilestoneOnTrack;

  /// On track message
  ///
  /// In ko, this message translates to:
  /// **'계획보다 앞서가고 있어요. 이대로만 하면 목표 달성 확실해요!'**
  String get progressHistoryMilestoneOnTrackMsg;

  /// On schedule milestone
  ///
  /// In ko, this message translates to:
  /// **'계획대로 진행 중'**
  String get progressHistoryMilestoneOnSchedule;

  /// On schedule message
  ///
  /// In ko, this message translates to:
  /// **'꾸준히 읽고 있어요. 오늘도 조금씩 읽어볼까요?'**
  String get progressHistoryMilestoneOnScheduleMsg;

  /// Behind milestone
  ///
  /// In ko, this message translates to:
  /// **'조금 더 속도를 내볼까요?'**
  String get progressHistoryMilestoneBehind;

  /// Behind message
  ///
  /// In ko, this message translates to:
  /// **'이번에는 꼭 완독해봐요. 매일 조금씩 더 읽으면 따라잡을 수 있어요!'**
  String get progressHistoryMilestoneBehindMsg;

  /// Fall behind milestone
  ///
  /// In ko, this message translates to:
  /// **'조금 더 읽어볼까요?'**
  String get progressHistoryMilestoneFallBehind;

  /// Fall behind message
  ///
  /// In ko, this message translates to:
  /// **'계획보다 살짝 뒤처졌어요. 오늘 조금 더 읽으면 따라잡을 수 있어요!'**
  String get progressHistoryMilestoneFallBehindMsg;

  /// Give up milestone
  ///
  /// In ko, this message translates to:
  /// **'포기하지 마세요!'**
  String get progressHistoryMilestoneGiveUp;

  /// Give up message
  ///
  /// In ko, this message translates to:
  /// **'{attemptCount}번째 도전 중이에요. 목표일을 조정하거나 더 집중해서 읽어봐요!'**
  String progressHistoryMilestoneGiveUpMsg(int attemptCount);

  /// Reset milestone
  ///
  /// In ko, this message translates to:
  /// **'목표 재설정이 필요할 수도'**
  String get progressHistoryMilestoneReset;

  /// Reset message
  ///
  /// In ko, this message translates to:
  /// **'현재 페이스로는 목표 달성이 어려워요. 목표일을 조정해볼까요?'**
  String get progressHistoryMilestoneResetMsg;

  /// Daily records label
  ///
  /// In ko, this message translates to:
  /// **'📅 일별 기록'**
  String get progressHistoryDailyRecords;

  /// Page label
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get progressHistoryPageLabel;

  /// Cumulative label
  ///
  /// In ko, this message translates to:
  /// **'누적: {page} 페이지'**
  String progressHistoryCumulativeLabel(int page);

  /// Daily target confirm title
  ///
  /// In ko, this message translates to:
  /// **'일일 목표 변경'**
  String get dailyTargetConfirmTitle;

  /// Daily target confirm message
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표는 수정할 수 없지만,\n내일부터 변경된 목표가 적용됩니다.'**
  String get dailyTargetConfirmMessage;

  /// Daily target confirm question
  ///
  /// In ko, this message translates to:
  /// **'변경하시겠어요?'**
  String get dailyTargetConfirmQuestion;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get dailyTargetConfirmCancel;

  /// Change button
  ///
  /// In ko, this message translates to:
  /// **'변경하기'**
  String get dailyTargetConfirmButton;

  /// Extracted text modal title
  ///
  /// In ko, this message translates to:
  /// **'추출된 텍스트'**
  String get widgetExtractedTextTitle;

  /// Extracted text modal subtitle
  ///
  /// In ko, this message translates to:
  /// **'추출된 내용을 확인해주세요. 직접 수정도 가능해요!'**
  String get widgetExtractedTextSubtitle;

  /// Apply button for extracted text
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get widgetExtractedTextApply;

  /// Cancel button for extracted text
  ///
  /// In ko, this message translates to:
  /// **'다시 선택'**
  String get widgetExtractedTextCancel;

  /// Text input hint
  ///
  /// In ko, this message translates to:
  /// **'텍스트를 입력하세요'**
  String get widgetExtractedTextHint;

  /// Page number display
  ///
  /// In ko, this message translates to:
  /// **'페이지 {pageNumber}'**
  String widgetExtractedTextPage(int pageNumber);

  /// Full text view modal title
  ///
  /// In ko, this message translates to:
  /// **'기록 문구'**
  String get widgetFullTextTitle;

  /// Full text input hint
  ///
  /// In ko, this message translates to:
  /// **'텍스트를 입력하세요...'**
  String get widgetFullTextHint;

  /// Text copied message
  ///
  /// In ko, this message translates to:
  /// **'텍스트가 복사되었습니다.'**
  String get widgetFullTextCopied;

  /// Collapse button
  ///
  /// In ko, this message translates to:
  /// **'축소보기'**
  String get widgetFullTextCollapse;

  /// Copy button
  ///
  /// In ko, this message translates to:
  /// **'복사하기'**
  String get widgetFullTextCopy;

  /// Edit button
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get widgetFullTextEdit;

  /// Clear all button
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get widgetFullTextClearAll;

  /// Back to reading detail
  ///
  /// In ko, this message translates to:
  /// **'독서상세 메뉴로'**
  String get widgetNavigationBackToDetail;

  /// Year unit
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get widgetDatePickerYear;

  /// Month unit
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get widgetDatePickerMonth;

  /// Day unit
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get widgetDatePickerDay;

  /// AM
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get widgetTimePickerAm;

  /// PM
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get widgetTimePickerPm;

  /// Hour unit
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get widgetTimePickerHour;

  /// Minute unit
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get widgetTimePickerMinute;

  /// Bookstore selection title
  ///
  /// In ko, this message translates to:
  /// **'서점 선택'**
  String get widgetBookstoreSelectTitle;

  /// Bookstore search text
  ///
  /// In ko, this message translates to:
  /// **'\"{searchTitle}\" 검색'**
  String widgetBookstoreSearch(String searchTitle);

  /// Aladin bookstore name
  ///
  /// In ko, this message translates to:
  /// **'알라딘'**
  String get widgetBookstoreAladin;

  /// Kyobo bookstore name
  ///
  /// In ko, this message translates to:
  /// **'교보문고'**
  String get widgetBookstoreKyobo;

  /// Highlight edit title
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 편집'**
  String get widgetHighlightEditTitle;

  /// Opacity label
  ///
  /// In ko, this message translates to:
  /// **'투명도'**
  String get widgetHighlightOpacity;

  /// Stroke width label
  ///
  /// In ko, this message translates to:
  /// **'굵기'**
  String get widgetHighlightStrokeWidth;

  /// Page update button
  ///
  /// In ko, this message translates to:
  /// **'페이지 업데이트'**
  String get widgetPageUpdate;

  /// View book detail in recommendation action sheet
  ///
  /// In ko, this message translates to:
  /// **'책 내용 상세보기'**
  String get widgetRecommendationViewDetail;

  /// Subtitle for view detail action
  ///
  /// In ko, this message translates to:
  /// **'서점에서 책 정보 확인'**
  String get widgetRecommendationViewDetailSubtitle;

  /// Start reading action in recommendation
  ///
  /// In ko, this message translates to:
  /// **'독서 시작'**
  String get widgetRecommendationStartReading;

  /// Subtitle for start reading action
  ///
  /// In ko, this message translates to:
  /// **'해당 책으로 독서 시작'**
  String get widgetRecommendationStartReadingSubtitle;

  /// Select bookstore title
  ///
  /// In ko, this message translates to:
  /// **'서점 선택'**
  String get widgetRecommendationSelectBookstore;

  /// Search bookstore subtitle
  ///
  /// In ko, this message translates to:
  /// **'\'{searchTitle}\' 검색 결과'**
  String widgetRecommendationSearchBookstore(String searchTitle);

  /// Text copied message in recall widgets
  ///
  /// In ko, this message translates to:
  /// **'텍스트가 복사되었습니다'**
  String get recallTextCopied;

  /// Record label in source detail modal
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get recallRecordLabel;

  /// Global recall search title
  ///
  /// In ko, this message translates to:
  /// **'모든 기록 검색'**
  String get recallGlobalSearchTitle;

  /// Global search in progress message
  ///
  /// In ko, this message translates to:
  /// **'모든 책에서 검색하는 중...'**
  String get recallGlobalSearching;

  /// Recent global searches section title
  ///
  /// In ko, this message translates to:
  /// **'최근 전역 검색'**
  String get recallRecentGlobalSearches;

  /// Global search empty state title
  ///
  /// In ko, this message translates to:
  /// **'모든 독서 기록에서 검색하세요'**
  String get recallGlobalEmptyTitle;

  /// Global search empty state subtitle
  ///
  /// In ko, this message translates to:
  /// **'여러 책에 흩어진 기록들을\nAI가 종합하여 찾아드립니다'**
  String get recallGlobalEmptySubtitle;

  /// Sources by book count label
  ///
  /// In ko, this message translates to:
  /// **'참고한 기록 ({count}권)'**
  String recallSourcesByBookCount(int count);

  /// More books count label
  ///
  /// In ko, this message translates to:
  /// **'{count}권 더 보기'**
  String recallMoreBooksCount(int count);

  /// AI answer label
  ///
  /// In ko, this message translates to:
  /// **'AI 답변'**
  String get recallAIAnswer;

  /// Global search hint text
  ///
  /// In ko, this message translates to:
  /// **'예: \"습관에 대해 어떤 내용이 있었지?\"'**
  String get recallGlobalSearchHint;

  /// My records search title
  ///
  /// In ko, this message translates to:
  /// **'내 기록 검색'**
  String get recallMyRecordsSearchTitle;

  /// My records search in progress message
  ///
  /// In ko, this message translates to:
  /// **'당신의 기록을 검색하는 중...'**
  String get recallMyRecordsSearching;

  /// Recent searches section title
  ///
  /// In ko, this message translates to:
  /// **'최근 검색'**
  String get recallRecentSearches;

  /// Suggested questions section title
  ///
  /// In ko, this message translates to:
  /// **'추천 질문'**
  String get recallSuggestedQuestions;

  /// Recall search empty state title
  ///
  /// In ko, this message translates to:
  /// **'궁금한 내용을 검색해보세요'**
  String get recallEmptyTitle;

  /// Recall search empty state subtitle
  ///
  /// In ko, this message translates to:
  /// **'하이라이트, 메모, 사진 속에서 찾아드립니다'**
  String get recallEmptySubtitle;

  /// Related records section title
  ///
  /// In ko, this message translates to:
  /// **'관련 기록'**
  String get recallRelatedRecords;

  /// Copy button label
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get recallCopyButton;

  /// Just now time label
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get recallJustNow;

  /// Minutes ago time label
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String recallMinutesAgo(int count);

  /// Hours ago time label
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String recallHoursAgo(int count);

  /// Days ago time label
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String recallDaysAgo(int count);

  /// My records search hint text
  ///
  /// In ko, this message translates to:
  /// **'예: \"저자가 습관에 대해 뭐라고 했지?\"'**
  String get recallMyRecordsSearchHint;

  /// Page label
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get recallPageLabel;

  /// Record count label
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록'**
  String recallRecordCountLabel(int count);

  /// Content copied message in record detail sheet
  ///
  /// In ko, this message translates to:
  /// **'내용이 복사되었습니다'**
  String get recallContentCopied;

  /// View in book button label
  ///
  /// In ko, this message translates to:
  /// **'이 책에서 보기'**
  String get recallViewInBook;

  /// Page unit in book list cards
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get bookListPageUnit;

  /// Days to complete book message
  ///
  /// In ko, this message translates to:
  /// **'{days}일만에 완독'**
  String completedBookDaysToComplete(int days);

  /// Same day completion message
  ///
  /// In ko, this message translates to:
  /// **'당일 완독'**
  String get completedBookSameDayComplete;

  /// Achievement rate label
  ///
  /// In ko, this message translates to:
  /// **'달성률 {rate}%'**
  String completedBookAchievementRate(int rate);

  /// Unknown date label for paused book
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get pausedBookUnknownDate;

  /// Planned start date label
  ///
  /// In ko, this message translates to:
  /// **'시작 예정: {date}'**
  String plannedBookStartDate(String date);

  /// Undetermined start date label
  ///
  /// In ko, this message translates to:
  /// **'시작일 미정'**
  String get plannedBookStartDateUndetermined;

  /// Priority selector label
  ///
  /// In ko, this message translates to:
  /// **'우선순위 (선택사항)'**
  String get prioritySelectorLabel;

  /// Status selector label
  ///
  /// In ko, this message translates to:
  /// **'독서 상태'**
  String get statusSelectorLabel;

  /// Planned status label
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get statusPlannedLabel;

  /// Reading status label
  ///
  /// In ko, this message translates to:
  /// **'바로 시작'**
  String get statusReadingLabel;

  /// Note content type
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get contentTypeNote;

  /// Business/Economics genre
  ///
  /// In ko, this message translates to:
  /// **'경제경영'**
  String get genreBusinessEconomics;

  /// Genre message for novel
  ///
  /// In ko, this message translates to:
  /// **'당신은 문학 소년이군요!'**
  String get genreMessageNovel1;

  /// Genre message for novel
  ///
  /// In ko, this message translates to:
  /// **'이야기 속에서 살고 있는 당신'**
  String get genreMessageNovel2;

  /// Genre message for novel
  ///
  /// In ko, this message translates to:
  /// **'소설의 세계에 푹 빠진 독서가'**
  String get genreMessageNovel3;

  /// Genre message for literature
  ///
  /// In ko, this message translates to:
  /// **'당신은 문학 소년이군요!'**
  String get genreMessageLiterature1;

  /// Genre message for literature
  ///
  /// In ko, this message translates to:
  /// **'문학의 깊이를 아는 독자'**
  String get genreMessageLiterature2;

  /// Genre message for literature
  ///
  /// In ko, this message translates to:
  /// **'글의 아름다움을 즐기는 분'**
  String get genreMessageLiterature3;

  /// Genre message for self-help
  ///
  /// In ko, this message translates to:
  /// **'끊임없이 성장하는 당신!'**
  String get genreMessageSelfHelp1;

  /// Genre message for self-help
  ///
  /// In ko, this message translates to:
  /// **'발전을 멈추지 않는 독서가'**
  String get genreMessageSelfHelp2;

  /// Genre message for self-help
  ///
  /// In ko, this message translates to:
  /// **'더 나은 내일을 준비하는 중'**
  String get genreMessageSelfHelp3;

  /// Genre message for business
  ///
  /// In ko, this message translates to:
  /// **'비즈니스 마인드가 뛰어나시네요!'**
  String get genreMessageBusiness1;

  /// Genre message for business
  ///
  /// In ko, this message translates to:
  /// **'성공을 향해 달려가는 중'**
  String get genreMessageBusiness2;

  /// Genre message for business
  ///
  /// In ko, this message translates to:
  /// **'미래의 CEO 감이에요'**
  String get genreMessageBusiness3;

  /// Genre message for humanities
  ///
  /// In ko, this message translates to:
  /// **'깊이 있는 사색을 즐기시는군요'**
  String get genreMessageHumanities1;

  /// Genre message for humanities
  ///
  /// In ko, this message translates to:
  /// **'철학적 사유를 즐기는 독자'**
  String get genreMessageHumanities2;

  /// Genre message for humanities
  ///
  /// In ko, this message translates to:
  /// **'인간과 세상을 탐구하는 분'**
  String get genreMessageHumanities3;

  /// Genre message for science
  ///
  /// In ko, this message translates to:
  /// **'호기심 많은 탐험가시네요!'**
  String get genreMessageScience1;

  /// Genre message for science
  ///
  /// In ko, this message translates to:
  /// **'세상의 원리를 파헤치는 중'**
  String get genreMessageScience2;

  /// Genre message for science
  ///
  /// In ko, this message translates to:
  /// **'과학적 사고의 소유자'**
  String get genreMessageScience3;

  /// Genre message for history
  ///
  /// In ko, this message translates to:
  /// **'역사에서 지혜를 찾는 분이시네요'**
  String get genreMessageHistory1;

  /// Genre message for history
  ///
  /// In ko, this message translates to:
  /// **'과거를 통해 미래를 보는 눈'**
  String get genreMessageHistory2;

  /// Genre message for history
  ///
  /// In ko, this message translates to:
  /// **'역사 덕후의 기질이 보여요'**
  String get genreMessageHistory3;

  /// Genre message for essay
  ///
  /// In ko, this message translates to:
  /// **'삶의 이야기에 공감하시는 분'**
  String get genreMessageEssay1;

  /// Genre message for essay
  ///
  /// In ko, this message translates to:
  /// **'일상 속 의미를 찾는 독자'**
  String get genreMessageEssay2;

  /// Genre message for essay
  ///
  /// In ko, this message translates to:
  /// **'따뜻한 감성의 소유자'**
  String get genreMessageEssay3;

  /// Genre message for poetry
  ///
  /// In ko, this message translates to:
  /// **'감성이 풍부한 시인의 영혼'**
  String get genreMessagePoetry1;

  /// Genre message for poetry
  ///
  /// In ko, this message translates to:
  /// **'언어의 아름다움을 아는 분'**
  String get genreMessagePoetry2;

  /// Genre message for poetry
  ///
  /// In ko, this message translates to:
  /// **'시적 감수성이 뛰어나시네요'**
  String get genreMessagePoetry3;

  /// Genre message for comic
  ///
  /// In ko, this message translates to:
  /// **'재미와 감동을 동시에 즐기는 분'**
  String get genreMessageComic1;

  /// Genre message for comic
  ///
  /// In ko, this message translates to:
  /// **'그림으로 이야기를 읽는 독자'**
  String get genreMessageComic2;

  /// Genre message for comic
  ///
  /// In ko, this message translates to:
  /// **'만화의 매력을 아는 분'**
  String get genreMessageComic3;

  /// Genre message for uncategorized
  ///
  /// In ko, this message translates to:
  /// **'다양한 분야를 섭렵하는 중!'**
  String get genreMessageUncategorized1;

  /// Genre message for uncategorized
  ///
  /// In ko, this message translates to:
  /// **'장르를 가리지 않는 독서가'**
  String get genreMessageUncategorized2;

  /// Genre message for uncategorized
  ///
  /// In ko, this message translates to:
  /// **'책이라면 다 좋아하시는 분'**
  String get genreMessageUncategorized3;

  /// Default genre message
  ///
  /// In ko, this message translates to:
  /// **'{genre} 분야의 전문가시네요!'**
  String genreMessageDefault(String genre);

  /// Default genre message 2
  ///
  /// In ko, this message translates to:
  /// **'{genre}에 깊은 관심을 가지신 분'**
  String genreMessageDefault2(String genre);

  /// Default genre message 3
  ///
  /// In ko, this message translates to:
  /// **'{genre} 마니아의 기질이 보여요'**
  String genreMessageDefault3(String genre);

  /// Paywall screen title
  ///
  /// In ko, this message translates to:
  /// **'Bookgolas Pro'**
  String get paywallTitle;

  /// Paywall screen subtitle
  ///
  /// In ko, this message translates to:
  /// **'모든 기능을 제한 없이 사용하세요'**
  String get paywallSubtitle;

  /// Unlimited concurrent reading
  ///
  /// In ko, this message translates to:
  /// **'동시 읽기 무제한'**
  String get paywallBenefit1;

  /// AI Recall monthly usage
  ///
  /// In ko, this message translates to:
  /// **'AI Recall 월 30회 사용'**
  String get paywallBenefit2;

  /// Reading insights and statistics
  ///
  /// In ko, this message translates to:
  /// **'독서 인사이트 및 통계'**
  String get paywallBenefit3;

  /// Monthly subscription
  ///
  /// In ko, this message translates to:
  /// **'월간 구독'**
  String get paywallMonthly;

  /// Monthly price
  ///
  /// In ko, this message translates to:
  /// **'₩3,900'**
  String get paywallMonthlyPrice;

  /// Per month label
  ///
  /// In ko, this message translates to:
  /// **'/월'**
  String get paywallPerMonth;

  /// Yearly subscription
  ///
  /// In ko, this message translates to:
  /// **'연간 구독'**
  String get paywallYearly;

  /// Yearly price
  ///
  /// In ko, this message translates to:
  /// **'₩29,900'**
  String get paywallYearlyPrice;

  /// Per year label
  ///
  /// In ko, this message translates to:
  /// **'/년'**
  String get paywallPerYear;

  /// Yearly savings message
  ///
  /// In ko, this message translates to:
  /// **'연간 구독 시 36% 절약'**
  String get paywallYearlySavings;

  /// Restore purchases button
  ///
  /// In ko, this message translates to:
  /// **'이전 구매 복원'**
  String get paywallRestore;

  /// Restore success message
  ///
  /// In ko, this message translates to:
  /// **'구독이 복원되었습니다'**
  String get paywallRestoreSuccess;

  /// Title when concurrent reading limit reached
  ///
  /// In ko, this message translates to:
  /// **'동시 읽기 제한'**
  String get concurrentReadingLimitTitle;

  /// Message when concurrent reading limit reached
  ///
  /// In ko, this message translates to:
  /// **'무료 사용자는 동시에 3권까지 읽을 수 있습니다. Pro로 업그레이드하여 무제한으로 이용하세요.'**
  String get concurrentReadingLimitMessage;

  /// Title when AI Recall limit reached
  ///
  /// In ko, this message translates to:
  /// **'AI Recall 사용량 초과'**
  String get aiRecallLimitTitle;

  /// Message when AI Recall limit reached
  ///
  /// In ko, this message translates to:
  /// **'이번 달 AI Recall 사용 횟수를 모두 소진했습니다.'**
  String get aiRecallLimitMessage;

  /// Remaining AI Recall uses
  ///
  /// In ko, this message translates to:
  /// **'이번 달 남은 횟수: {count}회'**
  String aiRecallRemainingUses(int count);

  /// Subscription screen title
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get subscriptionTitle;

  /// Pro subscription status
  ///
  /// In ko, this message translates to:
  /// **'Bookgolas Pro'**
  String get subscriptionProStatus;

  /// Free user status
  ///
  /// In ko, this message translates to:
  /// **'무료 사용자'**
  String get subscriptionFreeStatus;

  /// Pro subscription description
  ///
  /// In ko, this message translates to:
  /// **'모든 기능을 무제한으로 이용하세요'**
  String get subscriptionProDescription;

  /// Free user description
  ///
  /// In ko, this message translates to:
  /// **'기능 제한이 적용됩니다'**
  String get subscriptionFreeDescription;

  /// Upgrade to Pro title
  ///
  /// In ko, this message translates to:
  /// **'Pro로 업그레이드'**
  String get subscriptionUpgradeTitle;

  /// Monthly subscription
  ///
  /// In ko, this message translates to:
  /// **'월간 구독'**
  String get subscriptionMonthly;

  /// Monthly price
  ///
  /// In ko, this message translates to:
  /// **'₩3,900'**
  String get subscriptionMonthlyPrice;

  /// Per month label
  ///
  /// In ko, this message translates to:
  /// **'/월'**
  String get subscriptionPerMonth;

  /// Yearly subscription
  ///
  /// In ko, this message translates to:
  /// **'연간 구독'**
  String get subscriptionYearly;

  /// Yearly price
  ///
  /// In ko, this message translates to:
  /// **'₩29,900'**
  String get subscriptionYearlyPrice;

  /// Per year label
  ///
  /// In ko, this message translates to:
  /// **'/년'**
  String get subscriptionPerYear;

  /// Yearly savings
  ///
  /// In ko, this message translates to:
  /// **'36% 절약'**
  String get subscriptionYearlySavings;

  /// Pro benefits title
  ///
  /// In ko, this message translates to:
  /// **'Pro 혜택'**
  String get subscriptionBenefitsTitle;

  /// Unlimited concurrent reading
  ///
  /// In ko, this message translates to:
  /// **'동시 읽기 무제한'**
  String get subscriptionBenefit1;

  /// AI Recall monthly usage
  ///
  /// In ko, this message translates to:
  /// **'AI Recall 월 30회 사용'**
  String get subscriptionBenefit2;

  /// Reading insights
  ///
  /// In ko, this message translates to:
  /// **'독서 인사이트 및 통계'**
  String get subscriptionBenefit3;

  /// Manage subscription title
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get subscriptionManageTitle;

  /// Restore purchases
  ///
  /// In ko, this message translates to:
  /// **'이전 구매 복원'**
  String get subscriptionRestore;

  /// Subscription settings
  ///
  /// In ko, this message translates to:
  /// **'구독 설정'**
  String get subscriptionManageSubscription;

  /// Change or cancel subscription
  ///
  /// In ko, this message translates to:
  /// **'구독 변경 또는 해지'**
  String get subscriptionManageSubtitle;

  /// Restore success message
  ///
  /// In ko, this message translates to:
  /// **'구독이 복원되었습니다'**
  String get subscriptionRestoreSuccess;

  /// Restore failed message
  ///
  /// In ko, this message translates to:
  /// **'복원에 실패했습니다'**
  String get subscriptionRestoreFailed;

  /// Pro upgrade banner title
  ///
  /// In ko, this message translates to:
  /// **'Pro로 업그레이드'**
  String get proUpgradeBannerTitle;

  /// Pro upgrade banner subtitle
  ///
  /// In ko, this message translates to:
  /// **'동시 읽기 · AI Recall 무제한'**
  String get proUpgradeBannerSubtitle;

  /// Pro upgrade CTA button
  ///
  /// In ko, this message translates to:
  /// **'업그레이드하기'**
  String get proUpgradeBannerCta;

  /// Mini pro upgrade banner
  ///
  /// In ko, this message translates to:
  /// **'Pro로 무제한 이용하기'**
  String get proUpgradeBannerMini;

  /// Upgrade to Pro in my page
  ///
  /// In ko, this message translates to:
  /// **'Pro로 업그레이드'**
  String get myPageSubscriptionUpgrade;

  /// Manage subscription in my page
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get myPageSubscriptionManage;

  /// No description provided for @myPageNotificationDisabled.
  ///
  /// In ko, this message translates to:
  /// **'알림이 비활성화됨'**
  String get myPageNotificationDisabled;

  /// No description provided for @myPageTestNotificationSent.
  ///
  /// In ko, this message translates to:
  /// **'테스트 알림이 전송됨'**
  String get myPageTestNotificationSent;

  /// No description provided for @barcodeScannerHint.
  ///
  /// In ko, this message translates to:
  /// **'바코드를 프레임 안에 맞춰주세요'**
  String get barcodeScannerHint;

  /// No description provided for @scannerErrorDefault.
  ///
  /// In ko, this message translates to:
  /// **'스캐너 오류가 발생했습니다'**
  String get scannerErrorDefault;

  /// No description provided for @extractingText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출 중...'**
  String get extractingText;

  /// No description provided for @ocrExtractionFailed.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출 실패'**
  String get ocrExtractionFailed;

  /// No description provided for @extractTextConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출'**
  String get extractTextConfirmTitle;

  /// No description provided for @extractTextCreditsMessage.
  ///
  /// In ko, this message translates to:
  /// **'크레딧이 사용됩니다'**
  String get extractTextCreditsMessage;

  /// No description provided for @noThanksButton.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get noThanksButton;

  /// No description provided for @extractButton.
  ///
  /// In ko, this message translates to:
  /// **'추출하기'**
  String get extractButton;

  /// No description provided for @ocrAreaSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'추출할 영역 선택'**
  String get ocrAreaSelectTitle;

  /// No description provided for @imageLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 로드 실패'**
  String get imageLoadFailed;

  /// No description provided for @extractTextOverwriteMessage.
  ///
  /// In ko, this message translates to:
  /// **'기존 텍스트를 덮어씁니다'**
  String get extractTextOverwriteMessage;

  /// No description provided for @loadingImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 로딩 중...'**
  String get loadingImage;

  /// No description provided for @ocrReExtractionFailed.
  ///
  /// In ko, this message translates to:
  /// **'재추출 실패'**
  String get ocrReExtractionFailed;

  /// No description provided for @reScanButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 스캔'**
  String get reScanButton;

  /// No description provided for @documentScanFailed.
  ///
  /// In ko, this message translates to:
  /// **'문서 스캔 실패'**
  String get documentScanFailed;

  /// No description provided for @expectedSchedule.
  ///
  /// In ko, this message translates to:
  /// **'예상 스케줄'**
  String get expectedSchedule;

  /// No description provided for @dailyTargetChangeTitle.
  ///
  /// In ko, this message translates to:
  /// **'일일 목표 변경'**
  String get dailyTargetChangeTitle;

  /// No description provided for @pagesPerDay.
  ///
  /// In ko, this message translates to:
  /// **'페이지/일'**
  String get pagesPerDay;

  /// No description provided for @bookInfoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'책 정보를 찾을 수 없습니다'**
  String get bookInfoNotFound;

  /// No description provided for @goalChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'목표 변경 실패'**
  String get goalChangeFailed;

  /// No description provided for @editReadingPlanTitle.
  ///
  /// In ko, this message translates to:
  /// **'독서 계획 수정'**
  String get editReadingPlanTitle;

  /// No description provided for @editPlannedStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작 예정일'**
  String get editPlannedStartDate;

  /// No description provided for @validationEnterNumber.
  ///
  /// In ko, this message translates to:
  /// **'숫자를 입력해주세요'**
  String get validationEnterNumber;

  /// No description provided for @validationPageMinimum.
  ///
  /// In ko, this message translates to:
  /// **'페이지는 0 이상이어야 합니다'**
  String get validationPageMinimum;

  /// No description provided for @validationPageExceedsTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 페이지({totalPages})를 초과할 수 없습니다'**
  String validationPageExceedsTotal(int totalPages);

  /// No description provided for @validationPageBelowCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 페이지({currentPage})보다 작을 수 없습니다'**
  String validationPageBelowCurrent(int currentPage);

  /// No description provided for @updatePageTitle.
  ///
  /// In ko, this message translates to:
  /// **'페이지 업데이트'**
  String get updatePageTitle;

  /// No description provided for @currentPageLabel.
  ///
  /// In ko, this message translates to:
  /// **'현재: {page}p'**
  String currentPageLabel(int page);

  /// No description provided for @totalPageLabel.
  ///
  /// In ko, this message translates to:
  /// **'총: {page}p'**
  String totalPageLabel(int page);

  /// No description provided for @newPageNumber.
  ///
  /// In ko, this message translates to:
  /// **'새 페이지 번호'**
  String get newPageNumber;

  /// No description provided for @updateButton.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get updateButton;

  /// No description provided for @changeTargetDateTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표일 변경'**
  String get changeTargetDateTitle;

  /// No description provided for @attemptChangeMessage.
  ///
  /// In ko, this message translates to:
  /// **'{attempt}번째 도전이 시작됩니다'**
  String attemptChangeMessage(int attempt);

  /// No description provided for @confirmChange.
  ///
  /// In ko, this message translates to:
  /// **'변경 확인'**
  String get confirmChange;

  /// No description provided for @searchRecordsButton.
  ///
  /// In ko, this message translates to:
  /// **'기록 검색'**
  String get searchRecordsButton;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'정말 초기화하시겠습니까?'**
  String get resetConfirmMessage;

  /// No description provided for @resetButton.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get resetButton;

  /// No description provided for @addRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get addRecordTitle;

  /// No description provided for @highlightLabel.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get highlightLabel;

  /// No description provided for @highlightWithCount.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 ({count})'**
  String highlightWithCount(int count);

  /// No description provided for @extractTextButton.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 추출'**
  String get extractTextButton;

  /// No description provided for @replaceButton.
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get replaceButton;

  /// No description provided for @tapToAddImage.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 이미지 추가'**
  String get tapToAddImage;

  /// No description provided for @optionalLabel.
  ///
  /// In ko, this message translates to:
  /// **'(선택사항)'**
  String get optionalLabel;

  /// No description provided for @recallPage.
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get recallPage;

  /// No description provided for @recordHint.
  ///
  /// In ko, this message translates to:
  /// **'생각을 기록해주세요...'**
  String get recordHint;

  /// No description provided for @recordTextLabel.
  ///
  /// In ko, this message translates to:
  /// **'기록 텍스트'**
  String get recordTextLabel;

  /// No description provided for @viewFullButton.
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get viewFullButton;

  /// No description provided for @clearAllButton.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get clearAllButton;

  /// No description provided for @uploadButton.
  ///
  /// In ko, this message translates to:
  /// **'업로드'**
  String get uploadButton;

  /// No description provided for @uploading.
  ///
  /// In ko, this message translates to:
  /// **'업로드 중...'**
  String get uploading;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않은 변경 사항이 있습니다'**
  String get unsavedChangesMessage;

  /// No description provided for @discardChangesButton.
  ///
  /// In ko, this message translates to:
  /// **'버리기'**
  String get discardChangesButton;

  /// No description provided for @continueEditingButton.
  ///
  /// In ko, this message translates to:
  /// **'계속 편집'**
  String get continueEditingButton;

  /// No description provided for @pageExceedsTotalError.
  ///
  /// In ko, this message translates to:
  /// **'총 페이지({totalPages})를 초과할 수 없습니다'**
  String pageExceedsTotalError(int totalPages);

  /// No description provided for @pageNotSet.
  ///
  /// In ko, this message translates to:
  /// **'페이지 미설정'**
  String get pageNotSet;

  /// No description provided for @textInputHint.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 입력...'**
  String get textInputHint;

  /// No description provided for @textCopied.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 복사됨'**
  String get textCopied;

  /// No description provided for @copyButton.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get copyButton;

  /// No description provided for @editButton.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get editButton;

  /// No description provided for @noRecordedText.
  ///
  /// In ko, this message translates to:
  /// **'기록된 텍스트 없음'**
  String get noRecordedText;

  /// No description provided for @bookInfoDetail.
  ///
  /// In ko, this message translates to:
  /// **'도서 상세'**
  String get bookInfoDetail;

  /// No description provided for @invalidUrl.
  ///
  /// In ko, this message translates to:
  /// **'잘못된 URL'**
  String get invalidUrl;

  /// No description provided for @bookReviewTabTitle.
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get bookReviewTabTitle;

  /// No description provided for @bookDetailDeleteReading.
  ///
  /// In ko, this message translates to:
  /// **'독서 삭제'**
  String get bookDetailDeleteReading;

  /// No description provided for @bookDetailSchedule.
  ///
  /// In ko, this message translates to:
  /// **'독서 일정'**
  String get bookDetailSchedule;

  /// No description provided for @bookDetailGoalProgress.
  ///
  /// In ko, this message translates to:
  /// **'목표 진행'**
  String get bookDetailGoalProgress;

  /// No description provided for @bookDetailAchievementStatus.
  ///
  /// In ko, this message translates to:
  /// **'{total}일 중 {achieved}일 달성'**
  String bookDetailAchievementStatus(int achieved, int total);

  /// No description provided for @bookDetailNoPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진이 없습니다'**
  String get bookDetailNoPhotos;

  /// No description provided for @bookDetailAddPhotoHint.
  ///
  /// In ko, this message translates to:
  /// **'아래 + 버튼으로 추가하세요'**
  String get bookDetailAddPhotoHint;

  /// No description provided for @memorablePagesSortByPage.
  ///
  /// In ko, this message translates to:
  /// **'페이지순'**
  String get memorablePagesSortByPage;

  /// No description provided for @memorablePagesSortByDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜순'**
  String get memorablePagesSortByDate;

  /// No description provided for @memorablePagesDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get memorablePagesDelete;

  /// No description provided for @memorablePagesDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get memorablePagesDone;

  /// No description provided for @memorablePagesSelect.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get memorablePagesSelect;

  /// No description provided for @noProgressRecords.
  ///
  /// In ko, this message translates to:
  /// **'진행 기록 없음'**
  String get noProgressRecords;

  /// No description provided for @historyTabCumulativePages.
  ///
  /// In ko, this message translates to:
  /// **'누적 페이지'**
  String get historyTabCumulativePages;

  /// No description provided for @historyTabDailyPages.
  ///
  /// In ko, this message translates to:
  /// **'일일 페이지'**
  String get historyTabDailyPages;

  /// No description provided for @historyTabDailyRecords.
  ///
  /// In ko, this message translates to:
  /// **'일별 기록'**
  String get historyTabDailyRecords;

  /// No description provided for @historyTabCumulativeLabel.
  ///
  /// In ko, this message translates to:
  /// **'누적: {page}p'**
  String historyTabCumulativeLabel(int page);

  /// No description provided for @historyTabPagesUnit.
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get historyTabPagesUnit;

  /// No description provided for @daysRecorded.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 기록됨'**
  String daysRecorded(int days);

  /// No description provided for @unitPages.
  ///
  /// In ko, this message translates to:
  /// **'페이지'**
  String get unitPages;

  /// No description provided for @bookListErrorNetworkCheck.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get bookListErrorNetworkCheck;

  /// No description provided for @bookListCompletedIn.
  ///
  /// In ko, this message translates to:
  /// **'{days}일만에 완독'**
  String bookListCompletedIn(int days);

  /// No description provided for @bookListCompletedSameDay.
  ///
  /// In ko, this message translates to:
  /// **'당일 완독'**
  String get bookListCompletedSameDay;

  /// No description provided for @bookListAchievementRate.
  ///
  /// In ko, this message translates to:
  /// **'달성률 {rate}%'**
  String bookListAchievementRate(int rate);

  /// No description provided for @bookListCompletedDate.
  ///
  /// In ko, this message translates to:
  /// **'완독: {date}'**
  String bookListCompletedDate(String date);

  /// No description provided for @bookListUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get bookListUnknown;

  /// No description provided for @bookListPlannedStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작: {date}'**
  String bookListPlannedStartDate(String date);

  /// No description provided for @bookListUndetermined.
  ///
  /// In ko, this message translates to:
  /// **'시작일 미정'**
  String get bookListUndetermined;

  /// No description provided for @reviewReplaceConfirm.
  ///
  /// In ko, this message translates to:
  /// **'AI 초안으로 대체하시겠습니까?'**
  String get reviewReplaceConfirm;

  /// No description provided for @reviewReplaceButton.
  ///
  /// In ko, this message translates to:
  /// **'대체하기'**
  String get reviewReplaceButton;

  /// No description provided for @reviewAIDraftFailed.
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성 실패'**
  String get reviewAIDraftFailed;

  /// No description provided for @reviewAIDraftError.
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성 오류'**
  String get reviewAIDraftError;

  /// No description provided for @reviewSaveComplete.
  ///
  /// In ko, this message translates to:
  /// **'독후감 저장됨'**
  String get reviewSaveComplete;

  /// No description provided for @reviewExitConfirm.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가시겠습니까?'**
  String get reviewExitConfirm;

  /// No description provided for @reviewExitMessage.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장됩니다'**
  String get reviewExitMessage;

  /// No description provided for @aiDraftGenerating.
  ///
  /// In ko, this message translates to:
  /// **'AI가 작성 중...'**
  String get aiDraftGenerating;

  /// No description provided for @aiDraftGenerate.
  ///
  /// In ko, this message translates to:
  /// **'AI 초안 생성'**
  String get aiDraftGenerate;

  /// No description provided for @reviewHint.
  ///
  /// In ko, this message translates to:
  /// **'책에 대한 생각을 적어보세요...'**
  String get reviewHint;

  /// No description provided for @bookstoreSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'서점 선택'**
  String get bookstoreSelectTitle;

  /// No description provided for @bookstoreAladdin.
  ///
  /// In ko, this message translates to:
  /// **'알라딘'**
  String get bookstoreAladdin;

  /// No description provided for @bookstoreKyobo.
  ///
  /// In ko, this message translates to:
  /// **'교보문고'**
  String get bookstoreKyobo;

  /// No description provided for @expandedNavBackToDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세로 돌아가기'**
  String get expandedNavBackToDetail;

  /// No description provided for @highlightEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 수정'**
  String get highlightEditTitle;

  /// No description provided for @highlightEditDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get highlightEditDone;

  /// No description provided for @datePickerMonthJan.
  ///
  /// In ko, this message translates to:
  /// **'1월'**
  String get datePickerMonthJan;

  /// No description provided for @datePickerMonthFeb.
  ///
  /// In ko, this message translates to:
  /// **'2월'**
  String get datePickerMonthFeb;

  /// No description provided for @datePickerMonthMar.
  ///
  /// In ko, this message translates to:
  /// **'3월'**
  String get datePickerMonthMar;

  /// No description provided for @datePickerMonthApr.
  ///
  /// In ko, this message translates to:
  /// **'4월'**
  String get datePickerMonthApr;

  /// No description provided for @datePickerMonthMay.
  ///
  /// In ko, this message translates to:
  /// **'5월'**
  String get datePickerMonthMay;

  /// No description provided for @datePickerMonthJun.
  ///
  /// In ko, this message translates to:
  /// **'6월'**
  String get datePickerMonthJun;

  /// No description provided for @datePickerMonthJul.
  ///
  /// In ko, this message translates to:
  /// **'7월'**
  String get datePickerMonthJul;

  /// No description provided for @datePickerMonthAug.
  ///
  /// In ko, this message translates to:
  /// **'8월'**
  String get datePickerMonthAug;

  /// No description provided for @datePickerMonthSep.
  ///
  /// In ko, this message translates to:
  /// **'9월'**
  String get datePickerMonthSep;

  /// No description provided for @datePickerMonthOct.
  ///
  /// In ko, this message translates to:
  /// **'10월'**
  String get datePickerMonthOct;

  /// No description provided for @datePickerMonthNov.
  ///
  /// In ko, this message translates to:
  /// **'11월'**
  String get datePickerMonthNov;

  /// No description provided for @datePickerMonthDec.
  ///
  /// In ko, this message translates to:
  /// **'12월'**
  String get datePickerMonthDec;

  /// No description provided for @koreanDatePickerYear.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get koreanDatePickerYear;

  /// No description provided for @koreanDatePickerMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get koreanDatePickerMonth;

  /// No description provided for @koreanDatePickerDay.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get koreanDatePickerDay;

  /// No description provided for @recommendationViewDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 보기'**
  String get recommendationViewDetail;

  /// No description provided for @recommendationViewDetailSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'도서 정보 확인'**
  String get recommendationViewDetailSubtitle;

  /// No description provided for @recommendationStartReading.
  ///
  /// In ko, this message translates to:
  /// **'독서 시작'**
  String get recommendationStartReading;

  /// No description provided for @recommendationStartReadingSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이 책으로 독서 시작'**
  String get recommendationStartReadingSubtitle;

  /// No description provided for @recommendationBookstoreSelect.
  ///
  /// In ko, this message translates to:
  /// **'서점 선택'**
  String get recommendationBookstoreSelect;

  /// No description provided for @aiFeaturesTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 기능'**
  String get aiFeaturesTitle;

  /// No description provided for @bookRecommendButton.
  ///
  /// In ko, this message translates to:
  /// **'도서 추천'**
  String get bookRecommendButton;

  /// No description provided for @homeViewAllBooksMessage.
  ///
  /// In ko, this message translates to:
  /// **'전체 도서 보기'**
  String get homeViewAllBooksMessage;

  /// No description provided for @homeViewReadingMessage.
  ///
  /// In ko, this message translates to:
  /// **'읽는 중인 도서만 보기'**
  String get homeViewReadingMessage;

  /// No description provided for @homeViewAllBooks.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get homeViewAllBooks;

  /// No description provided for @homeViewReadingOnly.
  ///
  /// In ko, this message translates to:
  /// **'읽는 중만'**
  String get homeViewReadingOnly;

  /// No description provided for @myLibraryTabReading.
  ///
  /// In ko, this message translates to:
  /// **'읽는 중'**
  String get myLibraryTabReading;

  /// No description provided for @myLibraryTabReview.
  ///
  /// In ko, this message translates to:
  /// **'독후감'**
  String get myLibraryTabReview;

  /// No description provided for @myLibraryTabRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get myLibraryTabRecord;

  /// No description provided for @myLibrarySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'도서 검색...'**
  String get myLibrarySearchHint;

  /// No description provided for @myLibraryFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get myLibraryFilterAll;

  /// No description provided for @myLibraryNoSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 없음'**
  String get myLibraryNoSearchResults;

  /// No description provided for @myLibraryNoBooks.
  ///
  /// In ko, this message translates to:
  /// **'도서가 없습니다'**
  String get myLibraryNoBooks;

  /// No description provided for @myLibraryNoReviewBooks.
  ///
  /// In ko, this message translates to:
  /// **'독후감 도서 없음'**
  String get myLibraryNoReviewBooks;

  /// No description provided for @myLibraryNoRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get myLibraryNoRecords;

  /// No description provided for @myLibraryAiSearch.
  ///
  /// In ko, this message translates to:
  /// **'AI 검색'**
  String get myLibraryAiSearch;

  /// No description provided for @myLibraryFilterHighlight.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get myLibraryFilterHighlight;

  /// No description provided for @myLibraryFilterMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get myLibraryFilterMemo;

  /// No description provided for @myLibraryFilterPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get myLibraryFilterPhoto;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ko, this message translates to:
  /// **'독서 기록하기'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In ko, this message translates to:
  /// **'매일 독서 목표를 세우고 진행 상황을 추적하세요'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ko, this message translates to:
  /// **'인상적인 순간 저장'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In ko, this message translates to:
  /// **'책에서 하이라이트와 생각을 캡처하세요'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ko, this message translates to:
  /// **'목표 달성하기'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In ko, this message translates to:
  /// **'책을 완독하고 성과를 축하하세요'**
  String get onboardingDescription3;

  /// No description provided for @totalDaysFormat.
  ///
  /// In ko, this message translates to:
  /// **'총 {days}일'**
  String totalDaysFormat(int days);

  /// No description provided for @attemptOrdinal.
  ///
  /// In ko, this message translates to:
  /// **'{attempt}번째 도전'**
  String attemptOrdinal(int attempt);

  /// No description provided for @streakDaysAchieved.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 연속 달성!'**
  String streakDaysAchieved(int days);

  /// No description provided for @pagesRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{pages}페이지 남음'**
  String pagesRemaining(int pages);

  /// No description provided for @todayGoalWithPages.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표: {pages}p'**
  String todayGoalWithPages(int pages);

  /// No description provided for @pagesRemainingShort.
  ///
  /// In ko, this message translates to:
  /// **'{pages}p 남음'**
  String pagesRemainingShort(int pages);

  /// No description provided for @pagesRemainingWithDays.
  ///
  /// In ko, this message translates to:
  /// **' · D-{days}'**
  String pagesRemainingWithDays(int days);

  /// No description provided for @todayGoalChanged.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표가 {pages}p로 변경됨'**
  String todayGoalChanged(int pages);

  /// No description provided for @chartAiInsightTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 인사이트'**
  String get chartAiInsightTitle;

  /// No description provided for @chartAiInsightClearMemory.
  ///
  /// In ko, this message translates to:
  /// **'기억 삭제'**
  String get chartAiInsightClearMemory;

  /// No description provided for @chartAiInsightClearMemoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 기억을 삭제하시겠습니까?'**
  String get chartAiInsightClearMemoryTitle;

  /// No description provided for @chartAiInsightClearMemoryMessage.
  ///
  /// In ko, this message translates to:
  /// **'이전 분석이 삭제됩니다'**
  String get chartAiInsightClearMemoryMessage;

  /// No description provided for @chartAiInsightClearMemoryCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get chartAiInsightClearMemoryCancel;

  /// No description provided for @chartAiInsightClearMemoryConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get chartAiInsightClearMemoryConfirm;

  /// No description provided for @chartAiInsightAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get chartAiInsightAnalyzing;

  /// No description provided for @chartAiInsightUnknownError.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류 발생'**
  String get chartAiInsightUnknownError;

  /// No description provided for @chartAiInsightRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get chartAiInsightRetry;

  /// No description provided for @chartAiInsightMinBooksRequired.
  ///
  /// In ko, this message translates to:
  /// **'더 많은 책이 필요합니다'**
  String get chartAiInsightMinBooksRequired;

  /// No description provided for @chartAiInsightMinBooksMessage.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석을 위해 최소 {count}권을 완독해주세요'**
  String chartAiInsightMinBooksMessage(int count);

  /// No description provided for @chartAiInsightMinBooksHint.
  ///
  /// In ko, this message translates to:
  /// **'인사이트를 잠금 해제하려면 계속 읽어주세요'**
  String get chartAiInsightMinBooksHint;

  /// No description provided for @chartAiInsightSampleLabel.
  ///
  /// In ko, this message translates to:
  /// **'샘플'**
  String get chartAiInsightSampleLabel;

  /// No description provided for @chartAiInsightEmptyState.
  ///
  /// In ko, this message translates to:
  /// **'인사이트 없음'**
  String get chartAiInsightEmptyState;

  /// No description provided for @chartAiInsightGenerateButton.
  ///
  /// In ko, this message translates to:
  /// **'인사이트 생성'**
  String get chartAiInsightGenerateButton;

  /// No description provided for @chartAiInsightAlreadyAnalyzed.
  ///
  /// In ko, this message translates to:
  /// **'이미 분석됨'**
  String get chartAiInsightAlreadyAnalyzed;

  /// No description provided for @chartAnnualGoalTitle.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 독서 목표'**
  String chartAnnualGoalTitle(int year);

  /// No description provided for @chartAnnualGoalAchieved.
  ///
  /// In ko, this message translates to:
  /// **'{count}권 완독!'**
  String chartAnnualGoalAchieved(int count);

  /// No description provided for @chartAnnualGoalRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{count}권 남음'**
  String chartAnnualGoalRemaining(int count);

  /// No description provided for @chartAnnualGoalAchievedMessage.
  ///
  /// In ko, this message translates to:
  /// **'축하합니다! 목표를 달성했습니다!'**
  String get chartAnnualGoalAchievedMessage;

  /// No description provided for @chartAnnualGoalAheadMessage.
  ///
  /// In ko, this message translates to:
  /// **'{diff}권 앞서고 있습니다!'**
  String chartAnnualGoalAheadMessage(int diff);

  /// No description provided for @chartAnnualGoalMotivationMessage.
  ///
  /// In ko, this message translates to:
  /// **'목표 달성을 위해 계속 읽어주세요!'**
  String get chartAnnualGoalMotivationMessage;

  /// No description provided for @chartAnnualGoalSetGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get chartAnnualGoalSetGoal;

  /// No description provided for @chartAnnualGoalSetGoalMessage.
  ///
  /// In ko, this message translates to:
  /// **'연간 독서 목표를 설정하세요'**
  String get chartAnnualGoalSetGoalMessage;

  /// No description provided for @chartCompletionRateLabel.
  ///
  /// In ko, this message translates to:
  /// **'완독률'**
  String get chartCompletionRateLabel;

  /// No description provided for @chartCompletionRateBooks.
  ///
  /// In ko, this message translates to:
  /// **'{count}권'**
  String chartCompletionRateBooks(int count);

  /// No description provided for @chartAbandonRateLabel.
  ///
  /// In ko, this message translates to:
  /// **'포기율'**
  String get chartAbandonRateLabel;

  /// No description provided for @chartAbandonRateBooks.
  ///
  /// In ko, this message translates to:
  /// **'{count}권'**
  String chartAbandonRateBooks(int count);

  /// No description provided for @chartRetrySuccessRateLabel.
  ///
  /// In ko, this message translates to:
  /// **'재도전 성공률'**
  String get chartRetrySuccessRateLabel;

  /// No description provided for @chartRetrySuccessRateBooks.
  ///
  /// In ko, this message translates to:
  /// **'성공한 재도전'**
  String get chartRetrySuccessRateBooks;

  /// No description provided for @chartCompletionRateTitle.
  ///
  /// In ko, this message translates to:
  /// **'완독률'**
  String get chartCompletionRateTitle;

  /// No description provided for @chartCompletionRateSummaryStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작함'**
  String get chartCompletionRateSummaryStarted;

  /// No description provided for @chartCompletionRateSummaryCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료함'**
  String get chartCompletionRateSummaryCompleted;

  /// No description provided for @chartCompletionRateSummaryInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get chartCompletionRateSummaryInProgress;

  /// No description provided for @chartCompletionRateSummaryAbandoned.
  ///
  /// In ko, this message translates to:
  /// **'포기함'**
  String get chartCompletionRateSummaryAbandoned;

  /// No description provided for @chartCompletionRateEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'완독 데이터 없음'**
  String get chartCompletionRateEmptyMessage;

  /// No description provided for @chartCompletionRateEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'책을 완독하면 통계를 확인할 수 있습니다'**
  String get chartCompletionRateEmptyHint;

  /// No description provided for @chartGenreAnalysisTitle.
  ///
  /// In ko, this message translates to:
  /// **'장르 분석'**
  String get chartGenreAnalysisTitle;

  /// No description provided for @chartGenreAnalysisTotalCompleted.
  ///
  /// In ko, this message translates to:
  /// **'총 완독'**
  String get chartGenreAnalysisTotalCompleted;

  /// No description provided for @chartGenreAnalysisDiversity.
  ///
  /// In ko, this message translates to:
  /// **'장르 다양성'**
  String get chartGenreAnalysisDiversity;

  /// No description provided for @chartGenreAnalysisEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'장르 데이터 없음'**
  String get chartGenreAnalysisEmptyMessage;

  /// No description provided for @chartGenreAnalysisEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'책을 완독하면 분석을 확인할 수 있습니다'**
  String get chartGenreAnalysisEmptyHint;

  /// No description provided for @chartHighlightStatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 통계'**
  String get chartHighlightStatsTitle;

  /// No description provided for @chartHighlightStatsHighlights.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get chartHighlightStatsHighlights;

  /// No description provided for @chartHighlightStatsMemos.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get chartHighlightStatsMemos;

  /// No description provided for @chartHighlightStatsPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get chartHighlightStatsPhotos;

  /// No description provided for @chartHighlightStatsByGenre.
  ///
  /// In ko, this message translates to:
  /// **'장르별'**
  String get chartHighlightStatsByGenre;

  /// No description provided for @chartHighlightStatsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트 없음'**
  String get chartHighlightStatsEmptyMessage;

  /// No description provided for @chartHighlightStatsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'독서 중 하이라이트를 추가해보세요'**
  String get chartHighlightStatsEmptyHint;

  /// No description provided for @chartMonthlyBooksTitle.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 월별 도서'**
  String chartMonthlyBooksTitle(int year);

  /// No description provided for @chartMonthlyBooksThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get chartMonthlyBooksThisMonth;

  /// No description provided for @chartMonthlyBooksLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get chartMonthlyBooksLastMonth;

  /// No description provided for @chartMonthlyBooksChange.
  ///
  /// In ko, this message translates to:
  /// **'변화'**
  String get chartMonthlyBooksChange;

  /// No description provided for @chartMonthlyBooksTooltip.
  ///
  /// In ko, this message translates to:
  /// **'{month}: {count}권'**
  String chartMonthlyBooksTooltip(int month, int count);

  /// No description provided for @chartReadingStreakTitle.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 독서 활동'**
  String chartReadingStreakTitle(int year);

  /// No description provided for @chartReadingStreakDaysRead.
  ///
  /// In ko, this message translates to:
  /// **'읽은 날'**
  String get chartReadingStreakDaysRead;

  /// No description provided for @chartReadingStreakTotalPages.
  ///
  /// In ko, this message translates to:
  /// **'총 페이지'**
  String get chartReadingStreakTotalPages;

  /// No description provided for @chartReadingStreakDailyAverage.
  ///
  /// In ko, this message translates to:
  /// **'일 평균'**
  String get chartReadingStreakDailyAverage;

  /// No description provided for @chartReadingStreakTooltip.
  ///
  /// In ko, this message translates to:
  /// **'{month}/{day}: {pages}p'**
  String chartReadingStreakTooltip(int month, int day, int pages);

  /// No description provided for @chartReadingStreakMonthJan.
  ///
  /// In ko, this message translates to:
  /// **'1월'**
  String get chartReadingStreakMonthJan;

  /// No description provided for @chartReadingStreakMonthMar.
  ///
  /// In ko, this message translates to:
  /// **'3월'**
  String get chartReadingStreakMonthMar;

  /// No description provided for @chartReadingStreakMonthMay.
  ///
  /// In ko, this message translates to:
  /// **'5월'**
  String get chartReadingStreakMonthMay;

  /// No description provided for @chartReadingStreakMonthJul.
  ///
  /// In ko, this message translates to:
  /// **'7월'**
  String get chartReadingStreakMonthJul;

  /// No description provided for @chartReadingStreakMonthSep.
  ///
  /// In ko, this message translates to:
  /// **'9월'**
  String get chartReadingStreakMonthSep;

  /// No description provided for @chartReadingStreakMonthNov.
  ///
  /// In ko, this message translates to:
  /// **'11월'**
  String get chartReadingStreakMonthNov;

  /// No description provided for @chartReadingStreakLess.
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get chartReadingStreakLess;

  /// No description provided for @chartReadingStreakMore.
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get chartReadingStreakMore;

  /// No description provided for @chartErrorLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'차트 로딩 실패'**
  String get chartErrorLoadFailed;

  /// No description provided for @chartErrorRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get chartErrorRetry;

  /// No description provided for @chartAiInsight.
  ///
  /// In ko, this message translates to:
  /// **'AI 인사이트'**
  String get chartAiInsight;

  /// No description provided for @chartCompletionRate.
  ///
  /// In ko, this message translates to:
  /// **'완독률'**
  String get chartCompletionRate;

  /// No description provided for @chartRecordsHighlights.
  ///
  /// In ko, this message translates to:
  /// **'기록 & 하이라이트'**
  String get chartRecordsHighlights;

  /// No description provided for @chartGenreAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'장르 분석'**
  String get chartGenreAnalysis;

  /// No description provided for @chartReadingStats.
  ///
  /// In ko, this message translates to:
  /// **'독서 통계'**
  String get chartReadingStats;

  /// No description provided for @chartTotalPages.
  ///
  /// In ko, this message translates to:
  /// **'총 페이지'**
  String get chartTotalPages;

  /// No description provided for @chartDailyAvgPages.
  ///
  /// In ko, this message translates to:
  /// **'일 평균'**
  String get chartDailyAvgPages;

  /// No description provided for @chartMaxDaily.
  ///
  /// In ko, this message translates to:
  /// **'최대 일일'**
  String get chartMaxDaily;

  /// No description provided for @chartConsecutiveDays.
  ///
  /// In ko, this message translates to:
  /// **'연속 일수'**
  String get chartConsecutiveDays;

  /// No description provided for @chartMinDaily.
  ///
  /// In ko, this message translates to:
  /// **'최소 일일'**
  String get chartMinDaily;

  /// No description provided for @chartTodayGoal.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표'**
  String get chartTodayGoal;

  /// No description provided for @chartDailyPages.
  ///
  /// In ko, this message translates to:
  /// **'일일 페이지'**
  String get chartDailyPages;

  /// No description provided for @chartCumulativePages.
  ///
  /// In ko, this message translates to:
  /// **'누적 페이지'**
  String get chartCumulativePages;

  /// No description provided for @chartDailyReadPages.
  ///
  /// In ko, this message translates to:
  /// **'일별 읽은 페이지'**
  String get chartDailyReadPages;

  /// No description provided for @chartReadingProgress.
  ///
  /// In ko, this message translates to:
  /// **'독서 진행'**
  String get chartReadingProgress;

  /// No description provided for @chartNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터 없음'**
  String get chartNoData;

  /// No description provided for @chartNoReadingRecords.
  ///
  /// In ko, this message translates to:
  /// **'독서 기록 없음'**
  String get chartNoReadingRecords;

  /// No description provided for @readingProgressTitle.
  ///
  /// In ko, this message translates to:
  /// **'독서 진행'**
  String get readingProgressTitle;

  /// No description provided for @readingProgressLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'진행 로딩 실패'**
  String get readingProgressLoadFailed;

  /// No description provided for @readingProgressNoRecords.
  ///
  /// In ko, this message translates to:
  /// **'진행 기록 없음'**
  String get readingProgressNoRecords;

  /// No description provided for @readingGoalSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 독서 목표'**
  String readingGoalSheetTitle(int year);

  /// No description provided for @readingGoalSheetQuestion.
  ///
  /// In ko, this message translates to:
  /// **'몇 권의 책을 읽고 싶으신가요?'**
  String get readingGoalSheetQuestion;

  /// No description provided for @readingGoalSheetRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get readingGoalSheetRecommended;

  /// No description provided for @readingGoalSheetBooks.
  ///
  /// In ko, this message translates to:
  /// **'권'**
  String get readingGoalSheetBooks;

  /// No description provided for @readingGoalSheetCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get readingGoalSheetCustom;

  /// No description provided for @readingGoalSheetHint.
  ///
  /// In ko, this message translates to:
  /// **'숫자 입력'**
  String get readingGoalSheetHint;

  /// No description provided for @readingGoalSheetCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get readingGoalSheetCancel;

  /// No description provided for @readingGoalSheetUpdate.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get readingGoalSheetUpdate;

  /// No description provided for @readingGoalSheetSet.
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get readingGoalSheetSet;

  /// No description provided for @readingGoalSheetBooksPerMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 {books}권'**
  String readingGoalSheetBooksPerMonth(String books);

  /// No description provided for @readingGoalSheetMotivation1.
  ///
  /// In ko, this message translates to:
  /// **'좋은 시작이에요!'**
  String get readingGoalSheetMotivation1;

  /// No description provided for @readingGoalSheetMotivation2.
  ///
  /// In ko, this message translates to:
  /// **'좋은 페이스!'**
  String get readingGoalSheetMotivation2;

  /// No description provided for @readingGoalSheetMotivation3.
  ///
  /// In ko, this message translates to:
  /// **'야심찬 독서가!'**
  String get readingGoalSheetMotivation3;

  /// No description provided for @readingGoalSheetMotivation4.
  ///
  /// In ko, this message translates to:
  /// **'도서 매니아!'**
  String get readingGoalSheetMotivation4;

  /// No description provided for @readingGoalSheetMotivation5.
  ///
  /// In ko, this message translates to:
  /// **'독서 챔피언!'**
  String get readingGoalSheetMotivation5;

  /// No description provided for @readingStartPriority.
  ///
  /// In ko, this message translates to:
  /// **'우선순위'**
  String get readingStartPriority;

  /// No description provided for @readingStartAiRecommendation.
  ///
  /// In ko, this message translates to:
  /// **'AI 추천'**
  String get readingStartAiRecommendation;

  /// No description provided for @readingStartAiRecommendationDesc.
  ///
  /// In ko, this message translates to:
  /// **'{userName}님의 독서 패턴을 기반으로 추천하는 도서'**
  String readingStartAiRecommendationDesc(String userName);

  /// No description provided for @readingStartConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get readingStartConfirm;

  /// No description provided for @readingStartPages.
  ///
  /// In ko, this message translates to:
  /// **'{pages}페이지'**
  String readingStartPages(int pages);

  /// No description provided for @readingStartPlannedDate.
  ///
  /// In ko, this message translates to:
  /// **'시작 예정일'**
  String get readingStartPlannedDate;

  /// No description provided for @readingStartToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get readingStartToday;

  /// No description provided for @readingStartTargetDate.
  ///
  /// In ko, this message translates to:
  /// **'목표일'**
  String get readingStartTargetDate;

  /// No description provided for @readingStartTargetDateNote.
  ///
  /// In ko, this message translates to:
  /// **'목표일은 나중에 변경할 수 있습니다'**
  String get readingStartTargetDateNote;

  /// No description provided for @readingStartSaveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get readingStartSaveError;

  /// No description provided for @readingStartReserve.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get readingStartReserve;

  /// No description provided for @readingStartBegin.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get readingStartBegin;

  /// No description provided for @scheduleTargetDays.
  ///
  /// In ko, this message translates to:
  /// **'목표 일수'**
  String get scheduleTargetDays;

  /// No description provided for @scheduleTargetDaysValue.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String scheduleTargetDaysValue(int days);

  /// No description provided for @scheduleDailyGoal.
  ///
  /// In ko, this message translates to:
  /// **'일일 목표'**
  String get scheduleDailyGoal;

  /// No description provided for @readingStatusLabel.
  ///
  /// In ko, this message translates to:
  /// **'독서 상태'**
  String get readingStatusLabel;

  /// No description provided for @readingStatusPlanned.
  ///
  /// In ko, this message translates to:
  /// **'읽을 예정'**
  String get readingStatusPlanned;

  /// No description provided for @readingStatusStartNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 시작'**
  String get readingStatusStartNow;

  /// No description provided for @recallSearchAllRecords.
  ///
  /// In ko, this message translates to:
  /// **'전체 기록 검색'**
  String get recallSearchAllRecords;

  /// No description provided for @recallSearchingAllBooks.
  ///
  /// In ko, this message translates to:
  /// **'모든 책에서 검색 중...'**
  String get recallSearchingAllBooks;

  /// No description provided for @recallSearchAllReadingRecords.
  ///
  /// In ko, this message translates to:
  /// **'모든 독서 기록 검색'**
  String get recallSearchAllReadingRecords;

  /// No description provided for @recallAiFindsScatteredRecords.
  ///
  /// In ko, this message translates to:
  /// **'AI가 여러 책에서 흩어진 기록을 찾습니다'**
  String get recallAiFindsScatteredRecords;

  /// No description provided for @recallAiAnswer.
  ///
  /// In ko, this message translates to:
  /// **'AI 답변'**
  String get recallAiAnswer;

  /// No description provided for @recallReferencedRecords.
  ///
  /// In ko, this message translates to:
  /// **'참조된 기록'**
  String get recallReferencedRecords;

  /// No description provided for @recallMoreBooks.
  ///
  /// In ko, this message translates to:
  /// **'{count}권 더 보기'**
  String recallMoreBooks(int count);

  /// No description provided for @recallRecordCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록'**
  String recallRecordCount(int count);

  /// No description provided for @recallSearchMyRecords.
  ///
  /// In ko, this message translates to:
  /// **'내 기록 검색'**
  String get recallSearchMyRecords;

  /// No description provided for @recallSearchingYourRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록 검색 중...'**
  String get recallSearchingYourRecords;

  /// No description provided for @recallSuggestedQuestion1.
  ///
  /// In ko, this message translates to:
  /// **'핵심 내용은 무엇이었나요?'**
  String get recallSuggestedQuestion1;

  /// No description provided for @recallSuggestedQuestion2.
  ///
  /// In ko, this message translates to:
  /// **'습관에 대해 뭐라고 했나요?'**
  String get recallSuggestedQuestion2;

  /// No description provided for @recallSuggestedQuestion3.
  ///
  /// In ko, this message translates to:
  /// **'인상적인 문구가 있나요?'**
  String get recallSuggestedQuestion3;

  /// No description provided for @recallSuggestedQuestion4.
  ///
  /// In ko, this message translates to:
  /// **'가장 영감을 준 것은?'**
  String get recallSuggestedQuestion4;

  /// No description provided for @recallSearchCurious.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 내용을 검색해보세요'**
  String get recallSearchCurious;

  /// No description provided for @recallFindInRecords.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트, 메모, 사진에서 찾기'**
  String get recallFindInRecords;

  /// No description provided for @recallCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get recallCopy;
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
