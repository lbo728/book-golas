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
  String booksCount(int count) {
    return '$count권';
  }

  @override
  String daysCount(int count) {
    return '$count일';
  }

  @override
  String pagesCount(int count) {
    return '$count페이지';
  }

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
  String calendarPagesRead(int count) {
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
}
