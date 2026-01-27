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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BookGolas'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonComplete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonComplete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get commonStart;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @booksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String booksCount(num count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(num count);

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pagesCount(num count);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @timeAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePm;

  /// No description provided for @unitYear.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unitYear;

  /// No description provided for @unitMonth.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unitMonth;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unitDay;

  /// No description provided for @unitHour.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unitHour;

  /// No description provided for @unitMinute.
  ///
  /// In en, this message translates to:
  /// **''**
  String get unitMinute;

  /// No description provided for @statusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get statusReading;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'To Read'**
  String get statusPlanned;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusReread.
  ///
  /// In en, this message translates to:
  /// **'Reread'**
  String get statusReread;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @contentTypeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get contentTypeHighlight;

  /// No description provided for @contentTypeMemo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get contentTypeMemo;

  /// No description provided for @contentTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get contentTypePhoto;

  /// No description provided for @languageSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingLabel;

  /// No description provided for @homeBookList.
  ///
  /// In en, this message translates to:
  /// **'Book List'**
  String get homeBookList;

  /// No description provided for @homeNoReadingBooks.
  ///
  /// In en, this message translates to:
  /// **'No books in progress. Please register a book first.'**
  String get homeNoReadingBooks;

  /// No description provided for @homeNoReadingBooksShort.
  ///
  /// In en, this message translates to:
  /// **'No books in progress'**
  String get homeNoReadingBooksShort;

  /// No description provided for @homeViewAllBooks.
  ///
  /// In en, this message translates to:
  /// **'View all books'**
  String get homeViewAllBooks;

  /// No description provided for @homeViewReadingOnly.
  ///
  /// In en, this message translates to:
  /// **'View reading only'**
  String get homeViewReadingOnly;

  /// No description provided for @homeViewAllBooksMessage.
  ///
  /// In en, this message translates to:
  /// **'Switched to view all books.'**
  String get homeViewAllBooksMessage;

  /// No description provided for @homeViewReadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Switched to view reading books.'**
  String get homeViewReadingMessage;

  /// No description provided for @bookListTabReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get bookListTabReading;

  /// No description provided for @bookListTabPlanned.
  ///
  /// In en, this message translates to:
  /// **'To Read'**
  String get bookListTabPlanned;

  /// No description provided for @bookListTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookListTabCompleted;

  /// No description provided for @bookListTabReread.
  ///
  /// In en, this message translates to:
  /// **'Reread'**
  String get bookListTabReread;

  /// No description provided for @bookListTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bookListTabAll;

  /// No description provided for @bookListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bookListFilterAll;

  /// No description provided for @bookListErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get bookListErrorLoadFailed;

  /// No description provided for @bookListErrorNetworkCheck.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection'**
  String get bookListErrorNetworkCheck;

  /// No description provided for @bookListEmptyReading.
  ///
  /// In en, this message translates to:
  /// **'No books in progress'**
  String get bookListEmptyReading;

  /// No description provided for @bookListEmptyPlanned.
  ///
  /// In en, this message translates to:
  /// **'No books to read'**
  String get bookListEmptyPlanned;

  /// No description provided for @bookListEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed books'**
  String get bookListEmptyCompleted;

  /// No description provided for @bookListEmptyPaused.
  ///
  /// In en, this message translates to:
  /// **'No paused books'**
  String get bookListEmptyPaused;

  /// No description provided for @bookListEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No reading started yet'**
  String get bookListEmptyAll;

  /// No description provided for @bookDetailTabRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get bookDetailTabRecord;

  /// No description provided for @bookDetailTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bookDetailTabHistory;

  /// No description provided for @bookDetailTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get bookDetailTabReview;

  /// No description provided for @bookDetailTabDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get bookDetailTabDetail;

  /// No description provided for @bookDetailStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get bookDetailStartDate;

  /// No description provided for @bookDetailTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target Date'**
  String get bookDetailTargetDate;

  /// No description provided for @bookDetailReviewWritten.
  ///
  /// In en, this message translates to:
  /// **'Written'**
  String get bookDetailReviewWritten;

  /// No description provided for @bookDetailReviewNotWritten.
  ///
  /// In en, this message translates to:
  /// **'Not written yet'**
  String get bookDetailReviewNotWritten;

  /// No description provided for @bookDetailLegendAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get bookDetailLegendAchieved;

  /// No description provided for @bookDetailLegendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get bookDetailLegendMissed;

  /// No description provided for @bookDetailLegendScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get bookDetailLegendScheduled;

  /// No description provided for @bookDetailLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bookDetailLater;

  /// No description provided for @myLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibraryTitle;

  /// No description provided for @myLibraryTabReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get myLibraryTabReading;

  /// No description provided for @myLibraryTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get myLibraryTabReview;

  /// No description provided for @myLibraryTabRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get myLibraryTabRecord;

  /// No description provided for @myLibrarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or author'**
  String get myLibrarySearchHint;

  /// No description provided for @myLibraryNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get myLibraryNoSearchResults;

  /// No description provided for @myLibraryNoBooks.
  ///
  /// In en, this message translates to:
  /// **'No books registered'**
  String get myLibraryNoBooks;

  /// No description provided for @myLibraryNoReviewBooks.
  ///
  /// In en, this message translates to:
  /// **'No books with reviews'**
  String get myLibraryNoReviewBooks;

  /// No description provided for @myLibraryNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get myLibraryNoRecords;

  /// No description provided for @myLibraryAiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Search All Records'**
  String get myLibraryAiSearch;

  /// No description provided for @myLibraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myLibraryFilterAll;

  /// No description provided for @myLibraryFilterHighlight.
  ///
  /// In en, this message translates to:
  /// **'✨ Highlight'**
  String get myLibraryFilterHighlight;

  /// No description provided for @myLibraryFilterMemo.
  ///
  /// In en, this message translates to:
  /// **'📝 Memo'**
  String get myLibraryFilterMemo;

  /// No description provided for @myLibraryFilterPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get myLibraryFilterPhoto;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reading Stats'**
  String get chartTitle;

  /// No description provided for @chartTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get chartTabOverview;

  /// No description provided for @chartTabAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get chartTabAnalysis;

  /// No description provided for @chartTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get chartTabActivity;

  /// No description provided for @chartPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get chartPeriodDaily;

  /// No description provided for @chartPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get chartPeriodWeekly;

  /// No description provided for @chartPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get chartPeriodMonthly;

  /// No description provided for @chartDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get chartDailyAverage;

  /// No description provided for @chartIncrease.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chartIncrease;

  /// No description provided for @chartLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get chartLess;

  /// No description provided for @chartMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chartMore;

  /// No description provided for @chartErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get chartErrorLoadFailed;

  /// No description provided for @chartErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chartErrorRetry;

  /// No description provided for @chartTotalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages Read'**
  String get chartTotalPages;

  /// No description provided for @chartDailyAvgPages.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get chartDailyAvgPages;

  /// No description provided for @chartMaxDaily.
  ///
  /// In en, this message translates to:
  /// **'Best Record'**
  String get chartMaxDaily;

  /// No description provided for @chartMinDaily.
  ///
  /// In en, this message translates to:
  /// **'Lowest Record'**
  String get chartMinDaily;

  /// No description provided for @chartConsecutiveDays.
  ///
  /// In en, this message translates to:
  /// **'Consecutive Days'**
  String get chartConsecutiveDays;

  /// No description provided for @chartTodayGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get chartTodayGoal;

  /// No description provided for @chartReadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading Progress'**
  String get chartReadingProgress;

  /// No description provided for @chartDailyPages.
  ///
  /// In en, this message translates to:
  /// **'Daily Pages'**
  String get chartDailyPages;

  /// No description provided for @chartCumulativePages.
  ///
  /// In en, this message translates to:
  /// **'Cumulative Pages'**
  String get chartCumulativePages;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get chartNoData;

  /// No description provided for @chartDailyReadPages.
  ///
  /// In en, this message translates to:
  /// **'Pages Read'**
  String get chartDailyReadPages;

  /// No description provided for @chartReadingStats.
  ///
  /// In en, this message translates to:
  /// **'Reading Statistics'**
  String get chartReadingStats;

  /// No description provided for @chartAiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get chartAiInsight;

  /// No description provided for @chartCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get chartCompletionRate;

  /// No description provided for @chartRecordsHighlights.
  ///
  /// In en, this message translates to:
  /// **'Records/Highlights'**
  String get chartRecordsHighlights;

  /// No description provided for @chartGenreAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Genre Analysis'**
  String get chartGenreAnalysis;

  /// No description provided for @chartNoReadingRecords.
  ///
  /// In en, this message translates to:
  /// **'No reading records'**
  String get chartNoReadingRecords;

  /// No description provided for @myPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My Page'**
  String get myPageTitle;

  /// No description provided for @myPageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get myPageSettings;

  /// No description provided for @myPageChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get myPageChangeAvatar;

  /// No description provided for @myPageLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get myPageLogout;

  /// No description provided for @myPageDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get myPageDeleteAccount;

  /// No description provided for @myPageDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?\n\nThis action cannot be undone, and all data will be permanently deleted.'**
  String get myPageDeleteAccountConfirm;

  /// No description provided for @myPageDeleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account successfully deleted.'**
  String get myPageDeleteAccountSuccess;

  /// No description provided for @myPageDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get myPageDeleteAccountFailed;

  /// Error message when deleting account
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String myPageDeleteAccountError(String error);

  /// No description provided for @myPageNotificationTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Notification Time'**
  String get myPageNotificationTimeTitle;

  /// No description provided for @myPageNoNickname.
  ///
  /// In en, this message translates to:
  /// **'No nickname'**
  String get myPageNoNickname;

  /// No description provided for @myPageNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get myPageNicknameHint;

  /// No description provided for @myPageDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get myPageDarkMode;

  /// No description provided for @myPageDailyReadingNotification.
  ///
  /// In en, this message translates to:
  /// **'Daily Reading Goal Notification'**
  String get myPageDailyReadingNotification;

  /// Notification time display
  ///
  /// In en, this message translates to:
  /// **'Daily notification at {time}'**
  String myPageNotificationTime(String time);

  /// No description provided for @myPageNoNotification.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get myPageNoNotification;

  /// No description provided for @myPageNotificationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get myPageNotificationEnabled;

  /// No description provided for @myPageNotificationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get myPageNotificationDisabled;

  /// No description provided for @myPageNotificationChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change notification settings'**
  String get myPageNotificationChangeFailed;

  /// No description provided for @myPageTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification (in 30 seconds)'**
  String get myPageTestNotification;

  /// No description provided for @myPageTestNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification will be sent in 30 seconds!'**
  String get myPageTestNotificationSent;

  /// No description provided for @myPageAvatarChanged.
  ///
  /// In en, this message translates to:
  /// **'Profile image changed'**
  String get myPageAvatarChanged;

  /// Error message when changing avatar
  ///
  /// In en, this message translates to:
  /// **'Failed to change profile image: {error}'**
  String myPageAvatarChangeFailed(String error);

  /// No description provided for @loginAppName.
  ///
  /// In en, this message translates to:
  /// **'BookGolas'**
  String get loginAppName;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get loginNicknameLabel;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOrDivider;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginSignupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignupButton;

  /// No description provided for @loginDescriptionSignIn.
  ///
  /// In en, this message translates to:
  /// **'One page a day,\nwe support your reading'**
  String get loginDescriptionSignIn;

  /// No description provided for @loginDescriptionSignUp.
  ///
  /// In en, this message translates to:
  /// **'Start your reading habit\nwith BookGolas'**
  String get loginDescriptionSignUp;

  /// No description provided for @loginDescriptionForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a password reset link\nto your registered email'**
  String get loginDescriptionForgotPassword;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6 or more characters'**
  String get loginPasswordHint;

  /// No description provided for @loginNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Name to use in the app'**
  String get loginNicknameHint;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginPasswordTooShort;

  /// No description provided for @loginNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your nickname'**
  String get loginNicknameRequired;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get loginNoAccount;

  /// No description provided for @loginHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get loginHaveAccount;

  /// No description provided for @loginBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get loginBackToSignIn;

  /// No description provided for @loginSaveEmail.
  ///
  /// In en, this message translates to:
  /// **'Save email'**
  String get loginSaveEmail;

  /// No description provided for @loginSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sign up complete. Please check your email.'**
  String get loginSignupSuccess;

  /// No description provided for @loginResetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get loginResetPasswordSuccess;

  /// No description provided for @loginUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get loginUnexpectedError;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email verification is not complete.'**
  String get loginErrorEmailNotConfirmed;

  /// No description provided for @loginErrorEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get loginErrorEmailAlreadyRegistered;

  /// No description provided for @loginErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginErrorPasswordTooShort;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Review'**
  String get reviewTitle;

  /// No description provided for @reviewSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get reviewSave;

  /// No description provided for @reviewReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get reviewReplace;

  /// No description provided for @reviewExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get reviewExit;

  /// No description provided for @reviewDraftLoaded.
  ///
  /// In en, this message translates to:
  /// **'Draft loaded successfully.'**
  String get reviewDraftLoaded;

  /// No description provided for @reviewCopied.
  ///
  /// In en, this message translates to:
  /// **'Review copied.'**
  String get reviewCopied;

  /// No description provided for @reviewBookNotFound.
  ///
  /// In en, this message translates to:
  /// **'Book information not found.'**
  String get reviewBookNotFound;

  /// No description provided for @reviewSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get reviewSaveFailed;

  /// No description provided for @reviewSaveError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving.'**
  String get reviewSaveError;

  /// No description provided for @reviewReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved content.\nDo you want to replace it with AI draft?'**
  String get reviewReplaceConfirm;

  /// No description provided for @reviewReplaceButton.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get reviewReplaceButton;

  /// No description provided for @reviewAIDraftGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI draft generated. Feel free to edit!'**
  String get reviewAIDraftGenerated;

  /// No description provided for @reviewAIDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate AI draft. Please try again.'**
  String get reviewAIDraftFailed;

  /// No description provided for @reviewAIDraftError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while generating AI draft.'**
  String get reviewAIDraftError;

  /// No description provided for @reviewSaveComplete.
  ///
  /// In en, this message translates to:
  /// **'Review saved!'**
  String get reviewSaveComplete;

  /// No description provided for @reviewSaveCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your saved review can be found in the \'Review\' tab or\n\'My Library > Review\'.'**
  String get reviewSaveCompleteMessage;

  /// No description provided for @reviewExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop writing and exit?'**
  String get reviewExitConfirm;

  /// No description provided for @reviewExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your draft will be saved automatically.'**
  String get reviewExitMessage;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write freely about your thoughts, impressive parts, and inspiration from this book.'**
  String get reviewHint;

  /// No description provided for @readingStartSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set Start Date'**
  String get readingStartSetDate;

  /// No description provided for @readingStartUndetermined.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get readingStartUndetermined;

  /// No description provided for @readingStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get readingStartTitle;

  /// No description provided for @readingStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for a book to start reading'**
  String get readingStartSubtitle;

  /// No description provided for @readingStartNoResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get readingStartNoResults;

  /// No description provided for @readingStartAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing reading patterns...'**
  String get readingStartAnalyzing;

  /// No description provided for @readingStartAiRecommendation.
  ///
  /// In en, this message translates to:
  /// **'AI Personalized Recommendations'**
  String get readingStartAiRecommendation;

  /// AI recommendation description
  ///
  /// In en, this message translates to:
  /// **'Books recommended based on {userName}\'s reading patterns'**
  String readingStartAiRecommendationDesc(String userName);

  /// No description provided for @readingStartSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get readingStartSearchHint;

  /// No description provided for @readingStartSelectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Selection Complete'**
  String get readingStartSelectionComplete;

  /// No description provided for @readingStartConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get readingStartConfirm;

  /// Total pages display
  ///
  /// In en, this message translates to:
  /// **'{totalPages} pages'**
  String readingStartPages(num totalPages);

  /// No description provided for @readingStartPlannedDate.
  ///
  /// In en, this message translates to:
  /// **'Planned Reading Start Date'**
  String get readingStartPlannedDate;

  /// No description provided for @readingStartToday.
  ///
  /// In en, this message translates to:
  /// **'Starting today'**
  String get readingStartToday;

  /// No description provided for @readingStartTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target Deadline'**
  String get readingStartTargetDate;

  /// No description provided for @readingStartTargetDateNote.
  ///
  /// In en, this message translates to:
  /// **'You can change the target date even after starting to read'**
  String get readingStartTargetDateNote;

  /// No description provided for @readingStartSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save reading information'**
  String get readingStartSaveError;

  /// No description provided for @readingStartReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve Reading'**
  String get readingStartReserve;

  /// No description provided for @readingStartBegin.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get readingStartBegin;

  /// No description provided for @dialogOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get dialogOpacity;

  /// No description provided for @dialogThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get dialogThickness;

  /// No description provided for @dialogTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get dialogTakePhoto;

  /// No description provided for @dialogReplaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get dialogReplaceImage;

  /// No description provided for @dialogViewFull.
  ///
  /// In en, this message translates to:
  /// **'View Full'**
  String get dialogViewFull;

  /// No description provided for @dialogCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get dialogCopy;

  /// No description provided for @dialogEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dialogEdit;

  /// No description provided for @dialogSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get dialogSaved;

  /// No description provided for @dialogSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get dialogSaving;

  /// No description provided for @dialogUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get dialogUpload;

  /// No description provided for @dialogSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get dialogSelect;

  /// No description provided for @dialogApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dialogApply;

  /// No description provided for @dialogExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get dialogExtract;

  /// No description provided for @dialogOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get dialogOkay;

  /// No description provided for @dialogExtractIt.
  ///
  /// In en, this message translates to:
  /// **'Extract It'**
  String get dialogExtractIt;

  /// No description provided for @dialogThinkAboutIt.
  ///
  /// In en, this message translates to:
  /// **'Think About It'**
  String get dialogThinkAboutIt;

  /// No description provided for @genreNovel.
  ///
  /// In en, this message translates to:
  /// **'Novel'**
  String get genreNovel;

  /// No description provided for @genreLiterature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get genreLiterature;

  /// No description provided for @genreSelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-Help'**
  String get genreSelfHelp;

  /// No description provided for @genreBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get genreBusiness;

  /// No description provided for @genreHumanities.
  ///
  /// In en, this message translates to:
  /// **'Humanities'**
  String get genreHumanities;

  /// No description provided for @genreScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get genreScience;

  /// No description provided for @genreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get genreHistory;

  /// No description provided for @genreEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get genreEssay;

  /// No description provided for @genrePoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get genrePoetry;

  /// No description provided for @genreComic.
  ///
  /// In en, this message translates to:
  /// **'Comic'**
  String get genreComic;

  /// No description provided for @genreUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get genreUncategorized;

  /// No description provided for @errorInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed'**
  String get errorInitFailed;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get errorLoadFailed;

  /// No description provided for @errorNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get errorNoRecords;

  /// No description provided for @loadingInit.
  ///
  /// In en, this message translates to:
  /// **'Initializing app...'**
  String get loadingInit;

  /// No description provided for @calendarMonthSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get calendarMonthSelect;

  /// No description provided for @calendarPagesRead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page read} other{{count} pages read}}'**
  String calendarPagesRead(num count);

  /// No description provided for @calendarCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get calendarCompleted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Record Your Own Reading Journey'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In en, this message translates to:
  /// **'Register books you want to read,\nand manage your reading goals and progress at a glance.'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Search Your Reading Records with AI'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In en, this message translates to:
  /// **'Search for content you remember,\nand AI will find related notes and books for you.'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Get Book Recommendations'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In en, this message translates to:
  /// **'Based on the books you\'ve read so far,\nAI recommends books tailored to your taste.'**
  String get onboardingDescription3;

  /// No description provided for @readingProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Progress History'**
  String get readingProgressTitle;

  /// No description provided for @readingProgressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load progress'**
  String get readingProgressLoadFailed;

  /// No description provided for @readingProgressNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No progress records'**
  String get readingProgressNoRecords;

  /// No description provided for @barcodeScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan ISBN Barcode'**
  String get barcodeScannerTitle;

  /// No description provided for @barcodeScannerHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the ISBN barcode on the back of the book'**
  String get barcodeScannerHint;

  /// No description provided for @scannerErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required\nPlease allow camera access in settings'**
  String get scannerErrorPermissionDenied;

  /// No description provided for @scannerErrorInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera'**
  String get scannerErrorInitializing;

  /// No description provided for @scannerErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Camera error occurred\nPlease try again'**
  String get scannerErrorDefault;

  /// No description provided for @bookstoreSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Bookstore'**
  String get bookstoreSelectTitle;

  /// No description provided for @bookstoreAladdin.
  ///
  /// In en, this message translates to:
  /// **'Aladin'**
  String get bookstoreAladdin;

  /// No description provided for @bookstoreKyobo.
  ///
  /// In en, this message translates to:
  /// **'Kyobo'**
  String get bookstoreKyobo;

  /// No description provided for @expandedNavBackToDetail.
  ///
  /// In en, this message translates to:
  /// **'Back to Reading Detail'**
  String get expandedNavBackToDetail;

  /// No description provided for @extractedTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get extractedTextTitle;

  /// No description provided for @extractedTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the extracted content. You can edit it directly!'**
  String get extractedTextSubtitle;

  /// No description provided for @extractedTextApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get extractedTextApplyButton;

  /// No description provided for @extractedTextCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Select Again'**
  String get extractedTextCancelButton;

  /// No description provided for @extractedTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get extractedTextHint;

  /// No description provided for @fullTextViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Text Record'**
  String get fullTextViewTitle;

  /// No description provided for @fullTextViewHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get fullTextViewHint;

  /// No description provided for @fullTextViewCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied.'**
  String get fullTextViewCopied;

  /// No description provided for @highlightEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlight'**
  String get highlightEditTitle;

  /// No description provided for @highlightEditOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get highlightEditOpacity;

  /// No description provided for @highlightEditThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get highlightEditThickness;

  /// No description provided for @koreanDatePickerYear.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanDatePickerYear;

  /// No description provided for @koreanDatePickerMonth.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanDatePickerMonth;

  /// No description provided for @koreanDatePickerDay.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanDatePickerDay;

  /// No description provided for @koreanTimePickerHour.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanTimePickerHour;

  /// No description provided for @koreanTimePickerMinute.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanTimePickerMinute;

  /// No description provided for @koreanYearMonthPickerYear.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanYearMonthPickerYear;

  /// No description provided for @koreanYearMonthPickerMonth.
  ///
  /// In en, this message translates to:
  /// **''**
  String get koreanYearMonthPickerMonth;

  /// No description provided for @liquidGlassSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get liquidGlassSearchHint;

  /// No description provided for @readingDetailPageUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Pages'**
  String get readingDetailPageUpdate;

  /// No description provided for @recommendationViewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Book Details'**
  String get recommendationViewDetail;

  /// No description provided for @recommendationViewDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check book information at the bookstore'**
  String get recommendationViewDetailSubtitle;

  /// No description provided for @recommendationStartReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get recommendationStartReading;

  /// No description provided for @recommendationStartReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start reading this book'**
  String get recommendationStartReadingSubtitle;

  /// No description provided for @recommendationBookstoreSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Bookstore'**
  String get recommendationBookstoreSelect;

  /// No description provided for @chartAiInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get chartAiInsightTitle;

  /// No description provided for @chartAiInsightAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your reading patterns...'**
  String get chartAiInsightAnalyzing;

  /// No description provided for @chartAiInsightUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get chartAiInsightUnknownError;

  /// No description provided for @chartAiInsightRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chartAiInsightRetry;

  /// No description provided for @chartAiInsightMinBooksRequired.
  ///
  /// In en, this message translates to:
  /// **'Read more books to get AI insights'**
  String get chartAiInsightMinBooksRequired;

  /// Minimum books required message
  ///
  /// In en, this message translates to:
  /// **'Books completed: {count}'**
  String chartAiInsightMinBooksMessage(int count);

  /// No description provided for @chartAiInsightMinBooksHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 books, recommended 5+'**
  String get chartAiInsightMinBooksHint;

  /// No description provided for @chartAiInsightGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get chartAiInsightGenerateButton;

  /// No description provided for @chartAiInsightEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to generate insights'**
  String get chartAiInsightEmptyState;

  /// No description provided for @chartAiInsightAlreadyAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Already analyzed today. Try again tomorrow.'**
  String get chartAiInsightAlreadyAnalyzed;

  /// No description provided for @chartAiInsightClearMemory.
  ///
  /// In en, this message translates to:
  /// **'Clear Insight History'**
  String get chartAiInsightClearMemory;

  /// No description provided for @chartAiInsightClearMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Insight History'**
  String get chartAiInsightClearMemoryTitle;

  /// No description provided for @chartAiInsightClearMemoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all insight history?\nThis action cannot be undone.'**
  String get chartAiInsightClearMemoryMessage;

  /// No description provided for @chartAiInsightClearMemoryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chartAiInsightClearMemoryCancel;

  /// No description provided for @chartAiInsightClearMemoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chartAiInsightClearMemoryConfirm;

  /// No description provided for @chartAiInsightSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'(Sample)'**
  String get chartAiInsightSampleLabel;

  /// Annual goal card title
  ///
  /// In en, this message translates to:
  /// **'{year} Reading Goal'**
  String chartAnnualGoalTitle(int year);

  /// Achievement percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% Achieved'**
  String chartAnnualGoalAchieved(int percent);

  /// Remaining books count
  ///
  /// In en, this message translates to:
  /// **'{count} books remaining'**
  String chartAnnualGoalRemaining(int count);

  /// No description provided for @chartAnnualGoalAchievedMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve achieved this year\'s goal!'**
  String get chartAnnualGoalAchievedMessage;

  /// Ahead of schedule message
  ///
  /// In en, this message translates to:
  /// **'You\'ve read {count} more books than expected!'**
  String chartAnnualGoalAheadMessage(int count);

  /// No description provided for @chartAnnualGoalMotivationMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep going! You can reach your goal!'**
  String get chartAnnualGoalMotivationMessage;

  /// No description provided for @chartAnnualGoalSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get chartAnnualGoalSetGoal;

  /// No description provided for @chartAnnualGoalSetGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'Set your reading goal to see your progress at a glance'**
  String get chartAnnualGoalSetGoalMessage;

  /// No description provided for @chartAnnualGoalEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get chartAnnualGoalEditGoal;

  /// No description provided for @chartCompletionRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Completion'**
  String get chartCompletionRateTitle;

  /// No description provided for @chartCompletionRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get chartCompletionRateLabel;

  /// Completed books count
  ///
  /// In en, this message translates to:
  /// **'{count} books completed'**
  String chartCompletionRateBooks(int count);

  /// No description provided for @chartAbandonRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Abandon Rate'**
  String get chartAbandonRateLabel;

  /// Abandoned books count
  ///
  /// In en, this message translates to:
  /// **'{count} books abandoned'**
  String chartAbandonRateBooks(int count);

  /// No description provided for @chartRetrySuccessRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry Success Rate'**
  String get chartRetrySuccessRateLabel;

  /// No description provided for @chartRetrySuccessRateBooks.
  ///
  /// In en, this message translates to:
  /// **'Completed after retry'**
  String get chartRetrySuccessRateBooks;

  /// No description provided for @chartCompletionRateSummaryStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get chartCompletionRateSummaryStarted;

  /// No description provided for @chartCompletionRateSummaryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get chartCompletionRateSummaryCompleted;

  /// No description provided for @chartCompletionRateSummaryInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get chartCompletionRateSummaryInProgress;

  /// No description provided for @chartCompletionRateSummaryAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get chartCompletionRateSummaryAbandoned;

  /// No description provided for @chartCompletionRateEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No completed books yet'**
  String get chartCompletionRateEmptyMessage;

  /// No description provided for @chartCompletionRateEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Read and complete books to see your completion rate'**
  String get chartCompletionRateEmptyHint;

  /// No description provided for @chartGenreAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Genre Analysis'**
  String get chartGenreAnalysisTitle;

  /// No description provided for @chartGenreAnalysisTotalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Total Completed'**
  String get chartGenreAnalysisTotalCompleted;

  /// No description provided for @chartGenreAnalysisDiversity.
  ///
  /// In en, this message translates to:
  /// **'Genre Diversity'**
  String get chartGenreAnalysisDiversity;

  /// No description provided for @chartGenreAnalysisEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No completed books yet'**
  String get chartGenreAnalysisEmptyMessage;

  /// No description provided for @chartGenreAnalysisEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Complete books to see genre statistics!'**
  String get chartGenreAnalysisEmptyHint;

  /// No description provided for @chartHighlightStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records/Highlights Statistics'**
  String get chartHighlightStatsTitle;

  /// No description provided for @chartHighlightStatsHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get chartHighlightStatsHighlights;

  /// No description provided for @chartHighlightStatsMemos.
  ///
  /// In en, this message translates to:
  /// **'Memos'**
  String get chartHighlightStatsMemos;

  /// No description provided for @chartHighlightStatsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get chartHighlightStatsPhotos;

  /// No description provided for @chartHighlightStatsByGenre.
  ///
  /// In en, this message translates to:
  /// **'Highlights by Genre'**
  String get chartHighlightStatsByGenre;

  /// No description provided for @chartHighlightStatsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet'**
  String get chartHighlightStatsEmptyMessage;

  /// No description provided for @chartHighlightStatsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Highlight important parts while reading'**
  String get chartHighlightStatsEmptyHint;

  /// Monthly books chart title
  ///
  /// In en, this message translates to:
  /// **'{year} Monthly Reading'**
  String chartMonthlyBooksTitle(int year);

  /// No description provided for @chartMonthlyBooksThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get chartMonthlyBooksThisMonth;

  /// No description provided for @chartMonthlyBooksLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get chartMonthlyBooksLastMonth;

  /// No description provided for @chartMonthlyBooksChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chartMonthlyBooksChange;

  /// Month number
  ///
  /// In en, this message translates to:
  /// **'{month}'**
  String chartMonthlyBooksMonth(int month);

  /// Monthly books tooltip
  ///
  /// In en, this message translates to:
  /// **'{month} month\n{count} books'**
  String chartMonthlyBooksTooltip(int month, int count);

  /// Reading streak heatmap title
  ///
  /// In en, this message translates to:
  /// **'{year} Reading Heatmap'**
  String chartReadingStreakTitle(int year);

  /// No description provided for @chartReadingStreakDaysRead.
  ///
  /// In en, this message translates to:
  /// **'Days Read'**
  String get chartReadingStreakDaysRead;

  /// No description provided for @chartReadingStreakTotalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get chartReadingStreakTotalPages;

  /// No description provided for @chartReadingStreakDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get chartReadingStreakDailyAverage;

  /// No description provided for @chartReadingStreakLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get chartReadingStreakLess;

  /// No description provided for @chartReadingStreakMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chartReadingStreakMore;

  /// Reading streak tooltip
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}: {pages} pages'**
  String chartReadingStreakTooltip(int month, int day, int pages);

  /// No description provided for @chartReadingStreakMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get chartReadingStreakMonthJan;

  /// No description provided for @chartReadingStreakMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get chartReadingStreakMonthMar;

  /// No description provided for @chartReadingStreakMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get chartReadingStreakMonthMay;

  /// No description provided for @chartReadingStreakMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get chartReadingStreakMonthJul;

  /// No description provided for @chartReadingStreakMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get chartReadingStreakMonthSep;

  /// No description provided for @chartReadingStreakMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get chartReadingStreakMonthNov;

  /// Reading goal sheet title
  ///
  /// In en, this message translates to:
  /// **'{year} Reading Goal'**
  String readingGoalSheetTitle(int year);

  /// No description provided for @readingGoalSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many books do you want to read this year?'**
  String get readingGoalSheetQuestion;

  /// No description provided for @readingGoalSheetRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended Goals'**
  String get readingGoalSheetRecommended;

  /// No description provided for @readingGoalSheetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Input'**
  String get readingGoalSheetCustom;

  /// Books per month message
  ///
  /// In en, this message translates to:
  /// **'Average {count} books per month'**
  String readingGoalSheetBooksPerMonth(String count);

  /// No description provided for @readingGoalSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Enter goal number'**
  String get readingGoalSheetHint;

  /// No description provided for @readingGoalSheetBooks.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get readingGoalSheetBooks;

  /// No description provided for @readingGoalSheetMotivation1.
  ///
  /// In en, this message translates to:
  /// **'Reading 1 book per month consistently builds a reading habit. Enjoy reading without pressure!'**
  String get readingGoalSheetMotivation1;

  /// No description provided for @readingGoalSheetMotivation2.
  ///
  /// In en, this message translates to:
  /// **'Reading 1 book every 2 weeks is achievable! Experience the joy of reading with a reasonable goal.'**
  String get readingGoalSheetMotivation2;

  /// No description provided for @readingGoalSheetMotivation3.
  ///
  /// In en, this message translates to:
  /// **'1 book every 10 days! You love reading. Explore diverse genres!'**
  String get readingGoalSheetMotivation3;

  /// No description provided for @readingGoalSheetMotivation4.
  ///
  /// In en, this message translates to:
  /// **'Almost 1 book per week! You\'re a true book lover. Keep the fire burning! 🔥'**
  String get readingGoalSheetMotivation4;

  /// No description provided for @readingGoalSheetMotivation5.
  ///
  /// In en, this message translates to:
  /// **'An ambitious goal! More than 1 book per week. You\'re a reading master! 📚✨'**
  String get readingGoalSheetMotivation5;

  /// No description provided for @readingGoalSheetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get readingGoalSheetCancel;

  /// No description provided for @readingGoalSheetSet.
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get readingGoalSheetSet;

  /// No description provided for @readingGoalSheetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get readingGoalSheetUpdate;
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
