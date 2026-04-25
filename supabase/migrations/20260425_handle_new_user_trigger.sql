-- Migration: Auto-create profile row when a new user signs up
-- ─────────────────────────────────────────────────────────────
-- Problem: When email confirmation is required, res.session is null after signUp().
-- This means auth.uid() is null client-side, causing RLS policy violations
-- when the client tries to INSERT into profiles (policy: with check (auth.uid() = id)).
--
-- Solution: A SECURITY DEFINER trigger runs as the DB owner, bypassing RLS,
-- and creates the profile row automatically at the DB level whenever a new
-- auth.users row is inserted.
--
-- Run this in your Supabase SQL Editor once.
-- ─────────────────────────────────────────────────────────────

-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;  -- idempotent: safe if profile already exists

  RETURN NEW;
END;
$$;

-- Step 2: Attach the trigger to auth.users INSERT
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- Notes:
-- • SECURITY DEFINER: runs as superuser, bypasses RLS
-- • ON CONFLICT DO NOTHING: safe if client-side upsert also fires (confirmed sessions)
-- • The client-side seed (habits, goals, schedule blocks) still runs only when
--   res.session != null (i.e. auto-confirmed or no email confirmation required)
-- • For email-confirmed users, _seedDefaultData() is called on first successful sign-in
--   via the signIn() → profiles upsert path (already guarded by session check)
-- ─────────────────────────────────────────────────────────────
