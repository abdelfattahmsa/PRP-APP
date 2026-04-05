# PRP System — Architecture & Development Log

## Overview

PRP (Personal Resource Planner) is a Flutter app that manages life through four resource engines: **Money**, **Time**, **Energy**, and **Health**, orchestrated by a **Goals** system. Originally built as "Life Plan" (v1.0), it was restructured into an engine-based architecture in v2.0.

---

## Architecture Decisions

### 1. Engine-Based Modular Architecture

**Decision**: Replace flat feature-based folders with resource-engine modules.

**Rationale**: Each life resource (Money, Time, Energy, Health) has distinct data models, business logic, and UI patterns. Grouping by resource creates natural boundaries for:
- Independent development and testing
- Future offline-first capability per engine
- Cross-engine communication through a defined contract (resource scores)

**Structure**:
```
engines/
├── money/    → BankAccount, Debt, Investment, Transaction
├── time/     → ScheduleBlock, CalendarEvent
├── energy/   → FocusSession, FocusTimerState
├── health/   → Habit
└── goals/    → Goal (cross-engine orchestrator)
```

### 2. Repository Pattern

**Decision**: Insert a repository layer between providers and SupabaseService.

**Rationale**: Decouples state management from data source. Enables:
- Swapping Supabase for local DB (offline-first Phase 2)
- Mocking in tests
- Caching strategies per engine

**Current**: Repositories delegate directly to SupabaseService (thin wrapper).
**Future**: Add local cache (Hive/Drift) with sync queue.

### 3. Barrel File Re-exports

**Decision**: Keep old import paths working via barrel files that re-export from new locations.

**Rationale**: Allows incremental migration. Existing screens continue working without import changes. New code imports directly from engine files.

### 4. Cross-Engine Communication via Resource Scores

**Decision**: A single `resourceScoresProvider` in `core/providers/` watches all engines and computes 0-100 scores.

**Rationale**:
- No circular dependencies between engines
- Command Center dashboard gets a unified view
- Each engine remains independent
- Scores can feed future AI recommendations

### 5. State Management: Riverpod AsyncNotifier

**Decision**: Use Riverpod 3.x AsyncNotifier pattern for all data providers.

**Rationale**:
- Built-in loading/error states
- Automatic disposal and caching
- Family providers for parameterized queries (schedule modes)
- Computed providers for derived data (financeSummary, habitsTodayProvider)

---

## Provider Hierarchy

```
Layer 1 — Infrastructure
  └── SupabaseService (singleton, raw Supabase operations)

Layer 2 — Repositories
  └── MoneyRepository, TimeRepository, EnergyRepository, HealthRepository, GoalsRepository

Layer 3 — Engine Data Providers
  └── bankAccountsProvider, scheduleProvider, focusSessionsProvider, habitsProvider, goalsProvider, etc.

Layer 4 — Computed Providers
  └── financeSummaryProvider, habitsTodayProvider

Layer 5 — Cross-Engine Providers
  └── resourceScoresProvider (watches all engines, computes scores)

Layer 6 — UI Providers
  └── focusTimerProvider (ephemeral, not persisted)
```

---

## Data Flow

```
User Action → Screen Widget → Notifier method → Repository → SupabaseService → Supabase DB
                                                                                    ↓
UI Update  ← Provider rebuild ← State update  ← AsyncData  ←  Response  ←──────────┘
```

---

## Feature Log

### v2.0.0 — PRP System (2026-04-05)

#### Architecture
- [x] Engine-based folder structure (money, time, energy, health, goals)
- [x] Per-engine model files split from monolithic models.dart
- [x] Per-engine repository classes extracted from SupabaseService
- [x] Per-engine provider files split from monolithic all_providers.dart
- [x] Cross-engine resource scores provider
- [x] Barrel file re-exports for backward compatibility
- [x] Zero compilation errors after restructure

#### Branding
- [x] App renamed from "Life Plan" to "PRP System"
- [x] Package renamed from life_plan to prp_system
- [x] Version bumped to 2.0.0
- [x] Shell navigation logo LP → PRP
- [x] Settings screen logo LP → PRP
- [x] Main app class LifePlanApp → PRPApp

