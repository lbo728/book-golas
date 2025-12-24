# Book Golas (LitGoal) Project Context

## 1. Project Overview
**Name:** Book Golas (also referred to as LitGoal)
**Purpose:** A mobile application to help users set reading goals, track progress, and form reading habits.
**Current Stage:** MVP Stabilization & UI/UX Improvement.
**Roadmap:** Focused on stabilizing core features, improving the UI/UX (Calendar, Home), and planning for AI-based recommendations.

## 2. Technology Stack
*   **Frontend:** Flutter (Dart)
    *   State Management: `Provider` (MVVM Pattern)
    *   UI Kit: Material Design (migrating to custom "Bookgolas" style)
*   **Backend:**
    *   **Supabase:** PostgreSQL Database, Auth, Realtime, Edge Functions (TypeScript/Deno).
    *   **Firebase:** Cloud Messaging (FCM) for push notifications (Nudges).
*   **External APIs:** Aladin API (Korean book search).

## 3. Architecture & Structure
The project follows a **Clean Architecture** approach with **MVVM**:

*   **`app/lib/ui/`**: UI Layer (Screens, Widgets, ViewModels).
    *   `core/`: Shared UI components.
    *   `home/`, `book/`, `reading/`, `calendar/`: Feature-based directories.
*   **`app/lib/domain/`**: Business Logic & Models (Entities).
*   **`app/lib/data/`**: Data Layer (Repositories, Services).
    *   `repositories/`: Abstract implementations.
    *   `services/`: API calls (Supabase, Aladin, FCM).
*   **`supabase/`**: Backend logic.
    *   `functions/`: Edge Functions for server-side logic (e.g., `send-smart-nudge`).
    *   `migrations/`: SQL migration files.

## 4. Key Development Conventions
*   **Pattern:** MVVM (Model-View-ViewModel).
    *   View consumes ViewModel via `Provider`.
    *   ViewModel handles business logic and calls Repositories.
    *   Repositories abstract data sources (Services).
*   **Styling:** Custom widgets in `ui/core/`.
*   **Database:** Supabase is the source of truth. Schema includes `books`, `users`, `fcm_tokens`.
*   **Async:** Heavy use of `Future` and `Stream` for data handling.

## 5. Build & Run Commands
*   **Run App:** `flutter run` (inside `app/` directory).
*   **Install Dependencies:** `flutter pub get` (inside `app/`).
*   **Supabase Local Dev:** `supabase start`, `supabase functions serve`.
*   **Deploy Functions:** `supabase functions deploy <function_name>`.

## 6. Operational Rules (System Prompts)
*   **Language:** **MUST** respond in **Korean (한글)** for all conversational text, explanations, and markdown content (except code).
*   **Commit Messages:** Use Conventional Commits in English (e.g., `feat: ...`), but the description body should be in Korean.
*   **PR Comments:** When creating PRs, format comments to match the team's template (if available).
*   **Planning:** All implementation plans must be written in Korean.

## 7. Current Focus (Context)
*   Recent work has been heavily focused on **FCM (Firebase Cloud Messaging)** integration for "Smart Nudges".
*   There are multiple markdown files (`FCM_*.md`) documenting this architecture.
*   The next steps involve UI improvements for the Book Detail screen and Calendar view.
