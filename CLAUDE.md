# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**북골라스 / Bookgolas** is a reading goal tracking mobile application built with Flutter. Users can set reading goals, track their progress, and manage their reading history through a simple and intuitive interface.

## Git Workflow

### Branch Strategy

```
main (Production)
 │
 └── dev (TestFlight)
      │
      └── daily/YYYY-MM-DD (일별 작업 그룹화 - 직접 커밋 금지!)
           │
           ├── feature/BYU-XXX-task-name (실제 작업 브랜치)
           ├── feature/BYU-YYY-another-task
           └── fix/BYU-ZZZ-bug-fix
```

**브랜치 역할:**

| 브랜치 | 용도 | 직접 커밋 |
|--------|------|----------|
| `main` | Production 릴리즈 | ❌ 금지 |
| `dev` | 개발 통합 브랜치 | ❌ 금지 |
| `daily/YYYY-MM-DD` | 일별 작업 그룹화 (머지 타겟) | ❌ 금지 |
| `feature/BYU-XXX-*` | **실제 코드 작업** | ✅ 허용 |

### Daily Workflow

⚠️ **중요: `daily` 브랜치에 직접 커밋하지 마라. 반드시 `feature/BYU-XXX` 브랜치를 만들어서 작업해라.**

```
1. 작업 시작
   ├── daily/YYYY-MM-DD 브랜치가 없으면 dev에서 생성
   └── daily 브랜치에서 feature/BYU-XXX 브랜치 생성 ← 여기서 작업!

2. 이슈별 작업 (각 이슈마다 반복)
   ├── feature/BYU-XXX 브랜치에서 코드 작성 및 커밋
   ├── 작업 완료 시 feature/BYU-XXX → daily PR 생성 및 머지
   └── 다음 이슈는 daily에서 새로운 feature/BYU-YYY 브랜치 생성

3. 일일 작업 완료
   └── daily → dev PR 생성 → 머지 → TestFlight 자동 배포

4. 버전 릴리즈
   └── dev → main PR 생성 (버전 태그: v1.x.x) → 머지 → App Store 배포
```

### 브랜치 생성 예시

```bash
# 1. daily 브랜치 생성 (없으면)
git checkout dev
git pull origin dev
git checkout -b daily/2025-01-07

# 2. 이슈 작업용 feature 브랜치 생성
git checkout daily/2025-01-07
git checkout -b feature/BYU-225-fix-network-error

# 3. 작업 및 커밋 (feature 브랜치에서!)
# ... 코드 작성 ...
git add .
git commit -m "fix: 네트워크 오류 수정 (BYU-225)"

# 4. feature → daily PR 생성 및 머지
git push origin feature/BYU-225-fix-network-error
gh pr create --base daily/2025-01-07 --head feature/BYU-225-fix-network-error

# 5. 다음 이슈는 daily에서 새 브랜치
git checkout daily/2025-01-07
git pull origin daily/2025-01-07
git checkout -b feature/BYU-248-tab-cycling
```

### Commit Rules

- 반드시 gh를 **lbo728** 계정으로 커밋, 푸시, PR을 진행해야해.
- 커밋 메세지는 영문 컨벤셔널 커밋으로 해야해. (단, description은 한글 불릿 포인트로 작성.)
- 맥락 별로 커밋을 만들며 진행해야해.

### Merge Rules

- PR 머지 시 반드시 **"Create a merge commit"** 방식으로 머지해라.
- ❌ "Squash and merge" 사용 금지
- ❌ "Rebase and merge" 사용 금지
- `gh pr merge` 사용 시: `gh pr merge --merge` (기본값이 merge commit)

### PR Template

PR 생성 시 아래 템플릿을 사용해. (인용문은 지우고 해당 내용을 작성)

