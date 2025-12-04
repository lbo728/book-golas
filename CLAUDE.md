# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LitGoal (북골라스 / Bookgolas)** is a reading goal tracking mobile application built with Flutter. Users can set reading goals, track their progress, and manage their reading history through a simple and intuitive interface.

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
