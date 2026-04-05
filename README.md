# PRP System — Personal Resource Planner

A cross-platform life management app built with Flutter. PRP organizes your life around four core resources: **Money**, **Time**, **Energy**, and **Health**, unified by a **Goals** orchestrator.

## Architecture

```
lib/
├── core/                    # App-wide infrastructure
│   ├── constants/           # AppConstants, categories, event types
│   ├── providers/           # Cross-engine providers (resource scores)
│   ├── router/              # GoRouter with auth guards
│   └── theme/               # Design system (dark + gold)
│
├── engines/                 # Resource-based engine modules
│   ├── money/               # Finance OS — accounts, debts, transactions
│   │   ├── data/models/     # BankAccount, ExternalDebt, Investment, Transaction
│   │   ├── data/repositories/ # MoneyRepository
│   │   ├── providers/       # Riverpod providers + computed summary
│   │   ├── screens/         # (Finance screen in features/ for now)
│   │   └── widgets/
│   ├── time/                # Schedule + Calendar
│   │   ├── data/models/     # ScheduleBlock, CalendarEvent
│   │   ├── data/repositories/ # TimeRepository
│   │   ├── providers/       # Schedule, Calendar notifiers
│   │   ├── screens/
│   │   └── widgets/
│   ├── energy/              # Focus sessions + timer
│   │   ├── data/models/     # FocusSession, FocusTimerState
│   │   ├── data/repositories/ # EnergyRepository
│   │   ├── providers/       # Sessions notifier, timer notifier
│   │   ├── screens/
│   │   └── widgets/
│   ├── health/              # Habits tracking
│   │   ├── data/models/     # Habit
│   │   ├── data/repositories/ # HealthRepository
│   │   ├── providers/       # Habits notifier, today's completion
│   │   ├── screens/
│   │   └── widgets/
│   └── goals/               # Goals orchestrator
│       ├── data/models/     # Goal
│       ├── data/repositories/ # GoalsRepository
│       ├── providers/       # Goals notifier
│       ├── screens/
│       └── widgets/
│
├── features/                # UI screens (being migrated to engines/)
│   ├── auth/                # Login, signup, forgot password
│   ├── overview/            # Command Center dashboard
│   ├── schedule/            # Schedule + edit block
│   ├── calendar/            # Calendar + event detail
│   ├── finance/             # Finance OS screen
│   ├── focus/               # Focus timer + log + analytics
│   ├── habits/              # Habit tracker
│   ├── goals/               # Goals screen
│   └── settings/            # App settings
│
├── services/                # External services
│   ├── supabase_service.dart # All Supabase operations
│   └── notification_service.dart
│
├── shared/                  # Cross-cutting concerns
│   ├── models/              # Barrel re-exports for backward compat
│   ├── screens/             # ShellScreen (responsive nav)
│   └── widgets/             # Shared UI components
│
└── main.dart                # App entry point
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter ≥3.19.0, Dart ≥3.3.0 |
| State | Riverpod 3.x (AsyncNotifier pattern) |
| Navigation | GoRouter 17.x with auth guards |
| Backend | Supabase (Auth + Postgres + RLS) |
| UI | Material 3, dark theme, PlayfairDisplay + IBMPlexMono |
| Charts | fl_chart |
| Calendar | table_calendar |
| Animations | flutter_animate |

## Design System

- **Background**: `#08070C` (near-black)
- **Surface**: `#0D0B13`
- **Card**: `#12101E`
- **Gold accent**: `#C8A050`
- **Spacing**: 4px grid system
- **Typography**: PlayfairDisplay (headings), IBMPlexMono (data/labels)
- **Breakpoints**: Mobile (<480), Tablet (480-768), Desktop (768-1200)

## Features

### Command Center (Overview)
- Resource Pulse — live 0-100 scores for Money, Time, Energy, Health
- Current schedule block with NOW indicator
- Stats grid (habits, focus, goals, finance)
- Upcoming events + active goals
- Milestone timeline

### Money Engine (Finance)
- Multi-bank account management (current, savings, credit card)
- External debt tracking
- Investment portfolio
- Transaction ledger with category filters
- Financial summary with computed metrics

### Time Engine (Schedule + Calendar)
- Multiple schedule modes (normal, fasting, friday, cairo)
- Drag-to-reorder blocks with notifications
- Full calendar with event types (personal, milestone, islamic, etc.)
- Event detail with links and attachments

### Energy Engine (Focus)
- Pomodoro-style timer (focus/break modes)
- Session logging with category tracking
- 7-day analytics with bar charts
- Time-by-category breakdown

### Health Engine (Habits)
- Daily habit tracker with streak counting
- History tracking (per-day toggle)
- Completion percentage dashboard

### Goals
- Goal tracking with progress bars
- Priority levels (high/medium/low)
- Status management (active/done/paused)
- Target date with days-remaining countdown
- Linked calendar events

## Getting Started

### Prerequisites
- Flutter SDK ≥3.19.0
- A Supabase project (URL + anon key configured in `app_constants.dart`)

### Run locally
```bash
flutter pub get
flutter run
```

### Build for release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## Deployment Guide

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed platform-specific deployment instructions and publishing costs.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | 2026-04-05 | PRP System restructure — engine-based architecture, resource scores, Command Center |
| 1.0.0 | 2026-03-01 | Initial Life Plan release |
