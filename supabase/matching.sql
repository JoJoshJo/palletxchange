-- ============================================================================
-- PalletXchange — server-side smart matching RPC (BRAIN §7)
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- Called from the app as supabase.rpc('match_listings_for_request',
--   params: { p_request_id: <uuid> }). Contains NO secrets.
--
-- Scoring (max 12): type +3 · size +3 · qty_available >= qty_needed +2 ·
-- condition +2 · max_price set & price <= max +2 · delivery-pref &
-- delivery_available +1 · pickup-pref & pickup_available +1.
-- Only ACTIVE listings, score > 0, sorted desc. Targeted requests are limited
-- to the target seller's listings.
-- ============================================================================

create or replace function public.match_listings_for_request(p_request_id uuid)
returns table(listing_id uuid, score integer)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.score
  from (
    select
      l.id,
      ( case when r.pallet_type_needed is not null
              and l.pallet_type = r.pallet_type_needed then 3 else 0 end
      + case when r.pallet_size_needed is not null
              and l.pallet_size = r.pallet_size_needed then 3 else 0 end
      + case when l.quantity_available >= r.quantity_needed then 2 else 0 end
      + case when r.preferred_condition is not null
              and l.condition = r.preferred_condition then 2 else 0 end
      + case when r.max_price is not null
              and l.price_per_pallet <= r.max_price then 2 else 0 end
      + case when r.pickup_or_delivery = 'delivery'
              and l.delivery_available then 1 else 0 end
      + case when r.pickup_or_delivery = 'pickup'
              and l.pickup_available then 1 else 0 end
      ) as score
    from public.listings l
    cross join (select * from public.requests where id = p_request_id) r
    where l.status = 'active'
      and (r.target_seller_id is null or l.seller_id = r.target_seller_id)
  ) s
  where s.score > 0
  order by s.score desc;
$$;

grant execute on function public.match_listings_for_request(uuid)
  to anon, authenticated;

-- ============================================================================
-- End.
-- ============================================================================