#### Command Center (Overview)
- [x] Resource Pulse widget with 4 engine scores
- [x] Overall score badge with color coding
- [x] Vertical pulse bars for Money, Time, Energy, Health

#### Existing Features (preserved)
- [x] Auth flow (login, signup, forgot password)
- [x] Schedule with 4 modes (normal, fasting, friday, cairo)
- [x] Calendar with event types
- [x] Finance (banks, debts, investments, transactions)
- [x] Focus timer with session logging
- [x] Habits tracker with streaks
- [x] Goals with progress tracking
- [x] Settings with preferences
- [x] Responsive navigation (desktop rail + mobile bottom nav)

### v1.0.0 — Life Plan (2026-03-01)
- Initial release with all features in flat feature-based structure

---

## Database Schema (Supabase)

| Table | Engine | Key Columns |
|-------|--------|-------------|
| profiles | Core | id, email, full_name, avatar_url, cash_on_hand |
| schedule_blocks | Time | id, user_id, schedule_mode, time, label, category_key, duration, order |
| calendar_events | Time | id, user_id, date, title, type_key, notes, is_done |
| bank_accounts | Money | id, user_id, name, cc_balance, cc_limit, savings_balance, current_balance |
| debts | Money | id, user_id, source, amount, due_date, is_paid |
| investments | Money | id, user_id, type, amount, unit |
| transactions | Money | id, user_id, date, description, amount, category, account_name, is_income |
| habits | Health | id, user_id, name, icon, streak, longest_streak, history (JSONB) |
| goals | Goals | id, user_id, title, target_date, priority, status, progress, milestones |
| focus_sessions | Energy | id, user_id, date, block_label, planned_seconds, actual_seconds, completed |

All tables use RLS (Row Level Security) with `user_id = auth.uid()` policies.

---

## Design System

### Colors
| Token | Hex | Usage |
|-------|-----|-------|
| bg | #08070C | App background |
| surface | #0D0B13 | Navigation, elevated surfaces |
| card | #12101E | Card backgrounds |
| gold | #C8A050 | Primary accent, brand |
| goldDim | #5A4418 | Muted gold, secondary accent |
| textPrimary | #E0DAF0 | Main text |
| textSecondary | #7A7090 | Supporting text |
| textMuted | #3A3450 | Disabled/subtle text |

### Category Colors
| Category | Color | Engine |
|----------|-------|--------|
| Deen | #54C478 | Time |
| PMP | #6A8EF0 | Time |
| CFI/Study | #4AAAE0 | Time |
| Health | #D07848 | Health |
| Kyberia | #AA70EE | Time |
| Work | #C09840 | Time |
| Fasting | #E08840 | Time |
| Commute | #3AB8A8 | Time |
| Rest | #6B6080 | Time |

### Typography
- **PlayfairDisplay**: display, headline, title (large) — editorial feel
- **IBMPlexMono**: title (medium/small), body, label — data density

### Spacing (4px grid)
- xs: 4, sm: 8, md: 12, base: 16, lg: 20, xl: 28, xxl: 40

---

## Future Roadmap

### Phase 2 — Offline-First
- [ ] Add local cache layer (Hive or Drift) in repositories
- [ ] Implement sync queue for offline changes
- [ ] Conflict resolution strategy

### Phase 3 — Enhanced Finance OS
- [ ] Multi-currency support with exchange rates
- [ ] Recurring transaction rules
- [ ] Savings goals with progress tracking
- [ ] Financial analytics (spend patterns, cash flow projections)

### Phase 4 — Energy Management
- [ ] Post-session energy rating (1-5)
- [ ] Peak performance time detection
- [ ] Energy pattern heatmap
- [ ] Distraction counter

### Phase 5 — Customization System
- [ ] User preferences model (dashboard layout, nav order)
- [ ] Custom categories
- [ ] Custom schedule modes
- [ ] Module visibility toggles

### Phase 6 — AI Integration
- [ ] Smart scheduling suggestions
- [ ] Spending pattern analysis
- [ ] Energy optimization recommendations
- [ ] Goal progress predictions
