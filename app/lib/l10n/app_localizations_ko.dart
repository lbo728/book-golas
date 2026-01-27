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
  String get myPageTitle => '마이페이지';

  @override
  String get myPageSettings => '설정';

  @override
  String get myPageChangeAvatar => '변경';

  @override
  String get myPageLogout => '로그아웃';

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
  String get reviewTitle => '독후감';

  @override
  String get reviewSave => '저장';

  @override
  String get reviewReplace => '대체하기';

  @override
  String get reviewExit => '나가기';

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
}
