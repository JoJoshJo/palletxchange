-- ============================================================================
-- PalletXchange — availability trigger + 24h auto-archive job (BRAIN §7)
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- Optionally enable pg_cron (see step 3) to run the archive hourly; otherwise
-- call public.archive_stale_unavailable() manually or from a scheduled Edge
-- Function. Contains NO secrets.
-- ============================================================================

-- 1) Stamp/clear unavailable_since automatically on status changes.
--    Unavailable → set the 24h clock; anything else → clear it.
create or replace function public.set_unavailable_since()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'unavailable' then
    if tg_op = 'INSERT' or old.status is distinct from 'unavailable' then
      new.unavailable_since := coalesce(new.unavailable_since, now());
    end if;
  else
    new.unavailable_since := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_unavailable_since on public.listings;
create trigger trg_set_unavailable_since
  before insert or update on public.listings
  for each row execute function public.set_unavailable_since();

-- 2) Archive listings that have been Unavailable for >24h AND have no live deal.
create or replace function public.archive_stale_unavailable()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  affected integer;
begin
  update public.listings l
     set status = 'archived'
   where l.status = 'unavailable'
     and l.unavailable_since is not null
     and l.unavailable_since < now() - interval '24 hours'
     and not exists (
       select 1 from public.deals d
        where d.listing_id = l.id
          and d.deal_status in ('pending', 'accepted')
     );
  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- 3) Schedule it hourly IF pg_cron is available; otherwise leave a notice.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    if exists (select 1 from cron.job where jobname = 'archive-stale-unavailable') then
      perform cron.unschedule('archive-stale-unavailable');
    end if;
    perform cron.schedule(
      'archive-stale-unavailable',
      '0 * * * *',                         -- top of every hour
      $cron$ select public.archive_stale_unavailable(); $cron$
    );
    raise notice 'Scheduled archive-stale-unavailable via pg_cron.';
  else
    raise notice 'pg_cron not enabled — enable it (Database → Extensions) and re-run, or call public.archive_stale_unavailable() on a schedule.';
  end if;
end $$;

-- ============================================================================
-- End.
-- ============================================================================
