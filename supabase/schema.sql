-- ══════════════════════════════════════════════════════════════
-- LIFE PLAN APP — SUPABASE SCHEMA
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ══════════════════════════════════════════════════════════════

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── PROFILES ──────────────────────────────────────────────────
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  full_name text,
  avatar_url text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- ── SCHEDULE BLOCKS ───────────────────────────────────────────
create table public.schedule_blocks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  schedule_mode text not null check (schedule_mode in ('normal', 'fasting', 'friday', 'cairo')),
  time text not null,
  label text not null,
  category_key text not null,
  duration text,
  note text,
  "order" int default 0,
  notify_on_start boolean default true,
  notify_on_end boolean default false,
  created_at timestamptz default now()
);

alter table public.schedule_blocks enable row level security;
create policy "schedule_blocks_own" on public.schedule_blocks
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_schedule_blocks_user_mode on public.schedule_blocks(user_id, schedule_mode, "order");

-- ── CALENDAR EVENTS ───────────────────────────────────────────
create table public.calendar_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  date date not null,
  title text not null,
  type_key text not null default 'personal',
  notes text,
  link_url text,
  attachment_url text,
  is_done boolean default false,
  is_default boolean default false,
  gcal_event_id text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.calendar_events enable row level security;
create policy "calendar_events_own" on public.calendar_events
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_calendar_events_user_date on public.calendar_events(user_id, date);

-- ── BANK ACCOUNTS ─────────────────────────────────────────────
create table public.bank_accounts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  name text not null,
  cc_balance numeric default 0,
  cc_limit numeric default 0,
  savings_balance numeric default 0,
  current_balance numeric default 0,
  "order" int default 0,
  created_at timestamptz default now()
);

alter table public.bank_accounts enable row level security;
create policy "bank_accounts_own" on public.bank_accounts
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── DEBTS ─────────────────────────────────────────────────────
create table public.debts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  source text not null,
  amount numeric not null,
  notes text,
  due_date date,
  is_paid boolean default false,
  created_at timestamptz default now()
);

alter table public.debts enable row level security;
create policy "debts_own" on public.debts
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── INVESTMENTS ───────────────────────────────────────────────
create table public.investments (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  type text not null,
  amount numeric not null,
  unit text not null default 'EGP',
  notes text,
  purchase_date date,
  created_at timestamptz default now()
);

alter table public.investments enable row level security;
create policy "investments_own" on public.investments
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── TRANSACTIONS ──────────────────────────────────────────────
create table public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  date date not null,
  description text not null,
  amount numeric not null,
  category text not null default 'General',
  account_name text not null,
  notes text,
  is_income boolean default false,
  created_at timestamptz default now()
);

alter table public.transactions enable row level security;
create policy "transactions_own" on public.transactions
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_transactions_user_date on public.transactions(user_id, date desc);

-- ── HABITS ────────────────────────────────────────────────────
create table public.habits (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  name text not null,
  icon text not null default '✅',
  streak int default 0,
  longest_streak int default 0,
  history jsonb default '{}',
  "order" int default 0,
  is_archived boolean default false,
  created_at timestamptz default now()
);

alter table public.habits enable row level security;
create policy "habits_own" on public.habits
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── GOALS ─────────────────────────────────────────────────────
create table public.goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  title text not null,
  description text,
  target_date date not null,
  priority text default 'medium' check (priority in ('high', 'medium', 'low')),
  status text default 'active' check (status in ('active', 'done', 'paused')),
  progress int default 0 check (progress between 0 and 100),
  milestones text[] default '{}',
  linked_event_ids uuid[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.goals enable row level security;
create policy "goals_own" on public.goals
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── FOCUS SESSIONS ────────────────────────────────────────────
create table public.focus_sessions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles on delete cascade not null,
  date date not null,
  block_label text not null,
  block_category_key text not null,
  planned_seconds int not null,
  actual_seconds int not null,
  completed boolean not null,
  note text,
  started_at timestamptz,
  created_at timestamptz default now()
);

alter table public.focus_sessions enable row level security;
create policy "focus_sessions_own" on public.focus_sessions
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index idx_focus_sessions_user_date on public.focus_sessions(user_id, date desc);

-- ── UPDATED_AT TRIGGER ────────────────────────────────────────
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger goals_updated_at before update on public.goals
  for each row execute procedure update_updated_at();
create trigger calendar_events_updated_at before update on public.calendar_events
  for each row execute procedure update_updated_at();

-- ── STORAGE BUCKET (for attachments) ──────────────────────────
insert into storage.buckets (id, name, public) values ('attachments', 'attachments', false);

create policy "Users can upload own attachments" on storage.objects
  for insert with check (auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can view own attachments" on storage.objects
  for select using (auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can delete own attachments" on storage.objects
  for delete using (auth.uid()::text = (storage.foldername(name))[1]);
