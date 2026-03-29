# Life Plan — Flutter App
### Abdelfattah M. Aboulfoutoh · 2026

Cross-platform life dashboard: Windows · iOS · Android · macOS

---

## 🚀 Quick Setup (5 steps)

### 1. Install dependencies
```bash
cd life_plan
flutter pub get
```

### 2. Add fonts
Download from Google Fonts and place in `assets/fonts/`:
- **Playfair Display**: Regular, Bold, Black → PlayfairDisplay-Regular.ttf, PlayfairDisplay-Bold.ttf, PlayfairDisplay-Black.ttf
- **IBM Plex Mono**: Regular, Medium, SemiBold → IBMPlexMono-Regular.ttf, IBMPlexMono-Medium.ttf, IBMPlexMono-SemiBold.ttf

Or use: https://fonts.google.com/specimen/Playfair+Display and https://fonts.google.com/specimen/IBM+Plex+Mono

### 3. Create Supabase project
1. Go to https://supabase.com → New Project
2. Go to SQL Editor → paste contents of `supabase/schema.sql` → Run
3. Go to Project Settings → API → copy **Project URL** and **anon key**
4. Paste into `lib/core/constants/app_constants.dart`:
```dart
static const supabaseUrl = 'https://xxxx.supabase.co';
static const supabaseAnonKey = 'eyJ...';
```

### 4. Run on Windows
```bash
flutter run -d windows
```

### 5. Run on mobile
```bash
flutter run -d android   # or ios
```

---

## 📁 Structure
```
lib/
├── main.dart               ← App entry point
├── core/
│   ├── theme/              ← Dark theme, colors, typography
│   ├── router/             ← GoRouter with auth guards
│   └── constants/          ← App constants, category info
├── services/
│   └── supabase_service.dart ← All DB operations
├── shared/
│   ├── models/             ← All data models
│   ├── widgets/            ← Reusable UI components
│   └── screens/            ← Shell navigation
└── features/
    ├── auth/               ← Login, signup, forgot password
    ├── overview/           ← Dashboard (Part 2)
    ├── schedule/           ← Daily schedule editor (Part 2)
    ├── calendar/           ← Calendar + events (Part 2)
    ├── finance/            ← Banks, debts, transactions (Part 2)
    ├── habits/             ← Habit tracker (Part 2)
    ├── goals/              ← Goal pool (Part 2)
    └── focus/              ← Pomodoro timer (Part 2)
```

---

## 🏗️ What's built (Part 1)
- ✅ Full project structure
- ✅ Dark theme (matches web app aesthetic exactly)
- ✅ GoRouter with auth guards
- ✅ Supabase auth (sign up, sign in, forgot password, sign out)
- ✅ All data models
- ✅ Full Supabase service layer
- ✅ Adaptive navigation (sidebar on desktop, bottom bar on mobile)
- ✅ All shared widgets (AppTextField, AppButton, AppCard, etc.)
- ✅ Database schema with RLS policies
- ✅ Default data seeding on sign-up
- ✅ Auth screens (Login, Signup, Forgot Password)

## 🔜 Part 2 will add
- Full Overview dashboard
- Schedule screen with drag-to-reorder blocks
- Calendar with event CRUD
- Finance dashboard (banks, debts, transactions)
- Habits tracker with streaks
- Goals pool
- Pomodoro focus timer with analytics

