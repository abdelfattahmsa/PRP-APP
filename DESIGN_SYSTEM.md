# Life Plan — Design System & Brand Guidelines
## Version 2.0 — UI/UX Overhaul

---

## 1. BRAND IDENTITY

### App Name
**Life Plan** — Clean, aspirational, professional. No abbreviation needed.

### Tagline
*"Design your day. Own your year."*

### Logo
The **Diamond Mark** — a layered geometric diamond representing:
- **Clarity** (transparent overlapping facets)
- **Value** (diamond = precious asset, like time)
- **Structure** (geometric precision = planned life)

Three concentric diamonds in gold gradient, rendered as `DiamondLogo` custom painter.

### Brand Voice
- **Professional** but approachable
- **Data-rich** but not overwhelming
- **Personal** — this is YOUR plan, not a generic tool
- **Confident** — no hedging language ("Track" not "Try to track")

---

## 2. COLOR SYSTEM

### Core Palette
| Token            | Hex       | Usage                              |
|------------------|-----------|------------------------------------|
| `bg`             | `#08070C` | App background                     |
| `surface`        | `#0D0B13` | Navigation, app bars, inputs       |
| `card`           | `#12101E` | Cards, tiles, containers           |
| `cardHover`      | `#171526` | Card hover/pressed state           |
| `border`         | `#1E1B2C` | Borders, dividers                  |
| `borderLight`    | `#2A2640` | Active borders, focus rings        |

### Brand Colors
| Token            | Hex       | Usage                              |
|------------------|-----------|------------------------------------|
| `gold`           | `#C8A050` | Primary actions, active nav, CTAs  |
| `goldLight`      | `#E8C97A` | Hover states, highlights           |
| `goldDim`        | `#5A4418` | Subtle backgrounds, badges         |
| `goldFaint`      | `#2A2010` | Ultra-subtle card tints            |

### Category Colors (Schedule & Habits)
| Category   | Hex       | Emoji |
|------------|-----------|-------|
| Deen       | `#54C478` | mosque |
| PMP        | `#6A8EF0` | clipboard |
| Study/CFI  | `#4AAAE0` | books |
| Health     | `#D07848` | activity |
| Kyberia    | `#AA70EE` | flask |
| Work       | `#C09840` | construction |
| Fasting    | `#E08840` | moon |
| Commute    | `#3AB8A8` | car |
| Rest       | `#6B6080` | sleep |

### Semantic Colors
| Token     | Hex       | Usage              |
|-----------|-----------|--------------------|
| `success` | `#54C478` | Positive feedback  |
| `error`   | `#E05050` | Errors, delete     |
| `warning` | `#E08840` | Warnings, alerts   |
| `info`    | `#6A8EF0` | Info, hints        |

### Text Colors
| Token          | Hex       | Usage                    |
|----------------|-----------|--------------------------|
| `textPrimary`  | `#E0DAF0` | Headings, primary text   |
| `textSecondary`| `#7A7090` | Labels, captions         |
| `textMuted`    | `#3A3450` | Placeholder, disabled    |
| `textOnGold`   | `#08070C` | Text on gold buttons     |

---

## 3. TYPOGRAPHY

### Font Stack
- **Display/Headings:** Playfair Display (700, 900)
- **UI/Body:** IBM Plex Mono (400, 500, 600)

### Type Scale
| Style          | Font             | Size | Weight | Tracking | Usage                    |
|----------------|------------------|------|--------|----------|--------------------------|
| `displayLarge` | Playfair Display | 40px | 900    | -1.0     | Hero numbers             |
| `headlineLarge`| Playfair Display | 24px | 700    |          | Page titles              |
| `headlineMed`  | Playfair Display | 20px | 700    |          | Section titles           |
| `titleLarge`   | Playfair Display | 16px | 700    |          | Card titles              |
| `titleMedium`  | IBM Plex Mono    | 13px | 600    |          | Subtitles, stat labels   |
| `titleSmall`   | IBM Plex Mono    | 11px | 600    | 0.5      | Section labels, tags     |
| `bodyLarge`    | IBM Plex Mono    | 14px | 400    |          | Primary body text        |
| `bodyMedium`   | IBM Plex Mono    | 12px | 400    |          | Secondary body text      |
| `bodySmall`    | IBM Plex Mono    | 11px | 400    |          | Captions, timestamps     |
| `labelLarge`   | IBM Plex Mono    | 12px | 600    | 0.5      | Buttons                  |
| `labelMedium`  | IBM Plex Mono    | 10px | 500    | 0.8      | Nav labels, tags         |
| `labelSmall`   | IBM Plex Mono    | 9px  | 400    | 1.5      | Overlines, section heads |

---

## 4. SPACING SYSTEM

### Base Unit: 4px
| Token  | Value | Usage                        |
|--------|-------|------------------------------|
| `xs`   | 4px   | Inline icon gaps             |
| `sm`   | 8px   | Between related elements     |
| `md`   | 12px  | Card internal padding        |
| `base` | 16px  | Page horizontal padding      |
| `lg`   | 20px  | Between sections             |
| `xl`   | 28px  | Major section separation     |
| `xxl`  | 40px  | Page top/bottom              |

### Page Layout
- **Mobile padding:** 16px horizontal
- **Desktop padding:** 24px horizontal
- **Max content width:** 1200px (centered on ultra-wide)
- **Card gap:** 8px between cards in a list
- **Section gap:** 20px between major sections

---

## 5. RESPONSIVE BREAKPOINTS

| Breakpoint | Name     | Layout                            |
|------------|----------|-----------------------------------|
| < 480px    | Mobile   | Bottom nav (5 items + More)       |
| 480-768px  | Tablet   | Bottom nav, 2-col grids           |
| 768-1200px | Desktop  | Side rail (collapsed 60px)        |
| > 1200px   | Wide     | Side rail (expanded 200px)        |

