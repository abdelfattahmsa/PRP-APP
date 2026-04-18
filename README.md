# PRP System — Personal Resource Planner

A cross-platform life management app built with Flutter. PRP organizes life around four core resources: **Money**, **Time**, **Energy**, and **Health** — with a unified **Overview** dashboard and **Profile** hub.

> **Live demo:** [prp-app.vercel.app](https://prp-app.vercel.app)

---

## V3.0.0 — What's new

- 6-tab navigation with full sub-tab hierarchy (21 routes total)
- Responsive shell: collapsible desktop sidebar + mobile bottom nav with scrollable sub-tab bar
- Dark / Light / System theme with green accent (`#22C55E`), persisted across sessions
- Complete placeholder screens for all tabs — ready for real data wiring
- Shared widget library: `StatCard`, `PlaceholderChart` (custom bezier painter), `PlaceholderList`, `SectionCard`, `SettingsTile`

---

## Tab & Route Map

| Tab | Sub-tabs | Routes |
|-----|----------|--------|
| Overview | Dashboard | `/overview` |
| Time | Overview · Schedule · Calendar | `/time/overview` `/time/schedule` `/time/calendar` |
| Finance | Overview · Accounts · Investments · Liabilities · Transactions | `/finance/overview` `/finance/accounts` `/finance/investments` `/finance/liabilities` `/finance/transactions` |
| Energy | Overview · Focus · Goals | `/energy/overview` `/energy/focus` `/energy/goals` |
| Health | Overview · Daily Progress · Fasting · Habits | `/health/overview` `/health/daily-progress` `/health/fasting` `/health/habits` |
| Profile | Profile · Account · App Settings | `/profile/settings` `/profile/account` `/profile/app` |

---

## Architecture

```
lib/
├── core/
│   ├── constants/           # AppConstants, categories
│   ├── providers/           # ThemeModeProvider, cross-app providers
│   ├── router/              # GoRouter — Routes class + auth guards
│   └── theme/               # AppTheme (dark + light), AppColors, Spacing
│
├── features/
│   ├── auth/                # Login, signup, forgot password
│   ├── overview/            # Dashboard
│   ├── time/                # Time overview
│   ├── schedule/            # Schedule + EditBlock
│   ├── calendar/            # Calendar + EventDetail
│   ├── finance/             # 5 finance screens
│   ├── energy/              # Energy overview, Focus, Goals
│   ├── health/              # 4 health screens
│   └── profile/             # 3 profile/settings screens
│
├── shared/
│   ├── screens/             # ShellScreen (desktop sidebar + mobile nav)
│   └── widgets/             # placeholders.dart — shared UI components
│
└── main.dart
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter ≥3.19.0, Dart ≥3.3.0 |
| State | Riverpod 3.x (`Notifier` / `AsyncNotifier` pattern) |
| Navigation | GoRouter 17.x — `ShellRoute` with auth redirect |
| Backend | Supabase (Auth + Postgres + RLS) |
| UI | Material 3, PlayfairDisplay + IBMPlexMono |
| Charts | Custom `CustomPainter` (bezier curves, gradient fill) |
| Calendar | table_calendar |
| Animations | flutter_animate |

---

## Design System

| Token | Value |
|-------|-------|
| Background (dark) | `#08070C` |
| Surface (dark) | `#0D0B13` |
| Card (dark) | `#12101E` |
| Green accent | `#22C55E` |
| Background (light) | `#F8F7FC` |
| Card (light) | `#FFFFFF` |
| Heading font | PlayfairDisplay |
| Data/label font | IBMPlexMono |
| Base spacing unit | 16px (4px grid) |
| Breakpoints | Mobile <768px · Desktop ≥768px |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥3.19.0
- Supabase project (URL + anon key in `lib/core/constants/app_constants.dart`)

### Run locally
```bash
flutter pub get
flutter run
```

### Build for web
```bash
flutter build web --release
```
Output: `build/web/`

---

## Deployment

### Vercel (automated via GitHub Actions)

Every push to `main` automatically builds Flutter web and deploys to Vercel.

**One-time setup:**
1. Create a Vercel project linked to this repo (or import it at [vercel.com/new](https://vercel.com/new))
2. Add these secrets to your GitHub repo (`Settings → Secrets and variables → Actions`):
   - `VERCEL_TOKEN` — from [vercel.com/account/tokens](https://vercel.com/account/tokens)
   - `VERCEL_ORG_ID` — from `.vercel/project.json` after running `vercel link` locally
   - `VERCEL_PROJECT_ID` — same file

3. Push to `main` — the workflow handles the rest.

### Manual deploy
```bash
flutter build web --release
cd build/web
npx vercel --prod
```

### Other platforms
See [DEPLOYMENT.md](DEPLOYMENT.md) for Android, iOS, Windows, macOS build and publishing instructions.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 3.0.0 | 2026-04-18 | 6-tab V3 architecture — responsive shell, light/dark/system theme, 21 routes, placeholder screens, Vercel CI/CD |
| 2.0.0 | 2026-04-05 | PRP System restructure — engine-based architecture, resource scores, Command Center |
| 1.0.0 | 2026-03-01 | Initial Life Plan release |
