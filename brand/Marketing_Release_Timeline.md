# PRP App — Staged Marketing & Release Timeline
*April 2026 · Living document — update each phase*

---

## Overview

```
Phase 0  ──── Phase 1  ──── Phase 2  ──── Phase 3  ──── Phase 4
Foundation    Alpha         Beta          Launch        Growth
Apr 2026      May–Jun       Jul–Aug       Sep           Oct+
(now)         2026          2026          2026          2026
```

---

## Phase 0 — Foundation (NOW — April 2026)

**Goal:** Get the product solid before any external exposure.

### Product
- [x] Core pillars built (Time, Finance, Energy, Health, Deen)
- [x] Auth, RLS, Supabase schema running
- [x] Web deployed at `web.prp-app.website`
- [ ] Onboarding flow (P1 in task list)
- [ ] Weekly Review screen (P2)
- [ ] Daily Check-in (P3)
- [ ] Quick Capture FAB (P4)
- [ ] Empty states on all screens
- [ ] Error/loading states consistent
- [ ] Mobile-responsive layout audit

### Brand
- [x] Brand kit created (`brand/PRP_Brand_Kit.md`)
- [x] Logo variants in `brand/logos/`
- [ ] App icon finalized (square, works at 16px and 1024px)
- [ ] Decide on public-facing name (PRP vs rename — see `Monk_App_Name_Analysis.md`)
- [ ] Landing page copy drafted

### Infrastructure
- [ ] GitHub Actions CI/CD (M4 — Vercel secrets)
- [ ] Error monitoring (Sentry free tier)
- [ ] Analytics baseline (Vercel Analytics or Mixpanel free)

---

## Phase 1 — Alpha (May–June 2026)

**Goal:** 10–25 hand-picked testers. Validate core loops. No public promotion.

### Target users
- Personal network: friends, family, colleagues
- Communities you're part of: productivity enthusiasts, Muslim professionals, finance-focused students
- Persona: 22–35, ambitious, already uses productivity tools (Notion, Todoist, etc.)

### How to recruit
- Direct DM / WhatsApp to 10–15 people you trust to give honest feedback
- Google Form waitlist embedded on landing page (collect emails silently)
- No social media posts yet — stealth phase

### Product milestones for Phase 1 exit
- [ ] Onboarding complete and tested
- [ ] All 7 pillars accessible and functional
- [ ] 0 crash-on-launch bugs reported
- [ ] Core loop tested: user opens app daily for 7 days

### Marketing actions
- [ ] Set up landing page on `prp-app.website` (simple: hero + waitlist CTA)
- [ ] Create private Discord/WhatsApp group for alpha testers
- [ ] Weekly feedback sessions (15 min calls or async surveys)
- [ ] Set up a Notion/Airtable feedback tracker

### Metrics to track
| Metric | Alpha target |
|---|---|
| Active testers | 10–25 |
| D7 retention | > 40% |
| Crash-free sessions | > 95% |
| NPS (informal) | Positive |

---

## Phase 2 — Beta (July–August 2026)

**Goal:** 50–200 users. Public waitlist open. Polish and Pro plan foundations.

### How to recruit
- **Twitter/X**: Start posting content — "Building in public" thread (1 post/week about features)
- **Reddit**: r/productivity, r/MuslimProductivity, r/personalfinance, r/getmotivated — share as community member, not spammer
- **YouTube Shorts / TikTok**: 60-second screen recordings of a feature per week
- **ProductHunt "upcoming" listing**: Register for a future PH launch
- **Indie hackers post**: Write a "building my personal life OS" story
- **Email list**: Start collecting on landing page — goal: 200 subscribers by end of Beta

### Product milestones for Phase 2 exit
- [ ] Pro plan backend (Stripe integration or manual upgrade for now)
- [ ] Budget Planner (P5) live
- [ ] Net Worth Timeline (P6) live
- [ ] Sleep Log (P7) live
- [ ] Mobile app (PWA or wrapped in Capacitor) for iOS/Android testing
- [ ] Performance: < 2s initial load on mobile
- [ ] Accessibility: keyboard-navigable, proper ARIA labels

