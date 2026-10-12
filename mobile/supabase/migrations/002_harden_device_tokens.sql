-- =====================================================================
-- 002 — Harden member_device_tokens (safe to run more than once).
-- Run this if 001_offline_sync_schema.sql was applied BEFORE this file
-- existed. 001 already contains these policies for fresh setups.
--
-- Before: anyone with the anon key could read, change or delete every
-- gym's push tokens. After: member devices may only register a token for
-- an existing gym; only the gym owner can read/update/delete them.
-- =====================================================================

create or replace function public.gym_exists(p_gym_id text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from gyms where id = p_gym_id and is_deleted = false);
$$;

alter table member_device_tokens enable row level security;

drop policy if exists tokens_anon_upsert on member_device_tokens;
drop policy if exists tokens_register on member_device_tokens;
drop policy if exists tokens_owner_all on member_device_tokens;

create policy tokens_register on member_device_tokens for insert to anon, authenticated
  with check (public.gym_exists(gym_id));

create policy tokens_owner_all on member_device_tokens for all to authenticated
  using (public.owns_gym(gym_id)) with check (public.owns_gym(gym_id));
