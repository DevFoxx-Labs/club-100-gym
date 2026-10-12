-- =====================================================================
-- Elite Fitness — offline-first sync schema (v1)
-- If the OLD schema (supabase_schema.sql) was already run and holds no
-- real data, uncomment and run this block first:
-- drop table if exists member_device_tokens, announcements, events, expenses,
--   receipts, payments, bills, trainer_change_logs, membership_change_logs,
--   memberships, members, trainer_payouts, trainers, membership_plans,
--   membership_packages, admins, notification_settings, app_settings, gyms cascade;
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- gyms (one per auth user) ----------
create table if not exists gyms (
  id text primary key,
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text, owner_name text, phone text, email text, website text,
  address text, city text, logo_path text, currency text,
  upi_id text, upi_payee_name text,
  bank_account_holder text, bank_account_number text, bank_ifsc text, bank_name text,
  show_upi_qr_on_bill integer, show_bank_details_on_bill integer,
  default_print_format text,
  created_at text, updated_at text,
  is_deleted boolean not null default false,
  server_updated_at timestamptz not null default now()
);

-- ---------- helper to declare child tables ----------
-- Each child table: gym_id + id composite key, tombstone, server clock.

create table if not exists admins (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, is_biometric_enabled integer,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_packages (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, description text, is_active integer,
  created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_plans (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  package_id text, name text, duration_days integer, default_fee double precision,
  description text, is_active integer, created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainers (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, role text, specialization text, monthly_salary double precision,
  photo_path text, is_active integer, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainer_payouts (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  trainer_id text, amount double precision, payout_date text, payout_type text, notes text,
  created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists members (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, email text, gender text, date_of_birth text, photo_path text,
  notes text, is_archived integer, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists memberships (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, plan_id text, plan_name text, trainer_id text,
  personal_training_fee double precision, package_id text,
  start_date text, end_date text, fee_amount double precision, status text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_change_logs (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, previous_membership_id text, new_membership_id text,
  previous_plan_name_snapshot text, new_plan_name_snapshot text,
  previous_fee_amount double precision, new_fee_amount double precision,
  reason text, changed_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainer_change_logs (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, membership_id text,
  previous_trainer_id text, previous_trainer_name_snapshot text,
  new_trainer_id text, new_trainer_name_snapshot text,
  previous_personal_training_fee double precision, new_personal_training_fee double precision,
  reason text, changed_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists bills (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  bill_number text, member_id text, member_name text, member_phone text,
  membership_id text, plan_name text, amount double precision,
  bill_date text, due_date text, status text, paid_amount double precision,
  payment_id text, receipt_id text, notes text, is_auto_generated integer, cycle_key text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists payments (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, membership_id text, bill_id text, amount double precision,
  payment_date text, payment_method text, notes text, receipt_id text, receipt_number text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists receipts (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  payment_id text, receipt_number text, bill_number text, member_name text, member_phone text,
  plan_name text, trainer_name text, personal_training_fee double precision,
  amount double precision, payment_method text, payment_date text,
  start_date text, end_date text, qr_payload text, created_at text,
  bill_total double precision, balance_due double precision,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists expenses (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, category text, amount double precision, expense_date text,
  payment_method text, notes text, created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists events (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, description text, start_time text, end_time text, location text,
  trainer_id text, color_value bigint, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists announcements (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, message text, image_path text, category text,
  audience_type text, audience_label text, audience_plan_id text,
  is_important integer, is_pinned integer, status text,
  scheduled_at text, sent_at text, created_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists notification_settings (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  fee_reminder7_days integer, fee_reminder3_days integer, fee_reminder1_day integer,
  fee_reminder_due_today integer, fee_reminder_overdue integer,
  membership_reminder7_days integer, membership_reminder3_days integer, membership_reminder1_day integer,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists app_settings (
  gym_id text not null references gyms(id) on delete cascade, key text not null,
  value text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, key)
);

-- Kept for the client_app (member devices register FCM tokens anonymously).
create table if not exists member_device_tokens (
  id text primary key default gen_random_uuid()::text,
  gym_id text references gyms(id) on delete cascade,
  member_id text,
  fcm_token text not null unique,
  platform text default 'android',
  last_active_at text not null default now()::text,
  created_at text not null default now()::text
);

-- ---------- server change clock + indexes ----------
create or replace function public.touch_server_updated_at()
returns trigger language plpgsql as $$
begin
  new.server_updated_at := now();
  return new;
end $$;

do $$
declare
  tbl text;
  tables text[] := array[
    'gyms','admins','membership_packages','membership_plans','trainers','trainer_payouts',
    'members','memberships','membership_change_logs','trainer_change_logs','bills',
    'payments','receipts','expenses','events','announcements','notification_settings','app_settings'
  ];
begin
  foreach tbl in array tables loop
    execute format('drop trigger if exists trg_touch_%1$s on %1$I;', tbl);
    execute format('create trigger trg_touch_%1$s before insert or update on %1$I
                    for each row execute function public.touch_server_updated_at();', tbl);
    if tbl <> 'gyms' then
      execute format('create index if not exists idx_%1$s_sync on %1$I (gym_id, server_updated_at);', tbl);
    end if;
  end loop;
end $$;

-- ---------- Row Level Security ----------
create or replace function public.owns_gym(p_gym_id text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from gyms where id = p_gym_id and owner_id = auth.uid());
$$;

alter table gyms enable row level security;
drop policy if exists gyms_owner_all on gyms;
create policy gyms_owner_all on gyms for all to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

do $$
declare
  tbl text;
  tables text[] := array[
    'admins','membership_packages','membership_plans','trainers','trainer_payouts',
    'members','memberships','membership_change_logs','trainer_change_logs','bills',
    'payments','receipts','expenses','events','announcements','notification_settings','app_settings'
  ];
begin
  foreach tbl in array tables loop
    execute format('alter table %I enable row level security;', tbl);
    execute format('drop policy if exists %1$s_owner_all on %1$I;', tbl);
    execute format('create policy %1$s_owner_all on %1$I for all to authenticated
                    using (public.owns_gym(gym_id)) with check (public.owns_gym(gym_id));', tbl);
  end loop;
end $$;

-- client_app reads announcements of its gym without logging in.
drop policy if exists announcements_public_read on announcements;
create policy announcements_public_read on announcements for select to anon
  using (is_deleted = false and status = 'sent');

-- Member devices may only REGISTER a token for an existing gym; only the
-- gym owner can read/update/delete their gym's tokens.
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

-- Realtime for client_app
do $$ begin
  alter publication supabase_realtime add table announcements;
exception when duplicate_object then null;
end $$;

-- ---------- Storage (Phase 7: photos/logos) ----------
insert into storage.buckets (id, name, public)
values ('gym-media', 'gym-media', false)
on conflict (id) do nothing;

drop policy if exists "gym media owner access" on storage.objects;
create policy "gym media owner access" on storage.objects for all to authenticated
  using (bucket_id = 'gym-media' and public.owns_gym((storage.foldername(name))[1]))
  with check (bucket_id = 'gym-media' and public.owns_gym((storage.foldername(name))[1]));