### Navigation Strategy
- **Mobile (< 768px):** Bottom navigation bar with 5 primary tabs + "More" overflow
  - Primary: Overview, Schedule, Calendar, Finance, More
  - More menu: Habits, Goals, Focus, Settings
- **Desktop (>= 768px):** Left navigation rail
  - Collapsed (icons only) at 768-1200px
  - Expanded (icons + labels) at 1200px+
  - Collapsible via toggle button

---

## 6. COMPONENT LIBRARY

### Cards
- **Standard Card:** `AppColors.card` bg, 1px border, 12px radius
- **Interactive Card:** Add `InkWell` + hover state (`cardHover` bg)
- **Accent Card:** Left 3px accent border in category color
- **Stat Card:** Compact, icon + label + value, optional trend indicator

### Buttons
- **Primary:** Gold bg, dark text, 8px radius, 600 weight
- **Secondary:** Transparent bg, gold border, gold text
- **Danger:** error bg at 10% opacity, error text
- **Ghost:** No bg/border, textSecondary color, hover reveals bg

### Inputs
- **Text Field:** surface bg, border on focus (gold), 8px radius
- **Dropdown:** Same styling as text field
- **Toggle/Switch:** Gold thumb when active
- **Chip Selector:** Wrap of selectable chips with category colors

### Status Badges
- **Active:** Green dot + "Active" text
- **Done:** Checkmark + strikethrough text
- **Overdue:** Red dot + "Overdue" text
- **Paused:** Gray dot + "Paused" text

### Empty States
- Centered icon (48px, muted color)
- Title text (bodyMedium, textSecondary)
- Optional action button (outlined)

### Loading States
- Skeleton shimmer for cards (not CircularProgressIndicator)
- Inline loading for buttons (replace text with small spinner)

---

## 7. INTERACTION PATTERNS

### Create/Edit
- **Mobile:** Full-screen bottom sheet sliding up
- **Desktop:** Side panel or dialog (max 480px wide)
- Never inline toggle — always dedicated form surface

### Delete
- Swipe-to-dismiss with red bg + trash icon
- Confirmation dialog for destructive actions
- Undo snackbar (3s timeout) for quick recovery

### Navigation
- Tap nav item → instant transition (no page animation)
- Sub-routes → slide-in from right
- Modals → fade + slide up

### Feedback
- Success: Green snackbar (bottom, 3s)
- Error: Red snackbar (bottom, 5s) with retry action
- Loading: Inline spinner replacing the action button

---

## 8. SCREEN HIERARCHY

### Information Architecture
```
Life Plan
├── Overview (Dashboard — "today at a glance")
│   ├── Current schedule block
│   ├── Today's habits progress
│   ├── Upcoming events
│   ├── Quick financial summary
│   └── Active goals progress
├── Schedule (Daily time blocks)
│   ├── Mode tabs (Normal/Fasting/Friday/Cairo)
│   ├── Timeline view with current indicator
│   └── Add/Edit block (sheet)
├── Calendar (Events & milestones)
│   ├── Month calendar with dot indicators
│   ├── Day event list
│   └── Add/Edit event (sheet)
├── Finance (Money management)
│   ├── Overview tab (totals, debt progress)
│   ├── Accounts tab (bank list)
│   ├── Debts tab (debt list)
│   └── Transactions tab (log + add)
├── Habits (Daily tracking)
│   ├── Today's progress bar
│   ├── Habit list with toggle
│   └── Add habit (sheet)
├── Goals (Long-term targets)
│   ├── Stats summary
│   ├── Goal cards with progress
│   └── Add/Edit goal (sheet)
├── Focus (Pomodoro timer)
│   ├── Timer tab
│   ├── Session log
│   └── Analytics
└── Settings
    ├── Profile
    ├── Schedule preferences
    └── Sign out
```

---

## 9. CUSTOMIZATION SYSTEM

### User-Configurable
- **Categories:** Add/edit/reorder/color custom categories
- **Schedule Modes:** Create custom modes beyond the 4 defaults
- **Event Types:** Add custom event types with color + emoji
- **Transaction Categories:** Add/edit spending categories
- **Investment Types:** User-defined investment categories

### Stored in Supabase
- Custom categories → `user_categories` table
- Custom modes → `user_schedule_modes` table
- Preferences → `profiles` table JSON column

### Stored Locally (SharedPreferences)
- Active schedule mode
- Alarms enabled/disabled
- Theme preference (future)
- Compact/comfortable density (future)

---

## 10. ACCESSIBILITY

### Minimum Requirements
- All interactive elements: 44x44px minimum tap target
- All icons: semantic labels
- All images: alt text
- Color contrast: WCAG AA (4.5:1 for text, 3:1 for UI)
- Focus indicators: 2px gold outline on keyboard focus
- Screen reader: proper widget semantics

---

## 11. IMPLEMENTATION PRIORITY

### Phase 1 (This Sprint) — Core Overhaul
1. Updated color system + spacing constants
2. Responsive navigation shell (mobile-first)
3. Overview dashboard redesign
4. Shared component extraction (cards, badges, empty states)
5. withOpacity → withValues migration (DONE)
6. Settings screen (DONE)

### Phase 2 — Screen Refinements
1. Schedule screen timeline UX
2. Calendar screen interactions
3. Finance tabs cleanup
4. Habits/Goals consistency pass

### Phase 3 — Polish & Customization
1. Custom category management UI
2. Skeleton loading states
3. Animation pass (consistent timings)
4. Accessibility audit pass
