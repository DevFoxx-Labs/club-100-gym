-- =====================================================================
-- 004 — Safe use of the same account on several phones at once
-- (safe to run more than once). Already included in 001 for fresh setups.
--
-- 1. gym_devices + register_device(): gives every phone of a gym its own
--    short code ('A', 'B', …). Bill/receipt numbers carry it
--    (GYM-2026-A00012), so two phones working offline can never create the
--    same number — a duplicate would make one phone's receipt silently
--    replace the other's when synced.
-- 2. server_updated_at uses clock_timestamp() (the moment the row is
--    written) instead of now() (start of the transaction), narrowing the gap
--    in which a concurrent write could be missed by incremental pulls. The
--    app additionally re-reads a 2-minute overlap on every pull.
-- =====================================================================

create table if not exists gym_devices (
  gym_id text not null references gyms(id) on delete cascade,
  device_id text not null,
  code text not null,
  created_at timestamptz not null default now(),
  primary key (gym_id, device_id),
  unique (gym_id, code)
);

alter table gym_devices enable row level security;
drop policy if exists gym_devices_owner_all on gym_devices;
create policy gym_devices_owner_all on gym_devices for all to authenticated
  using (public.owns_gym(gym_id)) with check (public.owns_gym(gym_id));

-- Returns this phone's code for the gym, assigning the next free one
-- ('A'…'Z', then 'AA'…) on the first call. Only the gym's owner may call it.
create or replace function public.register_device(p_gym_id text, p_device_id text)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_code text;
  v_n int;
begin
  if not public.owns_gym(p_gym_id) then
    raise exception 'not your gym';
  end if;

  select code into v_code from gym_devices where gym_id = p_gym_id and device_id = p_device_id;
  if v_code is not null then
    return v_code;
  end if;

  -- Serialize assignments per gym so two phones can't get the same code.
  perform pg_advisory_xact_lock(hashtext(p_gym_id));
  select count(*) into v_n from gym_devices where gym_id = p_gym_id;
  v_code := case
    when v_n < 26 then chr(65 + v_n)
    else chr(65 + v_n / 26 - 1) || chr(65 + v_n % 26)
  end;
  insert into gym_devices (gym_id, device_id, code) values (p_gym_id, p_device_id, v_code);
  return v_code;
end $$;

revoke all on function public.register_device(text, text) from public, anon;
grant execute on function public.register_device(text, text) to authenticated;

create or replace function public.touch_server_updated_at()
returns trigger language plpgsql as $$
begin
  new.server_updated_at := clock_timestamp();
  return new;
end $$;
