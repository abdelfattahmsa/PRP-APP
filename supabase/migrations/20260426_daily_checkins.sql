-- Daily check-ins table
-- Run at: https://app.supabase.com/project/qjqkmvlqrrkowvisvcmc/sql

create table if not exists daily_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  morning_energy integer check (morning_energy between 1 and 5),
  top_priority text,
  evening_mood integer check (evening_mood between 1 and 5),
  accomplishment text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, date)
);

alter table daily_checkins enable row level security;

create policy "user_owns" on daily_checkins
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
