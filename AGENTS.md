# AGENTS.md

Guidelines for AI coding agents working in the Bookgolas repository.

## Project Structure

- `app/` - Flutter mobile app (primary)
- `web/` - Next.js admin dashboard  
- `supabase/functions/` - Deno Edge Functions

## Build & Test Commands

### Flutter App (app/)
```bash
cd app && flutter pub get          # Setup
cd app && flutter run              # Run app
cd app && flutter test             # Run all tests
cd app && flutter test test/widget_test.dart  # Single test file
cd app && flutter test --name "description"   # Filter by name
cd app && flutter analyze          # Linting
cd app && flutter build ios        # Build iOS
cd app && flutter build apk        # Build Android
```

### Web Admin (web/)
```bash
cd web && npm install && npm run dev    # Development
cd web && npm run build                 # Production build
cd web && npm run lint                  # ESLint
```

### Supabase Functions
```bash
supabase functions deploy <name>   # Deploy
supabase functions serve <name>    # Local test
```

## Code Style - Dart/Flutter

### Import Order (group with blank lines)
1. Dart SDK (`dart:`)
2. Flutter (`package:flutter/`)
3. External packages (`package:provider/`)
4. Project imports (`package:book_golas/`)
5. Relative imports (`./`, `../`)

### Naming Conventions
- Classes: `PascalCase` (BookService, HomeViewModel)
- Files: `snake_case` (book_service.dart)
- Variables/Functions: `camelCase` (fetchBooks, _isLoading)
- Private members: prefix `_` (_books)

### File Structure
- Screens: `feature/feature_screen.dart`
- ViewModels: `feature/view_model/feature_view_model.dart`
- Widgets: `feature/widgets/` (subfolder only for 2+ related widgets)

### Error Handling
```dart
try {
  await someAsyncOperation();
} catch (e) {
  print('Failed: $e');
  return null;  // Return null/empty on failure, don't throw
}
```

### ViewModel Pattern
```dart
class FeatureViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // fetch data
    } finally {
      _isLoading = false;
      notifyListeners();  // ALWAYS call after state changes
    }
  }
}
```

### Model Classes
- Include `fromJson` factory and `toJson` method
- Use `copyWith` for immutable updates
- Nullable fields use `?` suffix

## Code Style - TypeScript/Deno

### Imports (URL-based)
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
```

### Interfaces & Error Responses
```typescript
interface RequestBody { userId?: string; title: string; }

return new Response(
  JSON.stringify({ error: "Message" }),
  { status: 400, headers: { "Content-Type": "application/json" } }
);
```

## Code Style - Next.js (web/)
- TypeScript strict mode
- Radix UI components from `src/components/ui/`
- Tailwind CSS for styling
- Server components default, `"use client"` only when needed

## Architecture

### Layer Structure
```
UI (lib/ui/) → ViewModel → Repository → Service
```

### Dependency Injection (main.dart MultiProvider)
1. Services (pure)
2. Repositories (depend on services)
3. ViewModels (depend on repositories)

### Database Access
- Client: `Supabase.instance.client`
- Always filter by `user_id`
- Pattern: `select().eq().order()`

## Git Workflow

### Branches
- `feature/BYU-XXX-description`
- `fix/BYU-XXX-description`  
- `daily/YYYY-MM-DD`

### Commits
English conventional commits: `feat:`, `fix:`, `refactor:`

## Critical Rules

1. **Remove comments before commit** - No comments in committed code
2. **Use debugPrint()** - Not print() in production
3. **Always notifyListeners()** - After ViewModel state changes
4. **Return null/empty on errors** - Don't throw from services
5. **Use const constructors** - For widgets where possible

## Environment Variables (app/.env)
- `ALADIN_TTB_KEY` - Book search API
- `SUPABASE_URL` - Supabase URL
- `SUPABASE_ANON_KEY` - Supabase key
- `ENVIRONMENT` - development/production

## Key Files
- `app/lib/main.dart` - Entry, providers
- `app/lib/config/app_config.dart` - Config
- `app/lib/data/services/` - API services
- `app/lib/data/repositories/` - Data layer
- `app/lib/ui/*/view_model/` - State management
