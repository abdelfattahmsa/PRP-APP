-- ══════════════════════════════════════════════════════════════
-- Religion Pillar Tables
-- Run in Supabase SQL Editor
-- ══════════════════════════════════════════════════════════════

-- ── Salah (prayer) records ───────────────────────────────────
create table if not exists public.salah_records (
  id          uuid    default gen_random_uuid() primary key,
  user_id     uuid    references public.profiles(id) on delete cascade not null,
  date        date    not null,
  prayers     jsonb   not null default '{}',
  created_at  timestamptz default now(),
  unique (user_id, date)
);

alter table public.salah_records enable row level security;

create policy "Users own their salah records"
  on public.salah_records for all
  using (auth.uid() = user_id);

-- ── Quran sessions ───────────────────────────────────────────
create table if not exists public.quran_sessions (
  id          uuid    default gen_random_uuid() primary key,
  user_id     uuid    references public.profiles(id) on delete cascade not null,
  date        date    not null default current_date,
  minutes     integer not null default 15 check (minutes > 0),
  type        text    not null default 'reading'
                check (type in ('reading', 'memorization', 'revision')),
  from_surah  integer check (from_surah between 1 and 114),
  to_surah    integer check (to_surah between 1 and 114),
  notes       text,
  created_at  timestamptz default now()
);

alter table public.quran_sessions enable row level security;

create policy "Users own their quran sessions"
  on public.quran_sessions for all
  using (auth.uid() = user_id);

-- ── Indexes ──────────────────────────────────────────────────
create index if not exists salah_records_user_date
  on public.salah_records (user_id, date desc);

create index if not exists quran_sessions_user_date
  on public.quran_sessions (user_id, date desc);