```markdown
> 이번 PR의 목적을 한 문장으로 요약해주세요.
>
> - 예: 사용자가 프로필 정보를 수정할 수 있는 기능을 추가했습니다.

## 📋 Changes

> 주요 변경사항을 bullet로 정리해주세요.
>
> - 예:
>   - `UserProfileEdit.tsx` 컴포넌트 추가
>   - `/api/user/profile` PUT 엔드포인트 연결
>   - Validation 로직 추가

## 🧠 Context & Background

> 이 변경이 필요한 이유를 설명해주세요.
> 관련된 이슈나 문서 링크를 첨부해도 좋아요.
>
> - 예: 유저 피드백에 따라 프로필 수정 기능이 필요했습니다. (#45)

## ✅ How to Test

> 테스트 방법을 단계별로 작성해주세요.
>
> - 예:
>   1. `/profile/edit` 페이지로 이동
>   2. 이름 수정 후 저장 클릭
>   3. 수정 내용이 DB에 반영되는지 확인

## 🧾 Screenshots or Videos (Optional)

> UI 변경이 있을 경우, Before / After 이미지를 첨부해주세요.
> 또는 Loom, GitHub Video를 추가해도 좋아요.

## 🔗 Related Issues

> 연관된 이슈를 연결해주세요.
>
> - 예:
>   - Closes: #123
>   - Related: #456

## 🙌 Additional Notes (Optional)

> 기타 참고사항, TODO, 리뷰어에게 요청사항 등을 작성해주세요. - 예: 스타일 관련 부분은 별도 PR로 분리 예정입니다.
```

## Code Rules

나에게 리뷰할 때만 주석을 포함해서 알려주고, 커밋 및 푸시 시점에는 주석은 삭제해야해.

## Tech Stack

- **Frontend**: Flutter 3.5.3 with Dart
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Provider 6.1.2
- **Backend**: Supabase (PostgreSQL + Realtime + Auth)
- **External APIs**: Aladin API for book search
- **Charts**: fl_chart 0.66.0

## Development Commands

### Setup

```bash
cd app
flutter pub get
```

### Running the App

```bash
cd app
flutter run
```

### Testing

```bash
cd app
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Analysis

```bash
cd app
flutter analyze
```

### Build

```bash
cd app
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios
```

## Environment Configuration

The app requires a `.env` file in the `app/` directory with:

- `ALADIN_TTB_KEY`: Aladin API key for book search
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `ENVIRONMENT`: 'development' or 'production'

Configuration is validated at app startup via `AppConfig.validateApiKeys()` in main.dart:18-22.

## Architecture

### Layer Structure (3-Layer)

**UI Layer** (`lib/ui/`)

- Feature-based organization with ViewModels and Widgets
- ViewModels extend `ChangeNotifier` for reactive state management
- Each feature has its own folder: `home/`, `book/`, `reading/`, `calendar/`, `auth/`
- Common UI components in `ui/core/ui/`

**Domain Layer** (`lib/domain/`)

- Business models: `Book`, `BookSearchResult`, `UserModel`
- Pure Dart classes with no framework dependencies

**Data Layer** (`lib/data/`)

- `repositories/`: Data access abstraction (Repository pattern)
- `services/`: External API communication (Aladin, Supabase) and business services
- `BookService` acts as an in-memory cache singleton

### Key Patterns

**MVVM Flow:**

1. View (Widget) triggers user action
2. ViewModel method is called
3. ViewModel requests data via Repository
4. Repository delegates to Service
5. Service fetches/updates data
6. Result flows back to ViewModel
7. ViewModel calls `notifyListeners()`
8. View automatically rebuilds

**Dependency Injection:**
Provider pattern with `MultiProvider` in main.dart:41-57. Services → Repositories → ViewModels are injected in order.

## Core Features

### Authentication Flow

- Entry point: `AuthWrapper` in main.dart:71-84
- Uses Supabase Auth with Apple Sign-In support
- `AuthService` manages user state via `ChangeNotifier`
- Logged-in users see `MainScreen`, others see `LoginScreen`

### Navigation

- Bottom navigation with 3 tabs: Home (BookListScreen), Reading Stats (ReadingChartScreen), My Page (MyPageScreen)
- Floating Action Button for "Start New Reading"
- Routing definitions in `routing/app_router.dart`

### Book Management

- Search books via Aladin API (`AladinApiService.searchBooks()`)
- Aladin API makes two calls per book: ItemSearch for list, then ItemLookUp for detailed page count
- Books stored in Supabase `books` table
- CRUD operations through `BookRepository` → `BookService`

### Reading Progress Tracking

- Users set start date, target completion date, and daily page goals
- Current page updates tracked with timestamps
- Progress visualization in charts using fl_chart
- Daily/weekly/monthly aggregations in `ReadingChartScreen`

## Database Schema

**books table** (Supabase):

- `id` (UUID, PK)
- `user_id` (UUID, FK to auth.users)
- `title` (TEXT)
- `author` (TEXT)
- `start_date` (TIMESTAMP)
- `target_date` (TIMESTAMP)
- `image_url` (TEXT)
- `current_page` (INTEGER)
- `total_pages` (INTEGER)
- `daily_target_pages` (INTEGER)
- `created_at`, `updated_at` (TIMESTAMP)

**reading_progress table**:

- Tracks daily page updates with timestamps
- Used for historical charts and streak calculations

## Important Implementation Notes

### Aladin API Integration

- Base URL: `http://www.aladin.co.kr/ttb/api/`
- Search endpoint: `ItemSearch.aspx`
- Detail endpoint: `ItemLookUp.aspx`
- Response format: JSON (`output=js`)
- API version: `20131101`
- Implementation: app/lib/data/services/aladin_api_service.dart

