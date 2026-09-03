-- ============================================================================
-- PalletXchange — starter seed data (real DB)
-- ============================================================================
-- Inserts 2 clearly-named DEMO/SYSTEM seller accounts + 6 starter listings so
-- the marketplace isn't empty before real users arrive.
--
-- HOW / WHEN TO RUN
--   Run AFTER schema.sql, in Supabase → SQL Editor → paste → Run.
--   Safe to re-run (idempotent: fixed UUIDs + ON CONFLICT DO NOTHING/UPDATE).
--
-- WHY auth.users rows: profiles.id has a FK to auth.users, so a seller profile
-- needs a matching auth.users row. These two are demo/system accounts (no one
-- signs into them); the handle_new_user trigger auto-creates their profile row,
-- which we then fill in. NOT real end-user signups.
--
-- Contains NO secrets.
-- ============================================================================

do $$
declare
  s1 uuid := 'a0000000-0000-4000-8000-0000000000a1';  -- Sunbelt Goods (demo)
  s2 uuid := 'a0000000-0000-4000-8000-0000000000a2';  -- Peachtree Logistics (demo)
begin
  -- 1) Demo seller auth.users (trigger auto-creates their profiles rows).
  insert into auth.users
    (id, instance_id, aud, role, email, email_confirmed_at,
     created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  values
    (s1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'sunbelt-demo@palletxchange.app', now(), now(), now(),
     '{"provider":"seed","providers":["seed"]}', '{}'),
    (s2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'peachtree-demo@palletxchange.app', now(), now(), now(),
     '{"provider":"seed","providers":["seed"]}', '{}')
  on conflict (id) do nothing;

  -- 2) Fill in the demo seller profiles. verified_status is normally
  --    admin-only (protected by trg_enforce_profile_privileges), so disable
  --    that trigger for this seed transaction, then re-enable it.
  alter table public.profiles disable trigger trg_enforce_profile_privileges;

  insert into public.profiles
    (id, name, email, business_name, account_type, city, state,
     latitude, longitude, verified_status)
  values
    (s1, 'Marcus Bell', 'sunbelt-demo@palletxchange.app', 'Sunbelt Goods',
     'warehouse', 'Marietta', 'GA', 33.9526, -84.5499, true),
    (s2, 'Dana Cho', 'peachtree-demo@palletxchange.app', 'Peachtree Logistics',
     'warehouse', 'Atlanta', 'GA', 33.7890, -84.3900, true)
  on conflict (id) do update set
    name           = excluded.name,
    business_name  = excluded.business_name,
    account_type   = excluded.account_type,
    city           = excluded.city,
    state          = excluded.state,
    latitude       = excluded.latitude,
    longitude      = excluded.longitude,
    verified_status = excluded.verified_status;

  alter table public.profiles enable trigger trg_enforce_profile_privileges;

  -- 3) Starter listings (fixed UUIDs → idempotent).
  insert into public.listings
    (id, seller_id, title, pallet_type, pallet_size, condition,
     quantity_available, min_order_quantity, price_per_pallet, is_free,
     exchange_allowed, pickup_available, delivery_available,
     loading_dock_available, forklift_available, stackable,
     city, state, zip, latitude, longitude, notes, status)
  values
    ('b0000000-0000-4000-8000-000000000001', s1,
     'Grade-A 48x40 GMA pallets — bulk',
     'Standard wooden pallets', '48 x 40', 'Like new',
     320, 20, 12.50, false, false, true, true, true, true, true,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Recycled GMA spec, 4-way entry. Consistent weekly stock.', 'active'),

    ('b0000000-0000-4000-8000-000000000002', s2,
     'Heat-treated (ISPM-15) export pallets',
     'Heat-treated pallets', '48 x 40', 'New',
     150, 10, 18.00, false, false, true, true, true, true, true,
     'Atlanta', 'GA', '30318', 33.7890, -84.3900,
     'Stamped HT for international freight. New build.', 'active'),

    ('b0000000-0000-4000-8000-000000000003', s1,
     'Used repairable stringer pallets',
     'Stringer pallets', '48 x 40', 'Used, repairable',
     140, 20, 6.75, false, false, true, true, false, true, true,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Some deck board damage, structurally sound stringers.', 'active'),

    ('b0000000-0000-4000-8000-000000000004', s2,
     'Plastic pallets — hygienic, 48x48',
     'Plastic pallets', '48 x 48', 'Used, good condition',
     64, 4, 27.00, false, false, true, false, false, true, true,
     'Atlanta', 'GA', '30318', 33.7890, -84.3900,
     'Food-grade HDPE, washable. Great for cold storage.', 'active'),

    ('b0000000-0000-4000-8000-000000000005', s1,
     'FREE broken pallets — you haul',
     'Broken or recyclable pallets', '48 x 40', 'Scrap/recycling only',
     200, 25, 0, true, false, true, false, false, false, false,
     'Marietta', 'GA', '30060', 33.9526, -84.5499,
     'Clearing the yard. Mixed damage, good for repair or firewood.', 'active'),

    ('b0000000-0000-4000-8000-000000000006', s2,
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
