-- ============================================================================
-- PalletXchange — account suspension (ban) capability
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- Prereq: schema.sql (public.is_admin, enforce_profile_privileges) and
-- notifications.sql. Contains NO secrets.
-- ============================================================================

-- 1) Column
alter table public.profiles
  add column if not exists banned boolean not null default false;

-- 2) Protect `banned` like the other privileged columns: only an admin may
--    change it. Re-create the guard trigger function to include `banned`.
create or replace function public.enforce_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    new.verified_status := old.verified_status;
    new.is_admin        := old.is_admin;
    new.driver_approved := old.driver_approved;
    new.banned          := old.banned;
  end if;
  return new;
end;
$$;

-- 3) Admin-only RPC to ban/unban a user + notify them.
create or replace function public.admin_set_banned(
  p_user uuid, p_banned boolean, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only';
  end if;

  update public.profiles set banned = p_banned where id = p_user;

  insert into public.notifications (user_id, type, title, body)
  values (
    p_user,
    case when p_banned then 'account_suspended' else 'account_restored' end,
    case when p_banned then 'Your account is suspended'
         else 'Your account is restored' end,
    case when p_banned then coalesce(p_reason, 'Contact support for details.')
         else 'You can use PalletXchange again.' end
  );
end;
$$;

grant execute on function public.admin_set_banned(uuid, boolean, text)
  to authenticated;

-- ============================================================================
-- End.
-- ============================================================================