### Supabase Integration

- Initialized in main.dart:24-31 before app runs
- Row-Level Security (RLS) should be enabled for production
- Currently allows all access in development (see PRD.md:289)

### State Management

- HomeViewModel tracks book list state, loading, and errors
- Provider's `Consumer` widgets listen to ViewModels
- Call `notifyListeners()` after any state change

### Image Handling

- Book covers from Aladin API
- Fallback icon for missing images
- Widget: `BookImageWidget` in ui/core/ui/

## Common Development Workflows

### Adding a New Feature Screen

1. Create feature folder in `lib/ui/<feature_name>/`
2. Add `view_model/` for ViewModel (extends ChangeNotifier)
3. Add `widgets/` for UI screens
4. Register ViewModel in MultiProvider (main.dart)
5. Add route in `app_router.dart`

### Adding a New Data Model

1. Create model in `lib/domain/models/`
2. Add JSON serialization methods (`fromJson`, `toJson`)
3. Update Repository interface if needed
4. Implement in Service layer

### API Integration

1. Add API calls in `lib/data/services/`
2. Handle errors with try-catch blocks
3. Return null or empty lists on failure
4. Update Repository to use the new service method

## Project Roadmap

See BOOKGOLAS_ROADMAP.md for detailed roadmap. Key upcoming features:

- Enhanced UI/UX redesign
- AI-powered book recommendations
- Reading calendar with streak tracking
- OCR for page text extraction
- Backend migration to NestJS

## File Organization

```
lib/
├── ui/                    # UI Layer
│   ├── auth/              # Login, MyPage
│   ├── book/              # BookList, BookDetail
│   ├── reading/           # ReadingStart, ReadingChart
│   ├── calendar/          # CalendarScreen (in progress)
│   └── core/ui/           # Shared widgets (BookImageWidget)
├── domain/models/         # Book, UserModel
├── data/
│   ├── repositories/      # BookRepository (interface + impl)
│   └── services/          # AladinApiService, BookService, AuthService
├── config/                # AppConfig (API keys, environment)
├── utils/                 # DateUtils, helpers
├── routing/               # AppRouter
└── main.dart              # App entry point
```

## Testing Strategy

- Unit tests for ViewModels and Repositories
- Widget tests for UI components
- Integration tests for full user flows
- Mock Supabase and Aladin API calls in tests

## Important Files

- **main.dart**: App initialization, provider setup, main navigation
- **app/ARCHITECTURE.md**: Detailed architecture documentation
- **app/PRD.md**: Complete product requirements document
- **BOOKGOLAS_ROADMAP.md**: Product roadmap and business strategy
- **app/lib/config/app_config.dart**: Environment and API configuration
- **app/lib/data/services/aladin_api_service.dart**: Book search implementation
- **app/lib/data/repositories/book_repository.dart**: Data access layer
