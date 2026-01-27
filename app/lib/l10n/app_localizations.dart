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
