-- ============================================================================
-- PalletXchange — starter listings seed (real DB)
-- ============================================================================
-- Inserts 6 varied starter listings so the marketplace isn't empty. They are
-- owned by an EXISTING real profile (no fake auth accounts).
--
-- HOW / WHEN TO RUN  (Supabase → SQL Editor)
--   1. Create a real account in the app (or pick any existing one).
--   2. Find its profile id — run this and copy the id you want to own the seed:
--          select id, email, business_name from public.profiles;
--   3. In the block below, replace  PASTE-PROFILE-UID-HERE  with that id.
--   4. Paste this whole file into the SQL Editor and press Run.
--
--   Note: the SQL Editor does NOT support psql \set, so the id is set as a
--   variable inside the DO block — just edit that one line.
--   Safe to re-run (fixed listing UUIDs + ON CONFLICT DO NOTHING).
--
-- Contains NO secrets.
-- ============================================================================

do $$
declare
  -- >>> EDIT THIS LINE: paste a real profiles.id to own the starter listings.
  seller_uid uuid := 'PASTE-PROFILE-UID-HERE';
begin
  if not exists (select 1 from public.profiles where id = seller_uid) then
    raise exception
      'seller_uid % is not a profiles.id — run "select id, email from public.profiles;" and paste a real id',
      seller_uid;
  end if;

  insert into public.listings
    (id, seller_id, title, pallet_type, pallet_size, condition,
     quantity_available, min_order_quantity, price_per_pallet, is_free,
     exchange_allowed, pickup_available, delivery_available,
     loading_dock_available, forklift_available, stackable,
     city, state, zip, latitude, longitude, notes, status)
  values
    ('b0000000-0000-4000-8000-000000000001', seller_uid,
     'Grade-A 48x40 GMA pallets — bulk',
     'Standard wooden pallets', '48 x 40', 'Like new',
     320, 20, 12.50, false, false, true, true, true, true, true,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Recycled GMA spec, 4-way entry. Consistent weekly stock.', 'active'),

    ('b0000000-0000-4000-8000-000000000002', seller_uid,
     'Heat-treated (ISPM-15) export pallets',
     'Heat-treated pallets', '48 x 40', 'New',
     150, 10, 18.00, false, false, true, true, true, true, true,
     'Atlanta', 'GA', '30318', 33.7890, -84.3900,
     'Stamped HT for international freight. New build.', 'active'),

    ('b0000000-0000-4000-8000-000000000003', seller_uid,
     'Used repairable stringer pallets',
     'Stringer pallets', '48 x 40', 'Used, repairable',
     140, 20, 6.75, false, false, true, true, false, true, true,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Some deck board damage, structurally sound stringers.', 'active'),

    ('b0000000-0000-4000-8000-000000000004', seller_uid,
     'Plastic pallets — hygienic, 48x48',
     'Plastic pallets', '48 x 48', 'Used, good condition',
     64, 4, 27.00, false, false, true, false, false, true, true,
     'Atlanta', 'GA', '30318', 33.7890, -84.3900,
     'Food-grade HDPE, washable. Great for cold storage.', 'active'),

    ('b0000000-0000-4000-8000-000000000005', seller_uid,
     'FREE broken pallets — you haul',
     'Broken or recyclable pallets', '48 x 40', 'Scrap/recycling only',
     200, 25, 0, true, false, true, false, false, false, false,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Clearing the yard. Mixed damage, good for repair or firewood.', 'active'),

    ('b0000000-0000-4000-8000-000000000006', seller_uid,
     'Euro (EPAL) pallets — certified',
     'Euro pallets', 'Euro pallet', 'Like new',
     88, 8, 21.50, false, true, true, true, true, true, true,
     'Atlanta', 'GA', '30318', 33.7890, -84.3900,
     'EPAL-stamped, exchange program available.', 'active')
  on conflict (id) do nothing;
end $$;

-- ============================================================================
-- End of seed.
-- ============================================================================
