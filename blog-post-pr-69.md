# 북골라스 독서 통계 화면 대규모 리팩토링 회고

> PR #69: daily/2026-01-22 | +6,109 / -1,040 lines

## TL;DR

Flutter 독서 앱 **북골라스**의 독서 통계 화면을 전면 개편했다. GitHub 스타일 히트맵, 도넛 차트, 연간 목표 카드 등 새로운 시각화 컴포넌트를 추가하고, 재사용 가능한 Liquid Glass 디자인 시스템을 구축했다. 그 과정에서 겪은 차트 오버플로우 이슈, 탭 상태 관리, Edge Function 한글 인코딩 문제 등을 해결한 기록.

---

## 1. 작업 배경

기존 독서 통계 화면은 단순한 바 차트 하나만 있었다. 사용자에게 더 풍부한 인사이트를 제공하기 위해 다음 기능들을 추가하기로 했다:

- **연간 독서 목표** 설정 및 진행률 추적
- **월별 독서량** 시각화
- **장르 분포** 분석
- **GitHub 스타일 독서 히트맵**

---

## 2. 주요 변경사항

### 2.1 3탭 구조로 전면 개편

독서 통계 화면을 **개요 / 분석 / 활동** 3개 탭으로 분리했다.

```dart
// reading_chart_screen.dart
class _ReadingChartScreenState extends State<ReadingChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  // 외부에서 탭 전환 가능하도록 GlobalKey 사용
  void cycleToNextTab() {
    final nextIndex = (_tabController.index + 1) % 3;
    _tabController.animateTo(nextIndex);
  }
}
```

### 2.2 GitHub 스타일 독서 히트맵

연간 독서 활동을 한눈에 볼 수 있는 히트맵을 구현했다.

```dart
// reading_streak_heatmap.dart
class ReadingStreakHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyPages;
  final int year;
  final int currentStreak;

  Widget _buildHeatmapGrid(bool isDark) {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);

    // 주 단위로 그리드 생성
    // 각 셀의 색상 강도는 해당 날짜의 독서량에 비례
  }
}
```

### 2.3 Core UI 컴포넌트 추출

여러 화면에서 재사용할 수 있도록 **Liquid Glass 디자인 시스템**을 구축했다.

```dart
// liquid_glass_tab_bar.dart
class LiquidGlassTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;

  static const Color liquidGlassColor = Color(0xFF5B7FFF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: controller,
      labelColor: labelColor ?? (isDark ? Colors.white : Colors.black),
      unselectedLabelColor: unselectedLabelColor ??
          (isDark ? Colors.grey[600] : Colors.grey[400]),
      indicatorColor: indicatorColor ?? liquidGlassColor,
      // ...
    );
  }
}
```

### 2.4 한국어 3휠 시간 선택기

알림 시간 설정을 위한 커스텀 타임피커를 만들었다. iOS의 기본 피커 대신 **오전/오후 | 시 | 분** 형태로 한국어에 맞게 구현.

```dart
// korean_time_picker.dart
class _KoreanTimePickerState extends State<KoreanTimePicker> {
  final List<String> _amPmLabels = ['오전', '오후'];
  final List<int> _hours12 = List.generate(12, (i) => i == 0 ? 12 : i);
  final List<int> _minutes = List.generate(60, (i) => i);

  int _convertTo24Hour() {
    if (_currentAmPmIndex == 0) {
      return _currentHour12 == 12 ? 0 : _currentHour12;
    } else {
      return _currentHour12 == 12 ? 12 : _currentHour12 + 12;
    }
  }
}
```

### 2.5 완독 축하 바텀시트

책을 완독했을 때 별점과 한줄평을 입력받는 UI를 추가했다.

```dart
// book_completion_sheet.dart
static String _getRatingMessage(int rating) {
  switch (rating) {
    case 1: return '아쉬웠어요 😢';
    case 2: return '그저 그랬어요 😐';
    case 3: return '괜찮았어요 🙂';
    case 4: return '재미있었어요! 😊';
    case 5: return '최고였어요! 🤩';
    default: return '';
  }
}
```

### 2.6 CSV 내보내기 Edge Function

독서 기록을 CSV로 내보내 이메일로 전송하는 Supabase Edge Function을 구현했다.

```typescript
// supabase/functions/export-reading-data/index.ts
function generateCsv(books: BookData[]): string {
  const headers = [
    "제목", "저자", "장르", "출판사", "ISBN",
    "독서상태", "별점", "한줄평", "도서링크",
    "독후감링크", "시작일", "완독일", "페이지", "메모개수",
  ];

  // BOM 추가로 엑셀에서 한글 깨짐 방지
  const bom = "\uFEFF";
  return bom + [headers.join(","), ...rows.map((row) => row.join(","))].join("\n");
}

async function sendEmailWithResend(email: string, csvContent: string, year: number) {
  const base64Csv = btoa(unescape(encodeURIComponent(csvContent)));
  // Resend API로 이메일 발송
}
```

---

## 3. 트러블슈팅

### 3.1 fl_chart 오버플로우 이슈

