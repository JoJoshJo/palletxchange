-- ============================================================================
-- PalletXchange — server-side radius search (BRAIN §7 distance)
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- Uses cube + earthdistance (available on Supabase). Returns active listings
-- within a radius (nearest-first, paged) as JSON rows that already include the
-- seller and a distance_miles field, so the app needs no second query.
-- Listings with NULL coordinates are still included (distance null, last).
-- Contains NO secrets.
-- ============================================================================

create extension if not exists cube with schema extensions;
create extension if not exists earthdistance with schema extensions;

create or replace function public.listings_within_radius(
  p_lat            double precision,
  p_lng            double precision,
  p_radius_miles   double precision,
  p_limit          integer default 25,
  p_offset         integer default 0,
  p_type           text default null,
  p_size           text default null,
  p_condition      text default null,
  p_free_only      boolean default false,
  p_delivery_only  boolean default false,
  p_recyclable     boolean default false,
  p_max_price      numeric default null,
  p_search         text default null
)
returns setof jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  with scored as (
    select
      l.*,
      case
        when l.latitude is null or l.longitude is null then null
        else earth_distance(
               ll_to_earth(p_lat, p_lng),
               ll_to_earth(l.latitude, l.longitude)
             ) / 1609.344   -- meters → miles
      end as dist
    from public.listings l
    where l.status = 'active'
      and (p_type      is null or l.pallet_type = p_type)
      and (p_size      is null or l.pallet_size = p_size)
      and (p_condition is null or l.condition   = p_condition)
      and (not p_free_only     or l.is_free)
      and (not p_delivery_only or l.delivery_available)
      and (not p_recyclable    or l.condition in ('Damaged','Scrap/recycling only'))
      and (p_max_price is null  or l.price_per_pallet <= p_max_price)
      and (p_search is null or p_search = '' or
           (l.title ilike '%'||p_search||'%'
            or coalesce(l.city,'')  ilike '%'||p_search||'%'
            or coalesce(l.state,'') ilike '%'||p_search||'%'
            or l.pallet_type        ilike '%'||p_search||'%'))
  )
  select
    to_jsonb(s) - 'dist'
      || jsonb_build_object(
           'distance_miles', s.dist,
           'seller', to_jsonb(p) - 'email' - 'phone' - 'address'
                       - 'driver_license_url' - 'driver_insurance_url'
         )
  from scored s
  left join public.profiles p on p.id = s.seller_id
  -- within radius OR unknown coords (kept, sorted last)
  where s.dist is null or s.dist <= p_radius_miles
  order by s.dist asc nulls last, s.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant execute on function public.listings_within_radius(
  double precision, double precision, double precision, integer, integer,
  text, text, text, boolean, boolean, boolean, numeric, text
) to anon, authenticated;

-- ============================================================================
-- End.
-- ============================================================================
