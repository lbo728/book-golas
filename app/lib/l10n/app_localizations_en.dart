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
  String booksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String daysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get unitPages => 'pages';

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
  String readingStartPages(num totalPages) {
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
  String calendarPagesRead(num count) {
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

  @override
  String get bookstoreSelectTitle => 'Select Bookstore';

  @override
  String get bookstoreAladdin => 'Aladin';

  @override
  String get bookstoreKyobo => 'Kyobo';

  @override
  String get expandedNavBackToDetail => 'Back to Reading Detail';

  @override
  String get extractedTextTitle => 'Extracted Text';

  @override
  String get extractedTextSubtitle =>
      'Check the extracted content. You can edit it directly!';

  @override
  String get extractedTextApplyButton => 'Apply';

  @override
  String get extractedTextCancelButton => 'Select Again';

  @override
  String get extractedTextHint => 'Enter text';

  @override
  String get fullTextViewTitle => 'Text Record';

  @override
  String get fullTextViewHint => 'Enter text...';

  @override
  String get fullTextViewCopied => 'Text copied.';

  @override
  String get highlightEditTitle => 'Edit Highlight';

  @override
  String get highlightEditOpacity => 'Opacity';

  @override
  String get highlightEditThickness => 'Thickness';

  @override
  String get koreanDatePickerYear => '';

  @override
  String get koreanDatePickerMonth => '';

  @override
  String get koreanDatePickerDay => '';

  @override
  String get koreanTimePickerHour => '';

  @override
  String get koreanTimePickerMinute => '';

  @override
  String get koreanYearMonthPickerYear => '';

  @override
  String get koreanYearMonthPickerMonth => '';

  @override
  String get liquidGlassSearchHint => 'Enter book title';

  @override
  String get readingDetailPageUpdate => 'Update Pages';

  @override
  String get recommendationViewDetail => 'View Book Details';

  @override
  String get recommendationViewDetailSubtitle =>
      'Check book information at the bookstore';

  @override
  String get recommendationStartReading => 'Start Reading';

  @override
  String get recommendationStartReadingSubtitle => 'Start reading this book';

  @override
  String get recommendationBookstoreSelect => 'Select Bookstore';

  @override
  String get chartAiInsightTitle => 'AI Insight';

  @override
  String get chartAiInsightAnalyzing => 'Analyzing your reading patterns...';

  @override
  String get chartAiInsightUnknownError => 'An unknown error occurred';

  @override
  String get chartAiInsightRetry => 'Retry';

  @override
  String get chartAiInsightMinBooksRequired =>
      'Read more books to get AI insights';

  @override
  String chartAiInsightMinBooksMessage(int count) {
    return 'Books completed: $count';
  }

  @override
  String get chartAiInsightMinBooksHint => 'Minimum 3 books, recommended 5+';

  @override
  String get chartAiInsightGenerateButton => 'Analyze';

  @override
  String get chartAiInsightEmptyState =>
      'Click the button below to generate insights';

  @override
  String get chartAiInsightAlreadyAnalyzed =>
      'Already analyzed today. Try again tomorrow.';

  @override
  String get chartAiInsightClearMemory => 'Clear Insight History';

  @override
  String get chartAiInsightClearMemoryTitle => 'Clear Insight History';

  @override
  String get chartAiInsightClearMemoryMessage =>
      'Are you sure you want to delete all insight history?\nThis action cannot be undone.';

  @override
  String get chartAiInsightClearMemoryCancel => 'Cancel';

  @override
  String get chartAiInsightClearMemoryConfirm => 'Delete';

  @override
  String get chartAiInsightSampleLabel => '(Sample)';

  @override
  String chartAnnualGoalTitle(int year) {
    return '$year Reading Goal';
  }

  @override
  String chartAnnualGoalAchieved(int percent) {
    return '$percent% Achieved';
  }

  @override
  String chartAnnualGoalRemaining(int count) {
    return '$count books remaining';
  }

  @override
  String get chartAnnualGoalAchievedMessage =>
      'Congratulations! You\'ve achieved this year\'s goal!';

  @override
  String chartAnnualGoalAheadMessage(int count) {
    return 'You\'ve read $count more books than expected!';
  }

  @override
  String get chartAnnualGoalMotivationMessage =>
      'Keep going! You can reach your goal!';

  @override
  String get chartAnnualGoalSetGoal => 'Set Goal';

  @override
  String get chartAnnualGoalSetGoalMessage =>
      'Set your reading goal to see your progress at a glance';

  @override
  String get chartAnnualGoalEditGoal => 'Edit Goal';

  @override
  String get chartCompletionRateTitle => 'Reading Completion';

  @override
  String get chartCompletionRateLabel => 'Completion Rate';

  @override
  String chartCompletionRateBooks(int count) {
    return '$count books completed';
  }

  @override
  String get chartAbandonRateLabel => 'Abandon Rate';

  @override
  String chartAbandonRateBooks(int count) {
    return '$count books abandoned';
  }

  @override
  String get chartRetrySuccessRateLabel => 'Retry Success Rate';

  @override
  String get chartRetrySuccessRateBooks => 'Completed after retry';

  @override
  String get chartCompletionRateSummaryStarted => 'Started';

  @override
  String get chartCompletionRateSummaryCompleted => 'Completed';

  @override
  String get chartCompletionRateSummaryInProgress => 'In Progress';

  @override
  String get chartCompletionRateSummaryAbandoned => 'Abandoned';

  @override
  String get chartCompletionRateEmptyMessage => 'No completed books yet';

  @override
  String get chartCompletionRateEmptyHint =>
      'Read and complete books to see your completion rate';

  @override
  String get chartGenreAnalysisTitle => 'Genre Analysis';

  @override
  String get chartGenreAnalysisTotalCompleted => 'Total Completed';

  @override
  String get chartGenreAnalysisDiversity => 'Genre Diversity';

  @override
  String get chartGenreAnalysisEmptyMessage => 'No completed books yet';

  @override
  String get chartGenreAnalysisEmptyHint =>
      'Complete books to see genre statistics!';

  @override
  String get chartHighlightStatsTitle => 'Records/Highlights Statistics';

  @override
  String get chartHighlightStatsHighlights => 'Highlights';

  @override
  String get chartHighlightStatsMemos => 'Memos';

  @override
  String get chartHighlightStatsPhotos => 'Photos';

  @override
  String get chartHighlightStatsByGenre => 'Highlights by Genre';

  @override
  String get chartHighlightStatsEmptyMessage => 'No highlights yet';

  @override
  String get chartHighlightStatsEmptyHint =>
      'Highlight important parts while reading';

  @override
  String chartMonthlyBooksTitle(int year) {
    return '$year Monthly Reading';
  }

  @override
  String get chartMonthlyBooksThisMonth => 'This Month';

  @override
  String get chartMonthlyBooksLastMonth => 'Last Month';

  @override
  String get chartMonthlyBooksChange => 'Change';

  @override
  String chartMonthlyBooksMonth(int month) {
    return '$month';
  }

  @override
  String chartMonthlyBooksTooltip(int month, int count) {
    return '$month month\n$count books';
  }

  @override
  String chartReadingStreakTitle(int year) {
    return '$year Reading Heatmap';
  }

  @override
  String get chartReadingStreakDaysRead => 'Days Read';

  @override
  String get chartReadingStreakTotalPages => 'Total Pages';

  @override
  String get chartReadingStreakDailyAverage => 'Daily Avg';

  @override
  String get chartReadingStreakLess => 'Less';

  @override
  String get chartReadingStreakMore => 'More';

  @override
  String chartReadingStreakTooltip(int month, int day, int pages) {
    return '$month/$day: $pages pages';
  }

  @override
  String get chartReadingStreakMonthJan => 'Jan';

  @override
  String get chartReadingStreakMonthMar => 'Mar';

  @override
  String get chartReadingStreakMonthMay => 'May';

  @override
  String get chartReadingStreakMonthJul => 'Jul';

  @override
  String get chartReadingStreakMonthSep => 'Sep';

  @override
  String get chartReadingStreakMonthNov => 'Nov';

  @override
  String readingGoalSheetTitle(int year) {
    return '$year Reading Goal';
  }

  @override
  String get readingGoalSheetQuestion =>
      'How many books do you want to read this year?';

  @override
  String get readingGoalSheetRecommended => 'Recommended Goals';

  @override
  String get readingGoalSheetCustom => 'Custom Input';

  @override
  String readingGoalSheetBooksPerMonth(String count) {
    return 'Average $count books per month';
  }

  @override
  String get readingGoalSheetHint => 'Enter goal number';

  @override
  String get readingGoalSheetBooks => 'books';

  @override
  String get readingGoalSheetMotivation1 =>
      'Reading 1 book per month consistently builds a reading habit. Enjoy reading without pressure!';

  @override
  String get readingGoalSheetMotivation2 =>
      'Reading 1 book every 2 weeks is achievable! Experience the joy of reading with a reasonable goal.';

  @override
  String get readingGoalSheetMotivation3 =>
      '1 book every 10 days! You love reading. Explore diverse genres!';

  @override
  String get readingGoalSheetMotivation4 =>
      'Almost 1 book per week! You\'re a true book lover. Keep the fire burning! 🔥';

  @override
  String get readingGoalSheetMotivation5 =>
      'An ambitious goal! More than 1 book per week. You\'re a reading master! 📚✨';

  @override
  String get readingGoalSheetCancel => 'Cancel';

  @override
  String get readingGoalSheetSet => 'Set Goal';

  @override
  String get readingGoalSheetUpdate => 'Update Goal';

  @override
  String get recallTextCopied => 'Text copied';

  @override
  String get recallSearchAllRecords => 'Search All Records';

  @override
  String get recallSearchingAllBooks => 'Searching all books...';

  @override
  String get recallRecentGlobalSearches => 'Recent Global Searches';

  @override
  String get recallSearchAllReadingRecords => 'Search all your reading records';

  @override
  String get recallAiFindsScatteredRecords =>
      'AI finds scattered records across books\nand brings them together for you';

  @override
  String get recallAiAnswer => 'AI Answer';

  @override
  String get recallReferencedRecords => 'Referenced Records';

  @override
  String recallMoreBooks(int count) {
    return '$count more books';
  }

  @override
  String recallRecordCount(int count) {
    return '$count records';
  }

  @override
  String get recallSearchMyRecords => 'Search My Records';

  @override
  String get recallSearchingYourRecords => 'Searching your records...';

  @override
  String get recallRecentSearches => 'Recent Searches';

  @override
  String get recallJustNow => 'Just now';

  @override
  String recallMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String recallHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String recallDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get recallSuggestedQuestions => 'Suggested Questions';

  @override
  String get recallSuggestedQuestion1 => 'What impressed me the most?';

  @override
  String get recallSuggestedQuestion2 => 'What did I note to practice?';

  @override
  String get recallSuggestedQuestion3 => 'What\'s the author\'s key message?';

  @override
  String get recallSuggestedQuestion4 => 'What part did I empathize with?';

  @override
  String get recallSearchCurious => 'Search for what you\'re curious about';

  @override
  String get recallFindInRecords => 'Find in highlights, memos, and photos';

  @override
  String get recallRelatedRecords => 'Related Records';

  @override
  String get recallPage => 'page';

  @override
  String get recallContentCopied => 'Content copied';

  @override
  String get recallViewInBook => 'View in This Book';

  @override
  String get recallCopy => 'Copy';

  @override
  String bookListPlannedStartDate(String date) {
    return 'Planned start: $date';
  }

  @override
  String get bookListUndetermined => 'Undetermined';

  @override
  String bookListCompletedIn(int days) {
    return '$days days to complete';
  }

  @override
  String get bookListCompletedSameDay => 'Completed same day';

  @override
  String bookListAchievementRate(int rate) {
    return 'Achievement rate $rate%';
  }

  @override
  String get bookListUnknown => 'Unknown';

  @override
  String bookListCompletedDate(String date) {
    return 'Completed $date';
  }

  @override
  String get readingStartPriority => 'Priority (Optional)';

  @override
  String get languageChangeConfirmTitle => 'Change Language?';

  @override
  String languageChangeConfirmMessage(String language) {
    return 'Would you like to change the language to $language?';
  }

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageEnglish => 'English';

  @override
  String get readingStatusLabel => 'Reading Status';

  @override
  String get readingStatusPlanned => 'Plan to Read';

  @override
  String get readingStatusStartNow => 'Start Now';

  @override
  String get scheduleTargetDays => 'Target Days';

  @override
  String scheduleTargetDaysValue(int count) {
    return '$count days';
  }

  @override
  String get scheduleDailyGoal => 'Daily Goal';

  @override
  String get datePickerMonthJan => 'Jan';

  @override
  String get datePickerMonthFeb => 'Feb';

  @override
  String get datePickerMonthMar => 'Mar';

  @override
  String get datePickerMonthApr => 'Apr';

  @override
  String get datePickerMonthMay => 'May';

  @override
  String get datePickerMonthJun => 'Jun';

  @override
  String get datePickerMonthJul => 'Jul';

  @override
  String get datePickerMonthAug => 'Aug';

  @override
  String get datePickerMonthSep => 'Sep';

  @override
  String get datePickerMonthOct => 'Oct';

  @override
  String get datePickerMonthNov => 'Nov';

  @override
  String get datePickerMonthDec => 'Dec';
}