**문제**: 차트가 컨테이너 영역을 벗어나 레이아웃이 깨지는 현상

**원인**: `BarChart` 위젯의 기본 패딩과 `reservedSize` 설정 충돌

**해결**:
```dart
// Before: 오버플로우 발생
BarChart(
  BarChartData(
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true),
      ),
    ),
  ),
)

// After: 명시적 크기 제한
BarChart(
  BarChartData(
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40, // 명시적 지정
          getTitlesWidget: (value, meta) {
            return SizedBox(
              width: 35, // 고정 너비
              child: Text('${value.toInt()}'),
            );
          },
        ),
      ),
    ),
  ),
)
```

### 3.2 탭 전환 시 데이터 재로딩 문제

**문제**: 탭을 전환할 때마다 API를 다시 호출해서 깜빡임 발생

**해결**: 캐싱 레이어 추가
```dart
class _ReadingChartScreenState extends State<ReadingChartScreen> {
  // 데이터 캐싱
  List<Map<String, dynamic>>? _cachedRawData;
  Map<String, int> _genreDistribution = {};
  Map<int, int> _monthlyBookCount = {};

  Future<void> _loadData() async {
    // 모든 데이터를 한 번에 로드
    final results = await Future.wait([
      fetchUserProgressHistory(),
      _progressService.getGenreDistribution(year: currentYear),
      _progressService.getMonthlyBookCount(year: currentYear),
      _goalService.getYearlyProgress(year: currentYear),
      _progressService.getDailyReadingHeatmap(weeksToShow: 26),
    ]);

    // 캐시에 저장
    _cachedRawData = results[0];
    _genreDistribution = results[1];
    // ...
  }
}
```

### 3.3 CSV 한글 인코딩 깨짐

**문제**: 엑셀에서 CSV 파일을 열면 한글이 깨짐

**원인**: UTF-8 BOM 누락

**해결**:
```typescript
function generateCsv(books: BookData[]): string {
  // UTF-8 BOM 추가
  const bom = "\uFEFF";
  return bom + csvContent;
}

// Base64 인코딩 시에도 UTF-8 유지
const base64Csv = btoa(unescape(encodeURIComponent(csvContent)));
```

### 3.4 장르 분포 쿼리 최적화

**문제**: 장르별 집계 쿼리가 느림

**해결**: Supabase RPC 함수로 서버사이드 집계
```sql
-- 서버에서 집계 후 반환
CREATE OR REPLACE FUNCTION get_genre_distribution(p_user_id UUID, p_year INT)
RETURNS TABLE(genre TEXT, count BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(b.genre, '미분류') as genre,
    COUNT(*) as count
  FROM books b
  WHERE b.user_id = p_user_id
    AND EXTRACT(YEAR FROM b.created_at) = p_year
    AND b.deleted_at IS NULL
  GROUP BY b.genre
  ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. CI/CD 파이프라인 강화

DB 마이그레이션 안전성을 위해 GitHub Actions 워크플로우를 추가했다.

```yaml
# .github/workflows/schema-check.yml
name: Schema Validation

on:
  pull_request:
    branches: [main]
    paths:
      - 'supabase/migrations/**'

jobs:
  check-migrations:
    steps:
      - name: Check migration file naming
        run: |
          # YYYYMMDD_description.sql 형식 검증
          if ! [[ $filename =~ ^[0-9]{8}_[a-z_]+\.sql$ ]]; then
            echo "::error::Invalid migration filename"
            exit 1
          fi

      - name: Migration safety warning
        run: |
          echo "::warning::This PR contains database migrations!"
          echo "Ensure migrations are applied to PROD before merging"
```

---

## 5. 배운 점

1. **컴포넌트 추출 타이밍**: 두 번째 사용처가 생길 때 추출하는 게 적절하다. 너무 이른 추상화는 오히려 복잡도를 높인다.

2. **차트 라이브러리 제약**: fl_chart는 강력하지만, 레이아웃 계산에서 예상치 못한 동작이 있다. `reservedSize`와 `ConstrainedBox`를 적극 활용하자.

3. **Edge Function 디버깅**: Supabase Edge Function은 로컬 테스트가 까다롭다. `supabase functions serve`로 로컬 실행 후 curl로 테스트하는 습관을 들이자.

4. **한글 인코딩**: 파일 내보내기 기능에서 BOM은 필수다. 특히 Windows 엑셀 사용자를 위해.

---

## 6. 다음 할 일

- [ ] 히트맵 터치 시 해당 날짜 상세 정보 표시
- [ ] 목표 달성 시 축하 애니메이션 추가
- [ ] 통계 데이터 공유 기능 (이미지 생성)

---

**관련 이슈**: BYU-178, BYU-283, BYU-279, BYU-288
**머지된 PR**: [#65](https://github.com/lbo728/book-golas/pull/65), [#66](https://github.com/lbo728/book-golas/pull/66), [#67](https://github.com/lbo728/book-golas/pull/67), [#68](https://github.com/lbo728/book-golas/pull/68) → [#69](https://github.com/lbo728/book-golas/pull/69)
