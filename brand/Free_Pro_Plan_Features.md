# PRP App — Free vs Pro Plan Feature Specification
*April 2026 · Living document*

---

## Design Philosophy

- **Free plan** must be genuinely useful — not crippled. It builds trust and converts through value, not frustration.
- **Pro plan** adds depth, history, customization, and automation — for the user who's committed to their life OS.
- Paywall triggers: deep analytics, unlimited records, AI features, multi-device priority sync, exports.

---

## Plan Summary

| | Free | Pro ($5.99/mo or $49/yr) |
|---|---|---|
| **Target** | New users, casual trackers | Power users, committed life-OS builders |
| **Pillars** | All 7 (with limits) | All 7 (unlimited) |
| **Data history** | 30 days most areas | Unlimited |
| **Devices** | Web only | Web + mobile (iOS/Android) |
| **Support** | Community | Priority email |

---

## Feature Breakdown by Pillar

### Overview

| Feature | Free | Pro |
|---|---|---|
| Resource Score dashboard | ✅ Full | ✅ Full |
| 7-day trend chart | ✅ | ✅ |
| Daily Check-in widget | ✅ | ✅ |
| 30-day arc gauge history | ❌ | ✅ |
| Weekly Review prompt on Sundays | ✅ (basic) | ✅ (full + stored history) |
| Correlation Insights (sleep vs habits, etc.) | ❌ | ✅ |
| Countdown timers | ❌ | ✅ |

### Time

| Feature | Free | Pro |
|---|---|---|
| Schedule blocks (create/edit) | ✅ Up to 20/week | ✅ Unlimited |
| Schedule modes (normal/focus/rest/off) | ✅ | ✅ |
| Calendar events | ✅ Up to 50 | ✅ Unlimited |
| Task manager | ✅ Up to 30 tasks | ✅ Unlimited |
| Recurring tasks | ❌ | ✅ |
| Time report (weekly hours by category) | ❌ | ✅ |
| Google Calendar sync | ❌ | ✅ |

### Finance

| Feature | Free | Pro |
|---|---|---|
| Bank accounts (track balances) | ✅ Up to 3 | ✅ Unlimited |
| Transactions | ✅ Last 30 days | ✅ Unlimited history |
| Investments | ✅ Up to 5 positions | ✅ Unlimited |
| Liabilities / Debts | ✅ Up to 3 | ✅ Unlimited |
| Spending by category donut | ✅ | ✅ |
| 6-month cashflow chart | ✅ | ✅ |
| Budget Planner (monthly limits) | ❌ | ✅ |
| Net Worth Timeline (12-month) | ❌ | ✅ |
| Debt Payoff Projections | ❌ | ✅ |
| CSV / PDF export | ❌ | ✅ |
| Bill & subscription tracker | ❌ | ✅ |
| Bank import (CSV upload) | ❌ | ✅ |

### Energy

| Feature | Free | Pro |
|---|---|---|
| Focus sessions (Pomodoro) | ✅ | ✅ |
| Focus history (last 30 days) | ✅ | ✅ Unlimited |
| Goals (create/track) | ✅ Up to 5 | ✅ Unlimited |
| Goal subtasks | ✅ | ✅ |
| Ideas manager | ✅ Up to 20 | ✅ Unlimited |
| Focus analytics (sessions/week trend) | ❌ | ✅ |
| Quick Capture FAB | ✅ | ✅ |

### Health

| Feature | Free | Pro |
|---|---|---|
| Habits (create/track) | ✅ Up to 7 | ✅ Unlimited |
| Habit streaks & heatmap | ✅ 30 days | ✅ Unlimited |
| Fasting tracker | ✅ | ✅ |
| Daily Check-in (energy/mood) | ✅ | ✅ |
| Sleep log | ✅ Last 30 days | ✅ Unlimited |
| Body metrics tracker (weight) | ❌ | ✅ |
| Habit completion trends | ❌ | ✅ |
| Apple Health / Google Fit sync | ❌ | ✅ |

### Deen (Religion — opt-in)

