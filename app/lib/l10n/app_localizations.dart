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
