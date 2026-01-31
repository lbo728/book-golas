// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '북골라스';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonChange => '변경';

  @override
  String get commonComplete => '완료';

  @override
  String get commonClose => '닫기';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonNext => '다음';

  @override
  String get commonSkip => '건너뛰기';

  @override
  String get commonStart => '시작하기';

  @override
  String get navHome => '홈';

  @override
  String get navLibrary => '서재';

  @override
  String get navStats => '상태';

  @override
  String get navCalendar => '캘린더';

  @override
  String booksCount(num count) {
    return '$count권';
  }

  @override
  String daysCount(num count) {
    return '$count일';
  }

  @override
  String pagesCount(num count) {
    return '$count페이지';
  }

  @override
  String get unitPages => '페이지';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get timeAm => '오전';

  @override
  String get timePm => '오후';

  @override
  String get unitYear => '년';

  @override
  String get unitMonth => '월';

  @override
  String get unitDay => '일';

  @override
  String get unitHour => '시';

  @override
  String get unitMinute => '분';

  @override
  String get statusReading => '독서 중';

  @override
  String get statusPlanned => '읽을 예정';

  @override
  String get statusCompleted => '완독';

  @override
  String get statusReread => '다시 읽을 책';

  @override
  String get priorityUrgent => '긴급';

  @override
  String get priorityHigh => '높음';

  @override
  String get priorityMedium => '보통';

  @override
  String get priorityLow => '낮음';

  @override
  String get contentTypeHighlight => '하이라이트';

  @override
  String get contentTypeMemo => '메모';

  @override
  String get contentTypePhoto => '사진';

  @override
  String get languageSettingLabel => '언어';

  @override
  String get homeBookList => '독서 목록';

  @override
  String get homeNoReadingBooks => '진행 중인 독서가 없습니다. 먼저 책을 등록해주세요.';

  @override
  String get homeNoReadingBooksShort => '진행 중인 독서가 없습니다';

  @override
  String get homeViewAllBooks => '전체 독서 보기';

  @override
  String get homeViewReadingOnly => '진행 중인 독서만 보기';

  @override
  String get homeViewAllBooksMessage => '전체 독서 보기로 전환되었습니다.';

  @override
  String get homeViewReadingMessage => '진행 중인 독서 보기로 전환되었습니다.';

  @override
  String get bookListTabReading => '독서 중';

  @override
  String get bookListTabPlanned => '읽을 예정';

  @override
  String get bookListTabCompleted => '완독';

  @override
  String get bookListTabReread => '다시 읽을 책';

  @override
  String get bookListTabAll => '전체';

  @override
  String get bookListFilterAll => '전체';

  @override
  String get bookListErrorLoadFailed => '데이터를 불러올 수 없습니다';

  @override
  String get bookListErrorNetworkCheck => '네트워크 연결을 확인해주세요';

  @override
  String get bookListEmptyReading => '현재 읽고 있는 책이 없습니다';

  @override
  String get bookListEmptyPlanned => '읽을 예정인 책이 없습니다';

  @override
  String get bookListEmptyCompleted => '완독한 책이 없습니다';

  @override
  String get bookListEmptyPaused => '잠시 쉬어가는 책이 없습니다';

  @override
  String get bookListEmptyAll => '아직 시작한 독서가 없습니다';

  @override
  String get bookDetailTabRecord => '기록';

  @override
  String get bookDetailTabHistory => '히스토리';

  @override
  String get bookDetailTabReview => '독후감';

  @override
  String get bookDetailTabDetail => '상세';

  @override
  String get bookDetailStartDate => '시작일';

  @override
  String get bookDetailTargetDate => '목표일';

  @override
  String get bookDetailReviewWritten => '작성됨';

  @override
  String get bookDetailReviewNotWritten => '아직 작성되지 않음';

  @override
  String get bookDetailLegendAchieved => '달성';

  @override
  String get bookDetailLegendMissed => '미달성';

  @override
  String get bookDetailLegendScheduled => '예정';

  @override
  String get bookDetailLater => '나중에';

  @override
  String get myLibraryTitle => '나의 서재';

  @override
  String get myLibraryTabReading => '독서';

  @override
  String get myLibraryTabReview => '독후감';

  @override
  String get myLibraryTabRecord => '기록';

  @override
  String get myLibrarySearchHint => '제목, 저자로 검색';

  @override
  String get myLibraryNoSearchResults => '검색 결과가 없습니다';

  @override
  String get myLibraryNoBooks => '등록된 책이 없습니다';

  @override
  String get myLibraryNoReviewBooks => '독후감이 있는 책이 없습니다';

  @override
  String get myLibraryNoRecords => '기록이 없습니다';

  @override
  String get myLibraryAiSearch => '모든 기록에서 AI 검색';

  @override
  String get myLibraryFilterAll => '전체';

  @override
  String get myLibraryFilterHighlight => '✨ 하이라이트';

  @override
  String get myLibraryFilterMemo => '📝 메모';

  @override
  String get myLibraryFilterPhoto => '📷 사진';

  @override
  String get chartTitle => '나의 독서 상태';

  @override
  String get chartTabOverview => '개요';

  @override
  String get chartTabAnalysis => '분석';

  @override
  String get chartTabActivity => '활동';

  @override
  String get chartPeriodDaily => '일별';

  @override
  String get chartPeriodWeekly => '주별';

  @override
  String get chartPeriodMonthly => '월별';

  @override
  String get chartDailyAverage => '일평균';

  @override
  String get chartIncrease => '증감';

  @override
  String get chartLess => '적음';

  @override
  String get chartMore => '많음';

  @override
  String get chartErrorLoadFailed => '데이터를 불러올 수 없습니다';

  @override
  String get chartErrorRetry => '다시 시도';

  @override
  String get chartTotalPages => '총 읽은 페이지';

  @override
  String get chartDailyAvgPages => '일평균';

  @override
  String get chartMaxDaily => '최고 기록';

  @override
  String get chartMinDaily => '최저 기록';

  @override
  String get chartConsecutiveDays => '연속 독서';

  @override
  String get chartTodayGoal => '오늘 목표';

  @override
  String get chartReadingProgress => '독서 진행 차트';

  @override
  String get chartDailyPages => '일별 페이지';

  @override
  String get chartCumulativePages => '누적 페이지';

  @override
  String get chartNoData => '아직 데이터가 없어요';

  @override
  String get chartDailyReadPages => '페이지';

  @override
  String get chartReadingStats => '독서 통계';

  @override
  String get chartAiInsight => 'AI 인사이트';

  @override
  String get chartCompletionRate => '완독률';

  @override
  String get chartRecordsHighlights => '기록/하이라이트';

  @override
  String get chartGenreAnalysis => '장르 분석';

  @override
  String get chartNoReadingRecords => '읽은 기록이 없어요';

  @override
  String get myPageTitle => '마이페이지';

  @override
  String get myPageSettings => '설정';

  @override
  String get myPageChangeAvatar => '변경';

  @override
  String get myPageLogout => '로그아웃';

  @override
  String get myPageDeleteAccount => '계정 삭제';

  @override
  String get myPageDeleteAccountConfirm =>
      '정말로 계정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.';

  @override
  String get myPageDeleteAccountSuccess => '계정이 성공적으로 삭제되었습니다.';

  @override
  String get myPageDeleteAccountFailed => '계정 삭제에 실패했습니다. 다시 시도해주세요.';

  @override
  String myPageDeleteAccountError(String error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String get myPageNotificationTimeTitle => '알림 시간 설정';

  @override
  String get myPageNoNickname => '닉네임 없음';

  @override
  String get myPageNicknameHint => '닉네임을 입력하세요';

  @override
  String get myPageDarkMode => '다크 모드';

  @override
  String get myPageDailyReadingNotification => '매일 독서 목표 알림';

  @override
  String myPageNotificationTime(String time) {
    return '매일 $time에 알림';
  }

  @override
  String get myPageNoNotification => '알림을 받지 않습니다';

  @override
  String get myPageNotificationEnabled => '알림이 활성화되었습니다';

  @override
  String get myPageNotificationDisabled => '알림이 비활성화되었습니다';

  @override
  String get myPageNotificationChangeFailed => '알림 설정 변경에 실패했습니다';

  @override
  String get myPageTestNotification => '테스트 알림 (30초 후)';

  @override
  String get myPageTestNotificationSent => '30초 후에 테스트 알림이 발송됩니다!';

  @override
  String get myPageAvatarChanged => '프로필 이미지가 변경되었습니다';

  @override
  String myPageAvatarChangeFailed(String error) {
    return '프로필 이미지 변경 실패: $error';
  }

  @override
  String get loginAppName => '북골라스';

  @override
  String get loginEmailLabel => '이메일';

  @override
  String get loginPasswordLabel => '비밀번호';

  @override
  String get loginNicknameLabel => '닉네임';

  @override
  String get loginOrDivider => '또는';

  @override
  String get loginButton => '로그인';

  @override
  String get loginSignupButton => '회원가입';

  @override
  String get loginDescriptionSignIn => '오늘도 한 페이지,\n당신의 독서를 응원합니다';

  @override
  String get loginDescriptionSignUp => '북골라스와 함께\n독서 습관을 시작해보세요';

  @override
  String get loginDescriptionForgotPassword => '가입하신 이메일로\n재설정 링크를 보내드립니다';

  @override
  String get loginEmailHint => 'example@email.com';

  @override
  String get loginPasswordHint => '6자 이상 입력해주세요';

  @override
  String get loginNicknameHint => '앱에서 사용할 이름';

  @override
  String get loginEmailRequired => '이메일을 입력해주세요';

  @override
  String get loginEmailInvalid => '올바른 이메일 주소를 입력해주세요';

  @override
  String get loginPasswordRequired => '비밀번호를 입력해주세요';

  @override
  String get loginPasswordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get loginNicknameRequired => '닉네임을 입력해주세요';

  @override
  String get loginForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get loginNoAccount => '계정이 없으신가요? 회원가입';

  @override
  String get loginHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get loginBackToSignIn => '로그인으로 돌아가기';

  @override
  String get loginSaveEmail => '이메일 저장';

  @override
  String get loginSignupSuccess => '회원가입이 완료되었습니다. 이메일을 확인해주세요.';

  @override
  String get loginResetPasswordSuccess => '비밀번호 재설정 이메일을 보냈습니다.';

  @override
  String get loginUnexpectedError => '예상치 못한 오류가 발생했습니다.';

  @override
  String get loginErrorInvalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get loginErrorEmailNotConfirmed => '이메일 인증이 완료되지 않았습니다.';

  @override
  String get loginErrorEmailAlreadyRegistered => '이미 등록된 이메일입니다.';

  @override
  String get loginErrorPasswordTooShort => '비밀번호는 6자 이상이어야 합니다.';

  @override
  String get reviewTitle => '독후감';

  @override
  String get reviewSave => '저장';

  @override
  String get reviewReplace => '대체하기';

  @override
  String get reviewExit => '나가기';

  @override
  String get reviewDraftLoaded => '임시 저장된 내용을 불러왔습니다.';

  @override
  String get reviewCopied => '독후감이 복사되었습니다.';

  @override
  String get reviewBookNotFound => '책 정보를 찾을 수 없습니다.';

  @override
  String get reviewSaveFailed => '저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get reviewSaveError => '저장 중 오류가 발생했습니다.';

  @override
  String get reviewReplaceConfirm => '현재 작성 중인 내용이 있습니다.\nAI 초안으로 대체하시겠습니까?';

  @override
  String get reviewReplaceButton => '대체하기';

  @override
  String get reviewAIDraftGenerated => 'AI 초안이 생성되었습니다. 자유롭게 수정해주세요!';

  @override
  String get reviewAIDraftFailed => 'AI 초안 생성에 실패했습니다. 다시 시도해주세요.';

  @override
  String get reviewAIDraftError => 'AI 초안 생성 중 오류가 발생했습니다.';

  @override
  String get reviewSaveComplete => '독후감이 저장되었습니다!';

  @override
  String get reviewSaveCompleteMessage =>
      '저장한 독후감은 \'독후감\' 탭 또는\n\'나의 서재 > 독후감\'에서 확인할 수 있어요.';

  @override
  String get reviewExitConfirm => '작성 중단하고 나가시겠어요?';

  @override
  String get reviewExitMessage => '작성 중이던 독후감은 임시 저장됩니다.';

  @override
  String get reviewHint => '이 책을 읽고 느낀 점, 인상 깊었던 부분, 나에게 준 영감 등을 자유롭게 적어보세요.';

  @override
  String get readingStartSetDate => '시작일 지정';

  @override
  String get readingStartUndetermined => '미정';

  @override
  String get readingStartTitle => '독서 시작하기';

  @override
  String get readingStartSubtitle => '독서를 시작할 책을 검색해보세요.';

  @override
  String get readingStartNoResults => '검색 결과가 없습니다';

  @override
  String get readingStartAnalyzing => '독서 패턴을 분석하고 있어요...';

  @override
  String get readingStartAiRecommendation => 'AI 맞춤 추천';

  @override
  String readingStartAiRecommendationDesc(String userName) {
    return '$userName님의 독서 패턴을 분석하여 추천하는 책들이에요';
  }

  @override
  String get readingStartSearchHint => '책 제목을 입력해주세요.';

  @override
  String get readingStartSelectionComplete => '선택 완료';

  @override
  String get readingStartConfirm => '확인';

  @override
  String readingStartPages(num totalPages) {
    return '$totalPages페이지';
  }

  @override
  String get readingStartPlannedDate => '독서 시작 예정일';

  @override
  String get readingStartToday => '오늘부터 시작합니다';

  @override
  String get readingStartTargetDate => '목표 마감일';

  @override
  String get readingStartTargetDateNote => '독서 시작 후에도 목표일을 변경할 수 있습니다';

  @override
  String get readingStartSaveError => '독서 정보 저장에 실패했습니다.';

  @override
  String get readingStartReserve => '독서 예약하기';

  @override
  String get readingStartBegin => '독서 시작';

  @override
  String get dialogOpacity => '투명도';

  @override
  String get dialogThickness => '굵기';

  @override
  String get dialogTakePhoto => '카메라로 촬영';

  @override
  String get dialogReplaceImage => '교체하기';

  @override
  String get dialogViewFull => '전체보기';

  @override
  String get dialogCopy => '복사하기';

  @override
  String get dialogEdit => '수정하기';

  @override
  String get dialogSaved => '저장되었습니다';

  @override
  String get dialogSaving => '저장 중...';

  @override
  String get dialogUpload => '업로드';

  @override
  String get dialogSelect => '선택';

  @override
  String get dialogApply => '적용하기';

  @override
  String get dialogExtract => '추출하기';

  @override
  String get dialogOkay => '괜찮아요';

  @override
  String get dialogExtractIt => '추출할게요';

  @override
  String get dialogThinkAboutIt => '고민해볼게요';

  @override
  String get genreNovel => '소설';

  @override
  String get genreLiterature => '문학';

  @override
  String get genreSelfHelp => '자기계발';

  @override
  String get genreBusiness => '경제경영';

  @override
  String get genreHumanities => '인문학';

  @override
  String get genreScience => '과학';

  @override
  String get genreHistory => '역사';

  @override
  String get genreEssay => '에세이';

  @override
  String get genrePoetry => '시';

  @override
  String get genreComic => '만화';

  @override
  String get genreUncategorized => '미분류';

  @override
  String get errorInitFailed => '초기화 중 오류가 발생했습니다';

  @override
  String get errorLoadFailed => '불러오기 실패';

  @override
  String get errorNoRecords => '기록이 없습니다';

  @override
  String get loadingInit => '앱을 초기화하는 중...';

  @override
  String get calendarMonthSelect => '월 선택';

  @override
  String calendarPagesRead(num count) {
    return '$count페이지 읽음';
  }

  @override
  String get calendarCompleted => '완독';

  @override
  String get onboardingTitle1 => '나만의 독서 여정을 기록하세요';

  @override
  String get onboardingDescription1 =>
      '읽고 싶은 책을 등록하고,\n독서 목표와 진행 상황을 한눈에 관리하세요.';

  @override
  String get onboardingTitle2 => 'AI로 독서 기록을 검색하세요';

  @override
  String get onboardingDescription2 => '기억나는 내용을 검색하면\nAI가 관련된 메모와 책을 찾아드립니다.';

  @override
  String get onboardingTitle3 => '다음 읽을 책을 추천받으세요';

  @override
  String get onboardingDescription3 =>
      '지금까지 읽은 책을 바탕으로\n당신의 취향에 맞는 책을 AI가 추천합니다.';

  @override
  String get readingProgressTitle => '진행률 히스토리';

  @override
  String get readingProgressLoadFailed => '진행률 불러오기 실패';

  @override
  String get readingProgressNoRecords => '진행률 기록이 없습니다.';

  @override
  String get barcodeScannerTitle => 'ISBN 바코드 스캔';

  @override
  String get barcodeScannerHint => '책 뒷면의 ISBN 바코드를 스캔해주세요';

  @override
  String get scannerErrorPermissionDenied => '카메라 권한이 필요합니다\n설정에서 권한을 허용해주세요';

  @override
  String get scannerErrorInitializing => '카메라를 초기화하는 중입니다';

  @override
  String get scannerErrorDefault => '카메라 오류가 발생했습니다\n다시 시도해주세요';

  @override
  String get bookstoreSelectTitle => '서점 선택';

  @override
  String get bookstoreAladdin => '알라딘';

  @override
  String get bookstoreKyobo => '교보문고';

  @override
  String get expandedNavBackToDetail => '독서상세 메뉴로';

  @override
  String get extractedTextTitle => '추출된 텍스트';

  @override
  String get extractedTextSubtitle => '추출된 내용을 확인해주세요. 직접 수정도 가능해요!';

  @override
  String get extractedTextApplyButton => '적용하기';

  @override
  String get extractedTextCancelButton => '다시 선택';

  @override
  String get extractedTextHint => '텍스트를 입력하세요';

  @override
  String get fullTextViewTitle => '기록 문구';

  @override
  String get fullTextViewHint => '텍스트를 입력하세요...';

  @override
  String get fullTextViewCopied => '텍스트가 복사되었습니다.';

  @override
  String get highlightEditTitle => '하이라이트 편집';

  @override
  String get highlightEditOpacity => '투명도';

  @override
  String get highlightEditThickness => '굵기';

  @override
  String get koreanDatePickerYear => '년';

  @override
  String get koreanDatePickerMonth => '월';

  @override
  String get koreanDatePickerDay => '일';

  @override
  String get koreanTimePickerHour => '시';

  @override
  String get koreanTimePickerMinute => '분';

  @override
  String get koreanYearMonthPickerYear => '년';

  @override
  String get koreanYearMonthPickerMonth => '월';

  @override
  String get liquidGlassSearchHint => '책 제목을 입력해주세요.';

  @override
  String get readingDetailPageUpdate => '페이지 업데이트';

  @override
  String get recommendationViewDetail => '책 내용 상세보기';

  @override
  String get recommendationViewDetailSubtitle => '서점에서 책 정보를 확인해요';

  @override
  String get recommendationStartReading => '독서 시작';

  @override
  String get recommendationStartReadingSubtitle => '이 책으로 독서를 시작합니다';

  @override
  String get recommendationBookstoreSelect => '서점 선택';

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
  String get chartHighlightStatsTitle => 'Highlights & Records';

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
  String get recallTextCopied => '텍스트가 복사되었습니다';

  @override
  String get recallSearchAllRecords => '모든 기록 검색';

  @override
  String get recallSearchingAllBooks => '모든 책에서 검색하는 중...';

  @override
  String get recallRecentGlobalSearches => '최근 전역 검색';

  @override
  String get recallSearchAllReadingRecords => '모든 독서 기록에서 검색하세요';

  @override
  String get recallAiFindsScatteredRecords => '여러 책에 흩어진 기록들을\nAI가 종합하여 찾아드립니다';

  @override
  String get recallAiAnswer => 'AI 답변';

  @override
  String get recallReferencedRecords => '참고한 기록';

  @override
  String recallMoreBooks(int count) {
    return '$count권 더 보기';
  }

  @override
  String recallRecordCount(int count) {
    return '$count개 기록';
  }

  @override
  String get recallSearchMyRecords => '내 기록 검색';

  @override
  String get recallSearchingYourRecords => '당신의 기록을 검색하는 중...';

  @override
  String get recallRecentSearches => '최근 검색';

  @override
  String get recallJustNow => '방금 전';

  @override
  String recallMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String recallHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String recallDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get recallSuggestedQuestions => '추천 질문';

  @override
  String get recallSuggestedQuestion1 => '가장 인상 깊었던 부분은?';

  @override
  String get recallSuggestedQuestion2 => '연습하기 위해 적은 내용은?';

  @override
  String get recallSuggestedQuestion3 => '저자의 핵심 메시지는?';

  @override
  String get recallSuggestedQuestion4 => '공감했던 부분은?';

  @override
  String get recallSearchCurious => '궁금한 내용을 검색해보세요';

  @override
  String get recallFindInRecords => '하이라이트, 메모, 사진 속에서 찾아드립니다';

  @override
  String get recallRelatedRecords => '관련 기록';

  @override
  String get recallPage => '페이지';

  @override
  String get recallContentCopied => '내용이 복사되었습니다';

  @override
  String get recallViewInBook => '이 책에서 보기';

  @override
  String get recallCopy => '복사';

  @override
  String bookListPlannedStartDate(String date) {
    return '시작 예정: $date';
  }

  @override
  String get bookListUndetermined => '시작일 미정';

  @override
  String bookListCompletedIn(int days) {
    return '$days일만에 완독';
  }

  @override
  String get bookListCompletedSameDay => '당일 완독';

  @override
  String bookListAchievementRate(int rate) {
    return '달성률 $rate%';
  }

  @override
  String get bookListUnknown => '알 수 없음';

  @override
  String bookListCompletedDate(String date) {
    return '완독일 $date';
  }

  @override
  String get readingStartPriority => '우선순위 (선택사항)';

  @override
  String get languageChangeConfirmTitle => '언어를 변경하시겠습니까?';

  @override
  String languageChangeConfirmMessage(String language) {
    return '언어를 $language(으)로 변경하시겠습니까?';
  }

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => '영어';

  @override
  String get readingStatusLabel => '독서 상태';

  @override
  String get readingStatusPlanned => '읽을 예정';

  @override
  String get readingStatusStartNow => '바로 시작';

  @override
  String get scheduleTargetDays => '목표 일수';

  @override
  String scheduleTargetDaysValue(int count) {
    return '$count일';
  }

  @override
  String get scheduleDailyGoal => '하루 목표';

  @override
  String get datePickerMonthJan => '1월';

  @override
  String get datePickerMonthFeb => '2월';

  @override
  String get datePickerMonthMar => '3월';

  @override
  String get datePickerMonthApr => '4월';

  @override
  String get datePickerMonthMay => '5월';

  @override
  String get datePickerMonthJun => '6월';

  @override
  String get datePickerMonthJul => '7월';

  @override
  String get datePickerMonthAug => '8월';

  @override
  String get datePickerMonthSep => '9월';

  @override
  String get datePickerMonthOct => '10월';

  @override
  String get datePickerMonthNov => '11월';

  @override
  String get datePickerMonthDec => '12월';

  @override
  String get bookDetailSchedule => '독서 일정';

  @override
  String get bookDetailGoalProgress => '목표 달성 현황';

  @override
  String get bookDetailGoalAchieved => '목표 달성';

  @override
  String get bookDetailDeleteReading => '독서 삭제';

  @override
  String get bookDetailNoPhotos => '아직 추가된 사진이 없습니다';

  @override
  String get bookDetailAddPhotoHint => '하단 + 버튼으로 추가해보세요';

  @override
  String get editReadingPlanTitle => '독서 계획 수정';

  @override
  String get editPlannedStartDate => '시작 예정일';

  @override
  String get changeTargetDateTitle => '목표일 변경';

  @override
  String attemptChangeMessage(int count) {
    return '$count번째 도전으로 변경됩니다';
  }

  @override
  String get confirmChange => '변경하기';

  @override
  String bookDetailAchievementStatus(int passed, int achieved) {
    return '$passed일 중 $achieved일 달성';
  }

  @override
  String attemptOrdinal(int count) {
    return '$count번째';
  }

  @override
  String totalDaysFormat(int count) {
    return '($count일)';
  }

  @override
  String pagesRemaining(int count) {
    return '$count페이지 남았어요';
  }

  @override
  String todayGoalWithPages(int count) {
    return '오늘 목표: ${count}p';
  }

  @override
  String streakDaysAchieved(int count) {
    return '$count일 연속 달성!';
  }

  @override
  String get streakFirstRecord => '오늘 첫 기록을 남겨보세요';

  @override
  String get dailyTargetChangeTitle => '일일 목표 페이지 변경';

  @override
  String pagesRemainingShort(int count) {
    return '$count페이지';
  }

  @override
  String pagesRemainingWithDays(int days) {
    return ' 남았어요 · D-$days';
  }

  @override
  String get expectedSchedule => '예상 스케줄';

  @override
  String get pagesPerDay => '페이지/일';

  @override
  String get dailyTargetConfirmTitle => '일일 목표 변경';

  @override
  String get dailyTargetConfirmMessage =>
      '오늘의 목표는 수정할 수 없지만,\n내일부터 변경된 목표가 적용됩니다.';

  @override
  String get dailyTargetConfirmQuestion => '변경하시겠어요?';

  @override
  String get updatePageTitle => '현재 페이지 업데이트';

  @override
  String currentPageLabel(int page) {
    return '현재 ${page}p';
  }

  @override
  String totalPageLabel(int page) {
    return ' / 총 ${page}p';
  }

  @override
  String get newPageNumber => '새 페이지 번호';

  @override
  String get updateButton => '업데이트';

  @override
  String get validationEnterNumber => '숫자를 입력해주세요';

  @override
  String get validationPageMinimum => '0 이상의 페이지를 입력해주세요';

  @override
  String validationPageExceedsTotal(int total) {
    return '총 페이지($total)를 초과할 수 없습니다';
  }

  @override
  String validationPageBelowCurrent(int current) {
    return '현재 페이지($current) 이하입니다';
  }

  @override
  String get addRecordTitle => '기록 추가';

  @override
  String get tapToAddImage => '터치하여 이미지 추가';

  @override
  String get optionalLabel => '(선택사항)';

  @override
  String get recordTextLabel => '기록 문구';

  @override
  String get clearAllButton => '모두 지우기';

  @override
  String get recordHint => '인상 깊은 대목을 기록해보세요.';

  @override
  String get uploadButton => '업로드';

  @override
  String get resetButton => '초기화';

  @override
  String get highlightLabel => '하이라이트';

  @override
  String highlightWithCount(int count) {
    return '하이라이트 ($count)';
  }

  @override
  String get replaceButton => '교체하기';

  @override
  String get extractTextButton => '텍스트 추출';

  @override
  String get viewFullButton => '전체보기';

  @override
  String get resetConfirmMessage => '내용을 정말 초기화하시겠어요?';

  @override
  String get uploading => '업로드 중...';

  @override
  String get extractTextConfirmTitle => '텍스트를 추출하시겠어요?';

  @override
  String get extractTextCreditsMessage => '크레딧을 소모합니다.';

  @override
  String get extractTextOverwriteMessage => '작성하신 텍스트를 덮어씁니다.\n크레딧을 소모합니다.';

  @override
  String get noThanksButton => '괜찮아요';

  @override
  String get extractButton => '추출할게요';

  @override
  String get extractingText => '텍스트 추출 중...';

  @override
  String get reselectButton => '다시 선택';

  @override
  String get applyButton => '적용하기';

  @override
  String get aiFeaturesTitle => 'AI 기능';

  @override
  String get searchRecordsButton => '기록 검색';

  @override
  String get bookRecommendButton => '책 추천';

  @override
  String get calendarFilterAll => '전체';

  @override
  String get calendarFilterReading => '읽고 있는 책';

  @override
  String get calendarFilterCompleted => '완독한 책';

  @override
  String get pageUpdateButton => '페이지 업데이트';

  @override
  String get noProgressRecords => '진행률 기록이 없습니다';

  @override
  String get oneLineReviewOptional => '한줄평 (선택사항)';

  @override
  String todayGoalChanged(int pages) {
    return '오늘 목표: ${pages}p로 변경되었습니다';
  }

  @override
  String get bookInfoNotFound => '도서 정보를 찾을 수 없습니다';

  @override
  String get goalChangeFailed => '목표 변경에 실패했습니다';

  @override
  String get unsavedChangesMessage => '수정 중인 내용이 있습니다.';

  @override
  String get discardChangesButton => '변경사항 무시';

  @override
  String get continueEditingButton => '이어서 하기';

  @override
  String get pageNotSet => '페이지 미설정';

  @override
  String get textInputHint => '텍스트를 입력하세요...';

  @override
  String get noRecordedText => '기록된 문구가 없습니다.';

  @override
  String get textCopied => '텍스트가 복사되었습니다.';

  @override
  String get copyButton => '복사하기';

  @override
  String get editButton => '수정하기';

  @override
  String get loadingImage => '이미지 불러오는 중...';

  @override
  String get ocrAreaSelectTitle => '텍스트 추출 영역 선택';

  @override
  String get ocrExtractionFailed => '텍스트를 추출하지 못했습니다. 다른 영역을 선택해보세요.';

  @override
  String get imageLoadFailed => '이미지를 불러오지 못했습니다.';

  @override
  String get ocrReExtractionFailed => '텍스트 다시 추출에 실패했습니다.';

  @override
  String get documentScanFailed => '문서 스캔에 실패했습니다.';

  @override
  String get reScanButton => '다시 스캔';

  @override
  String pageExceedsTotalError(int total) {
    return '총 페이지 수($total)를 초과할 수 없습니다';
  }

  @override
  String get highlightEditDone => '완료';

  @override
  String memorablePagesSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get memorablePagesSortByPage => '페이지';

  @override
  String get memorablePagesSortByDate => '날짜';

  @override
  String get memorablePagesSortPageDesc => '페이지 높은순';

  @override
  String get memorablePagesSortPageAsc => '페이지 낮은순';

  @override
  String get memorablePagesSortDateDesc => '최근 기록순';

  @override
  String get memorablePagesSortDateAsc => '오래된 기록순';

  @override
  String get memorablePagesDelete => '삭제';

  @override
  String get memorablePagesSelect => '선택';

  @override
  String get memorablePagesDone => '완료';

  @override
  String get historyTabCumulativePages => '📈 누적 페이지';

  @override
  String get historyTabDailyPages => '일일 페이지';

  @override
  String get historyTabCompletionTitle => '완독 축하해요!';

  @override
  String get historyTabCompletionMessage => '목표를 달성했어요. 다음 책도 함께 읽어볼까요?';

  @override
  String get historyTabDailyRecords => '📅 일별 기록';

  @override
  String historyTabCumulativeLabel(int page) {
    return '누적: $page 페이지';
  }

  @override
  String get historyTabPagesUnit => '페이지';

  @override
  String get bookReviewTabTitle => '나의 독후감';

  @override
  String get bookReviewTabEditButton => '독후감 수정하기';

  @override
  String get authorLabel => '지은이';

  @override
  String get aiDraftGenerating => 'AI가 초안을 작성하고 있어요...';

  @override
  String get aiDraftGenerate => 'AI로 독후감 초안 작성하기';

  @override
  String get bookInfoDetail => '도서 상세 정보';

  @override
  String get invalidUrl => '올바른 URL을 입력해주세요';

  @override
  String daysRecorded(int count) {
    return '$count일 기록';
  }

  @override
  String get startDateLabel => '시작일';
}