| Feature | Free | Pro |
|---|---|---|
| Salah tracker (5 prayers/day) | ✅ | ✅ |
| 30-day salah heatmap | ✅ | ✅ |
| Salah streak | ✅ | ✅ |
| Quran sessions log | ✅ Last 30 sessions | ✅ Unlimited |
| Quran daily page goal | ✅ | ✅ |
| Zakat calculator | ✅ | ✅ |
| Dhikr counter | ✅ | ✅ |
| Salah status detail (on-time/late/qada) | ❌ | ✅ |
| Deen Score (Overview integration) | ✅ | ✅ |
| Islamic calendar events | ❌ | ✅ |

### Profile & Settings

| Feature | Free | Pro |
|---|---|---|
| Avatar upload | ✅ | ✅ |
| Currency selection | ✅ | ✅ |
| Pillar toggle | ✅ | ✅ |
| Theme (dark only for now) | ✅ | ✅ Light/Dark/Custom |
| Export all data | ❌ | ✅ |
| Account deletion | ✅ | ✅ |

---

## Platform / Access

| Feature | Free | Pro |
|---|---|---|
| Web app (PWA) | ✅ | ✅ |
| iOS native app | ❌ | ✅ (when released) |
| Android native app | ❌ | ✅ (when released) |
| Offline mode | ❌ | ✅ (when released) |
| Push notifications | ✅ Basic | ✅ Custom schedules |

---

## AI Features (Future — V2+)

| Feature | Free | Pro |
|---|---|---|
| Weekly AI summary of performance | ❌ | ✅ |
| Smart goal suggestions | ❌ | ✅ |
| Spending pattern insights | ❌ | ✅ |
| AI journal prompts | ❌ | ✅ |

---

## What the Free Plan is Intentionally Good At

The Free plan should feel complete for someone just starting their life OS journey:
- Track their 5 daily prayers
- Log their 5–7 core habits
- See their spending for the month
- Run daily focus sessions
- Manage 5 goals
- Complete daily check-ins and weekly reviews

The Free plan converts when users hit limits (30 days of data gone, can't add the 6th habit, no budget planner) and feel invested enough to pay.

---

## Missing / Unstable Free Features (Current State — April 2026)

Features that should work on Free but currently don't, are broken, or haven't been built yet:

### P1 — Critical (blocks onboarding)
- [ ] **Onboarding flow** — new users land on empty app with no guidance (P1 task)
- [ ] **Empty states** — blank screens instead of helpful "Add your first X" prompts (every screen)
- [ ] **Error states** — network errors show nothing, no retry button

### P2 — High impact (core loops broken)
- [ ] **Daily Check-in** — not built yet; Overview has no energy/mood input (P3 task)
- [ ] **Weekly Review** — not built; Overview has no Sunday prompt (P2 task)
- [ ] **Quick Capture FAB** — not built; requires multiple taps to log anything (P4 task)

### P3 — Medium (pillar features incomplete)
- [ ] **Budget Planner UI** — table exists in task list but not built
- [ ] **Sleep Log** — not built; Health Overview has no sleep section
- [ ] **Quran page goal** — Deen P2 enhancement not built
- [ ] **Dhikr counter** — Deen P2 enhancement not built
- [ ] **Debt payoff projections** — Finance Liabilities screen shows debts but no projections

### P4 — Polish (rough edges)
- [ ] **Mobile layout** — several screens not optimized for < 400px width
- [ ] **Loading skeletons** — raw CircularProgressIndicator everywhere instead of shimmer
- [ ] **Transaction list pagination** — loads all records at once (will lag at scale)
- [ ] **Habit order** — no drag-to-reorder on Habits screen

---

## Execution Order (next sessions)

Priority is: make Free plan compelling before adding Pro-only features.

1. Onboarding flow (P1) — highest leverage for conversion
2. Empty states across all screens (P2) — second highest
3. Daily Check-in (P3) — core daily ritual
4. Quick Capture FAB (P4) — usability unlock
5. Sleep Log (medium effort, high value Health feature)
6. Budget Planner (Pro but close to done — locks in Pro conversions)
7. Weekly Review (P2 in task list — completes the weekly cycle)

---

*Document created: April 2026 | Update before Beta launch*
