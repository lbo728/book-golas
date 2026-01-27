// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BookGolas';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonChange => 'Change';

  @override
  String get commonComplete => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonStart => 'Get Started';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navStats => 'Stats';

  @override
  String get navCalendar => 'Calendar';

  @override
  String booksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get unitYear => '';

  @override
  String get unitMonth => '';

  @override
  String get unitDay => '';

  @override
  String get unitHour => '';

  @override
  String get unitMinute => '';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusPlanned => 'To Read';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusReread => 'Reread';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get contentTypeHighlight => 'Highlight';

  @override
  String get contentTypeMemo => 'Memo';

  @override
  String get contentTypePhoto => 'Photo';

  @override
  String get languageSettingLabel => 'Language';

  @override
  String get homeBookList => 'Book List';

  @override
  String get homeNoReadingBooks =>
      'No books in progress. Please register a book first.';

  @override
  String get homeNoReadingBooksShort => 'No books in progress';

  @override
  String get homeViewAllBooks => 'View all books';

  @override
  String get homeViewReadingOnly => 'View reading only';

  @override
  String get homeViewAllBooksMessage => 'Switched to view all books.';

  @override
  String get homeViewReadingMessage => 'Switched to view reading books.';

  @override
  String get bookListTabReading => 'Reading';

  @override
  String get bookListTabPlanned => 'To Read';

  @override
  String get bookListTabCompleted => 'Completed';

  @override
  String get bookListTabReread => 'Reread';

  @override
  String get bookListTabAll => 'All';

  @override
  String get bookListFilterAll => 'All';

  @override
  String get bookListErrorLoadFailed => 'Unable to load data';

  @override
  String get bookListErrorNetworkCheck =>
      'Please check your network connection';

  @override
  String get bookListEmptyReading => 'No books in progress';

  @override
  String get bookListEmptyPlanned => 'No books to read';

  @override
  String get bookListEmptyCompleted => 'No completed books';

  @override
  String get bookListEmptyPaused => 'No paused books';

  @override
  String get bookListEmptyAll => 'No reading started yet';

  @override
  String get bookDetailTabRecord => 'Record';

  @override
  String get bookDetailTabHistory => 'History';

  @override
  String get bookDetailTabReview => 'Review';

  @override
  String get bookDetailTabDetail => 'Details';

  @override
  String get bookDetailStartDate => 'Start Date';

  @override
  String get bookDetailTargetDate => 'Target Date';

  @override
  String get bookDetailReviewWritten => 'Written';

  @override
  String get bookDetailReviewNotWritten => 'Not written yet';

  @override
  String get bookDetailLegendAchieved => 'Achieved';

  @override
  String get bookDetailLegendMissed => 'Missed';

  @override
  String get bookDetailLegendScheduled => 'Scheduled';

  @override
  String get bookDetailLater => 'Later';

  @override
  String get myLibraryTitle => 'My Library';

  @override
  String get myLibraryTabReading => 'Reading';

  @override
  String get myLibraryTabReview => 'Review';

  @override
  String get myLibraryTabRecord => 'Record';

  @override
  String get myLibrarySearchHint => 'Search by title or author';

  @override
  String get myLibraryNoSearchResults => 'No search results';

  @override
  String get myLibraryNoBooks => 'No books registered';

  @override
  String get myLibraryNoReviewBooks => 'No books with reviews';

  @override
  String get myLibraryNoRecords => 'No records';

  @override
  String get myLibraryAiSearch => 'AI Search All Records';

  @override
  String get myLibraryFilterAll => 'All';

  @override
  String get myLibraryFilterHighlight => '✨ Highlight';

  @override
  String get myLibraryFilterMemo => '📝 Memo';

  @override
  String get myLibraryFilterPhoto => '📷 Photo';

  @override
  String get chartTitle => 'My Reading Stats';

  @override
  String get chartTabOverview => 'Overview';

  @override
  String get chartTabAnalysis => 'Analysis';

  @override
  String get chartTabActivity => 'Activity';

  @override
  String get chartPeriodDaily => 'Daily';

  @override
  String get chartPeriodWeekly => 'Weekly';

  @override
  String get chartPeriodMonthly => 'Monthly';

  @override
  String get chartDailyAverage => 'Daily Avg';

  @override
  String get chartIncrease => 'Change';

  @override
  String get chartLess => 'Less';

  @override
  String get chartMore => 'More';

  @override
  String get chartErrorLoadFailed => 'Unable to load data';

  @override
  String get chartErrorRetry => 'Retry';

  @override
  String get chartTotalPages => 'Total Pages Read';

  @override
  String get chartDailyAvgPages => 'Daily Average';

  @override
  String get chartMaxDaily => 'Best Record';

  @override
  String get chartMinDaily => 'Lowest Record';

  @override
  String get chartConsecutiveDays => 'Consecutive Days';

  @override
  String get chartTodayGoal => 'Today\'s Goal';

  @override
  String get chartReadingProgress => 'Reading Progress';

  @override
  String get chartDailyPages => 'Daily Pages';

  @override
  String get chartCumulativePages => 'Cumulative Pages';

  @override
  String get chartNoData => 'No data yet';

  @override
  String get chartDailyReadPages => 'Pages Read';

  @override
  String get chartReadingStats => 'Reading Statistics';

  @override
  String get chartAiInsight => 'AI Insight';

  @override
  String get chartCompletionRate => 'Completion Rate';

  @override
  String get chartRecordsHighlights => 'Records/Highlights';

  @override
  String get chartGenreAnalysis => 'Genre Analysis';

  @override
  String get chartNoReadingRecords => 'No reading records';

  @override
  String get myPageTitle => 'My Page';

  @override
  String get myPageSettings => 'Settings';

  @override
  String get myPageChangeAvatar => 'Change';

  @override
  String get myPageLogout => 'Logout';

  @override
  String get myPageDeleteAccount => 'Delete Account';

  @override
  String get myPageDeleteAccountConfirm =>
      'Are you sure you want to delete your account?\n\nThis action cannot be undone, and all data will be permanently deleted.';

  @override
  String get myPageDeleteAccountSuccess => 'Account successfully deleted.';

  @override
  String get myPageDeleteAccountFailed =>
      'Failed to delete account. Please try again.';

  @override
  String myPageDeleteAccountError(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get myPageNotificationTimeTitle => 'Set Notification Time';

  @override
  String get myPageNoNickname => 'No nickname';

  @override
  String get myPageNicknameHint => 'Enter your nickname';

  @override
  String get myPageDarkMode => 'Dark Mode';

  @override
  String get myPageDailyReadingNotification =>
      'Daily Reading Goal Notification';

  @override
  String myPageNotificationTime(String time) {
    return 'Daily notification at $time';
  }

  @override
  String get myPageNoNotification => 'No notifications';

  @override
  String get myPageNotificationEnabled => 'Notifications enabled';

  @override
  String get myPageNotificationDisabled => 'Notifications disabled';

  @override
  String get myPageNotificationChangeFailed =>
      'Failed to change notification settings';

  @override
  String get myPageTestNotification => 'Test Notification (in 30 seconds)';

  @override
  String get myPageTestNotificationSent =>
      'Test notification will be sent in 30 seconds!';

  @override
  String get myPageAvatarChanged => 'Profile image changed';

  @override
  String myPageAvatarChangeFailed(String error) {
    return 'Failed to change profile image: $error';
  }

  @override
  String get loginAppName => 'BookGolas';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginNicknameLabel => 'Nickname';

  @override
  String get loginOrDivider => 'or';

  @override
  String get loginButton => 'Login';

  @override
  String get loginSignupButton => 'Sign Up';

  @override
  String get loginDescriptionSignIn =>
      'One page a day,\nwe support your reading';

  @override
  String get loginDescriptionSignUp =>
      'Start your reading habit\nwith BookGolas';

  @override
  String get loginDescriptionForgotPassword =>
      'We\'ll send a password reset link\nto your registered email';

  @override
  String get loginEmailHint => 'example@email.com';

  @override
  String get loginPasswordHint => 'Enter 6 or more characters';

  @override
  String get loginNicknameHint => 'Name to use in the app';

  @override
  String get loginEmailRequired => 'Please enter your email';

  @override
  String get loginEmailInvalid => 'Please enter a valid email address';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginNicknameRequired => 'Please enter your nickname';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginNoAccount => 'Don\'t have an account? Sign Up';

  @override
  String get loginHaveAccount => 'Already have an account? Login';

  @override
  String get loginBackToSignIn => 'Back to Login';

  @override
  String get loginSaveEmail => 'Save email';

  @override
  String get loginSignupSuccess => 'Sign up complete. Please check your email.';

  @override
  String get loginResetPasswordSuccess => 'Password reset email sent.';

  @override
  String get loginUnexpectedError => 'An unexpected error occurred.';

  @override
  String get loginErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get loginErrorEmailNotConfirmed =>
      'Email verification is not complete.';

  @override
  String get loginErrorEmailAlreadyRegistered =>
      'This email is already registered.';

  @override
  String get loginErrorPasswordTooShort =>
      'Password must be at least 6 characters.';

  @override
  String get reviewTitle => 'Book Review';

  @override
  String get reviewSave => 'Save';

  @override
  String get reviewReplace => 'Replace';

  @override
  String get reviewExit => 'Exit';

  @override
  String get reviewDraftLoaded => 'Draft loaded successfully.';

  @override
  String get reviewCopied => 'Review copied.';

  @override
  String get reviewBookNotFound => 'Book information not found.';

  @override
  String get reviewSaveFailed => 'Failed to save. Please try again.';

  @override
  String get reviewSaveError => 'An error occurred while saving.';

  @override
  String get reviewReplaceConfirm =>
      'You have unsaved content.\nDo you want to replace it with AI draft?';

  @override
  String get reviewReplaceButton => 'Replace';

  @override
  String get reviewAIDraftGenerated => 'AI draft generated. Feel free to edit!';

  @override
  String get reviewAIDraftFailed =>
      'Failed to generate AI draft. Please try again.';

  @override
  String get reviewAIDraftError =>
      'An error occurred while generating AI draft.';

  @override
  String get reviewSaveComplete => 'Review saved!';

  @override
  String get reviewSaveCompleteMessage =>
      'Your saved review can be found in the \'Review\' tab or\n\'My Library > Review\'.';

  @override
  String get reviewExitConfirm => 'Stop writing and exit?';

  @override
  String get reviewExitMessage => 'Your draft will be saved automatically.';

  @override
  String get reviewHint =>
      'Write freely about your thoughts, impressive parts, and inspiration from this book.';

  @override
  String get readingStartSetDate => 'Set Start Date';

  @override
  String get readingStartUndetermined => 'TBD';

  @override
  String get readingStartTitle => 'Start Reading';

  @override
  String get readingStartSubtitle => 'Search for a book to start reading';

  @override
  String get readingStartNoResults => 'No search results';

  @override
  String get readingStartAnalyzing => 'Analyzing reading patterns...';

  @override
  String get readingStartAiRecommendation => 'AI Personalized Recommendations';

  @override
  String readingStartAiRecommendationDesc(String userName) {
    return 'Books recommended based on $userName\'s reading patterns';
  }

  @override
  String get readingStartSearchHint => 'Enter book title';

  @override
  String get readingStartSelectionComplete => 'Selection Complete';

  @override
  String get readingStartConfirm => 'OK';

  @override
  String readingStartPages(int totalPages) {
    return '$totalPages pages';
  }

  @override
  String get readingStartPlannedDate => 'Planned Reading Start Date';

  @override
  String get readingStartToday => 'Starting today';

  @override
  String get readingStartTargetDate => 'Target Deadline';

  @override
  String get readingStartTargetDateNote =>
      'You can change the target date even after starting to read';

  @override
  String get readingStartSaveError => 'Failed to save reading information';

  @override
  String get readingStartReserve => 'Reserve Reading';

  @override
  String get readingStartBegin => 'Start Reading';

  @override
  String get dialogOpacity => 'Opacity';

  @override
  String get dialogThickness => 'Thickness';

  @override
  String get dialogTakePhoto => 'Take Photo';

  @override
  String get dialogReplaceImage => 'Replace';

  @override
  String get dialogViewFull => 'View Full';

  @override
  String get dialogCopy => 'Copy';

  @override
  String get dialogEdit => 'Edit';

  @override
  String get dialogSaved => 'Saved';

  @override
  String get dialogSaving => 'Saving...';

  @override
  String get dialogUpload => 'Upload';

  @override
  String get dialogSelect => 'Select';

  @override
  String get dialogApply => 'Apply';

  @override
  String get dialogExtract => 'Extract';

  @override
  String get dialogOkay => 'Okay';

  @override
  String get dialogExtractIt => 'Extract It';

  @override
  String get dialogThinkAboutIt => 'Think About It';

  @override
  String get genreNovel => 'Novel';

  @override
  String get genreLiterature => 'Literature';

  @override
  String get genreSelfHelp => 'Self-Help';

  @override
  String get genreBusiness => 'Business';

  @override
  String get genreHumanities => 'Humanities';

  @override
  String get genreScience => 'Science';

  @override
  String get genreHistory => 'History';

  @override
  String get genreEssay => 'Essay';

  @override
  String get genrePoetry => 'Poetry';

  @override
  String get genreComic => 'Comic';

  @override
  String get genreUncategorized => 'Uncategorized';

  @override
  String get errorInitFailed => 'Initialization failed';

  @override
  String get errorLoadFailed => 'Failed to load';

  @override
  String get errorNoRecords => 'No records';

  @override
  String get loadingInit => 'Initializing app...';

  @override
  String get calendarMonthSelect => 'Select Month';

  @override
  String calendarPagesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages read',
      one: '1 page read',
    );
    return '$_temp0';
  }

  @override
  String get calendarCompleted => 'Completed';

  @override
  String get onboardingTitle1 => 'Record Your Own Reading Journey';

  @override
  String get onboardingDescription1 =>
      'Register books you want to read,\nand manage your reading goals and progress at a glance.';

  @override
  String get onboardingTitle2 => 'Search Your Reading Records with AI';

  @override
  String get onboardingDescription2 =>
      'Search for content you remember,\nand AI will find related notes and books for you.';

  @override
  String get onboardingTitle3 => 'Get Book Recommendations';

  @override
  String get onboardingDescription3 =>
      'Based on the books you\'ve read so far,\nAI recommends books tailored to your taste.';

  @override
  String get readingProgressTitle => 'Reading Progress History';

  @override
  String get readingProgressLoadFailed => 'Failed to load progress';

  @override
  String get readingProgressNoRecords => 'No progress records';

  @override
  String get barcodeScannerTitle => 'Scan ISBN Barcode';

  @override
  String get barcodeScannerHint =>
      'Scan the ISBN barcode on the back of the book';

  @override
  String get scannerErrorPermissionDenied =>
      'Camera permission required\nPlease allow camera access in settings';

  @override
  String get scannerErrorInitializing => 'Initializing camera';

  @override
  String get scannerErrorDefault => 'Camera error occurred\nPlease try again';
}