### Marketing actions
- [ ] Landing page v2: social proof section (alpha tester quotes), feature screenshots
- [ ] Twitter/X: 50 tweets/posts — mix of feature demos, behind-the-scenes, productivity tips
- [ ] 3 blog posts (SEO): "How I track all my resources in one app", "Salah tracker app for Muslims", "Budget + habit tracker combined"
- [ ] Newsletter: bi-weekly "PRP Notes" to email list

### Metrics to track
| Metric | Beta target |
|---|---|
| Total signups | 50–200 |
| D30 retention | > 25% |
| Email list | > 200 |
| Social followers (combined) | > 500 |

---

## Phase 3 — Public Launch (September 2026)

**Goal:** Visible public launch. 1,000+ signups. Pro plan live.

### Launch channels (in order of priority)
1. **ProductHunt** — Schedule a Monday launch. Goal: top 5 of the day.
   - Prepare: 10 upvote hunters, quality GIF demo, tight tagline, first comment ready
2. **Hacker News "Show HN"** — Same week as PH, different day
3. **Indie Hackers** — "Launched!" post with revenue milestone goal
4. **Twitter/X announcement** — Thread: "1 year of building → here's PRP" with demo video
5. **LinkedIn** — Longer post for professional audience
6. **Reddit** — Announce in relevant subreddits (not just self-promote — be a genuine community member first)
7. **Muslim tech communities** — Specific outreach: IslamicFinance communities, MuslimPro users, r/islam productivity threads

### Pro plan pricing (proposed)
| Plan | Price | Audience |
|---|---|---|
| Free | $0/mo | Individuals, students, casual users |
| Pro | $5.99/mo or $49/yr | Power users wanting all features |
| Team | TBD | Future (V2+) |

### Launch metrics target
| Metric | Launch week goal |
|---|---|
| ProductHunt upvotes | > 100 |
| New signups | > 500 |
| Pro conversions | > 10 |
| Press/blog mentions | 2–3 |

---

## Phase 4 — Growth (October 2026+)

**Goal:** Sustainable growth engine. $500+ MRR. App store presence.

### Product
- [ ] Native iOS app (Flutter iOS build)
- [ ] Native Android app (Flutter Android build)
- [ ] Apple Health / Google Fit sync
- [ ] API integrations: Google Calendar, bank import
- [ ] Team/family plan
- [ ] Offline mode

### Marketing (ongoing)
- SEO blog: 2 posts/month targeting long-tail productivity keywords
- YouTube channel: "Building a life OS" series
- Affiliate/referral program (Pro users get 1 month free per referral)
- Partnership: Notion template creators, productivity YouTubers
- Podcast appearances: productivity/Muslim entrepreneur shows

### Revenue targets
| Month | MRR target | Notes |
|---|---|---|
| Sep 2026 (launch) | $50–100 | First Pro conversions |
| Oct 2026 | $200 | Word of mouth |
| Dec 2026 | $500 | Steady growth |
| Mar 2027 | $1,000 | App store boost |
| Jun 2027 | $2,500 | Team plan live |

---

## Content Strategy (across all phases)

### Pillars of content
1. **Feature demos** — Screen recordings of a single feature (30–60s)
2. **Behind the scenes** — Code snippets, design decisions, "why I built this"
3. **Productivity philosophy** — Tips aligned with PRP's 4 resources (Time, Money, Energy, Health)
4. **User stories** — Alpha/beta testers sharing how they use it
5. **Islamic productivity** (for Deen pillar audience) — Salah discipline, Ramadan planning

### Posting rhythm
| Platform | Frequency | Format |
|---|---|---|
| Twitter/X | 3–4x/week | Text + screenshot |
| LinkedIn | 1–2x/week | Long-form story |
| TikTok/Reels | 1x/week | 30–60s screen recording |
| Newsletter | Bi-weekly | 300–500 words |
| Blog | Monthly | 800–1500 words (SEO) |

---

## Key Risks & Mitigations

| Risk | Mitigation |
|---|---|
| PH launch flops | Prep hunter list 3 weeks ahead; launch on Tuesday not Friday |
| Low D30 retention | Fix onboarding + daily check-in before launch |
| App name conflict (Monk) | Don't rename until trademark cleared (see analysis doc) |
| No mobile app at launch | PWA install prompt on mobile web as stopgap |
| Supabase free tier limits | Monitor — upgrade to Pro ($25/mo) if > 500 MAU |

---

*Document created: April 2026 | Update monthly*
