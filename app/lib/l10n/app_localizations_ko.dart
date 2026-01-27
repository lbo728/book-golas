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
}
