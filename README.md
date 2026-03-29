# Life Plan 🚀

<div align="center">
  <p>A comprehensive, cross-platform life dashboard built with Flutter & Supabase.</p>
  <p>
    <b>Windows • macOS • iOS • Android</b>
  </p>
</div>

---

## 📖 Overview

**Life Plan** is a meticulously crafted cross-platform application designed to serve as your ultimate life dashboard. Developed by Abdelfattah M. Aboulfoutoh in 2026, it seamlessly integrates schedule management, financial tracking, habit formation, goal setting, and focused work sessions into a single, unified interface wrapped in an elegant dark theme.

## ✨ Features

### Phase 1: Core Foundation (✅ Completed)
- **Robust Authentication**: Full Supabase authentication flow (Sign Up, Sign In, Forgot Password, Sign Out).
- **Adaptive Navigation**: Intelligent routing via `go_router` featuring auth guards, a desktop sidebar, and a mobile bottom navigation bar.
- **Premium UI/UX**: Exclusively designed dark theme with typography powered by *Playfair Display* and *IBM Plex Mono*, enriched with custom shared widgets (`AppTextField`, `AppButton`, `AppCard`).
- **Data Architecture**: Comprehensive data modeling, full Supabase service layer, custom database schema with Row Level Security (RLS) policies, and default automated data seeding on new sign-ups.

### Phase 2: Feature Modules (🔜 Upcoming)
- 📊 **Overview Dashboard**: High-level insights at a glance.
- ⏱️ **Schedule**: Daily planner with intuitive drag-to-reorder time blocks.
- 📅 **Calendar**: Advanced event and appointment management.
- 💰 **Finance**: Complete financial oversight including banks, debts, and transactions.
- 📈 **Habits**: Comprehensive habit tracking with streak maintenance.
- 🎯 **Goals**: A structured goal and milestone pool.
- 🍅 **Focus**: Built-in Pomodoro timer integrated with session analytics.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (>=3.19.0)
- **Backend & Auth**: [Supabase](https://supabase.com/)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage**: [Hive](https://docs.hivedb.dev/) & [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Key UI/UX Libraries**: `fl_chart`, `table_calendar`, `flutter_animate`

---

## 🚀 Quick Setup Guide

Follow these 5 simple steps to get the project running locally:

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Typography
This app uses custom typography. Download the following fonts from Google Fonts and place them in the `assets/fonts/` directory:
- [Playfair Display](https://fonts.google.com/specimen/Playfair+Display) (`PlayfairDisplay-Regular.ttf`, `PlayfairDisplay-Bold.ttf`, `PlayfairDisplay-Black.ttf`)
- [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono) (`IBMPlexMono-Regular.ttf`, `IBMPlexMono-Medium.ttf`, `IBMPlexMono-SemiBold.ttf`)

### 3. Setup Supabase Backend
1. Create a new project at [Supabase](https://supabase.com/).
2. Navigate to the **SQL Editor**, paste the contents of `supabase/schema.sql`, and hit **Run** to generate your tables and RLS policies.
3. Navigate to **Project Settings > API** and copy your **Project URL** and **anon public key**.
4. Inside your local project, open `lib/core/constants/app_constants.dart` and update the constants:
```dart
static const supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const supabaseAnonKey = 'eyJ...';
```

### 4. Run Locally (Desktop)
```bash
flutter run -d windows
# or macOS: flutter run -d macos
```

### 5. Run Locally (Mobile)
```bash
flutter run -d android
# or iOS: flutter run -d ios
```

---

## 📁 Project Architecture

The codebase follows a feature-centric, highly modular architecture to ensure scalability:

```text
lib/
├── main.dart                 # Application entry point
├── core/                     # Foundational configurations
│   ├── theme/                # Dark theme definition, colors, and typography 
│   ├── router/               # GoRouter configuration and auth guards
│   └── constants/            # Application-wide constants 
├── services/
│   └── supabase_service.dart # Centralized backend and DB operations
├── shared/                   # Cross-feature reusables
│   ├── models/               # Universal data models
│   ├── widgets/              # Reusable UI components (buttons, text fields, cards)
│   └── screens/              # Shell navigation structural screens
└── features/                 # Modular feature domains
    ├── auth/                 # Authentication workflows
    ├── overview/             # Central dashboard (Part 2) 
    ├── schedule/             # Daily schedule editor (Part 2)
    ├── calendar/             # Calendar and event integration (Part 2)
    ├── finance/              # Wealth tracking (Part 2)
    ├── habits/               # Habit monitoring (Part 2)
    ├── goals/                # Goal tracking (Part 2)
    └── focus/                # Pomodoro timer (Part 2)
```

---

<div align="center">
  <p>© 2026 Abdelfattah M. Aboulfoutoh</p>
</div>
