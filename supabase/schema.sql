-- ============================================================================
-- PalletXchange — Supabase / Postgres schema
-- ============================================================================
-- Source of truth: BRAIN.md §6 (data model) and §7 (business logic).
--
-- HOW TO RUN
--   1. Open your Supabase project → SQL Editor → New query.
--   2. Paste this entire file and press "Run".
--   It runs top-to-bottom on a fresh project and is SAFE TO RE-RUN (enums are
--   guarded, tables use IF NOT EXISTS, functions are CREATE OR REPLACE, and
--   every policy is dropped-then-created).
--
-- CONFIGURED SEPARATELY (not in this file):
--   • Storage buckets (listing photos, driver license/insurance, delivery
--     proof) — created in the Storage UI next.
--   • Auth providers (email/password + Google) — enabled in Auth settings.
--
-- Contains NO secrets or keys.
-- ============================================================================


-- ============================================================================
-- 1. ENUMS  (BRAIN §6)
-- ============================================================================
do $$ begin
  if not exists (select 1 from pg_type where typname = 'account_type') then
    create type account_type as enum ('individual', 'warehouse', 'driver');
  end if;

  if not exists (select 1 from pg_type where typname = 'pallet_type') then
    create type pallet_type as enum (
      'Standard wooden pallets', 'Heat-treated pallets', 'Plastic pallets',
      'Euro pallets', 'Stringer pallets', 'Block pallets',
      'Custom-size pallets', 'Broken or recyclable pallets'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'pallet_condition') then
    create type pallet_condition as enum (
      'New', 'Like new', 'Used, good condition', 'Used, repairable',
      'Damaged', 'Scrap/recycling only'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'pallet_size') then
    create type pallet_size as enum (
      '48 x 40', '42 x 42', '48 x 48', '36 x 36', 'Euro pallet', 'Custom size'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'listing_status') then
    create type listing_status as enum ('active', 'unavailable', 'sold_out', 'archived');
  end if;

  if not exists (select 1 from pg_type where typname = 'request_status') then
    create type request_status as enum ('open', 'matched', 'closed', 'cancelled');
  end if;

  if not exists (select 1 from pg_type where typname = 'deal_status') then
    create type deal_status as enum ('pending', 'accepted', 'completed', 'cancelled', 'declined');
  end if;

  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('not_required', 'unpaid', 'paid');
  end if;

  if not exists (select 1 from pg_type where typname = 'delivery_status') then
    create type delivery_status as enum (
      'requested', 'accepted', 'driver_assigned', 'picked_up',
      'in_transit', 'delivered', 'completed', 'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'report_status') then
    create type report_status as enum ('open', 'resolved');
  end if;
end $$;


-- ============================================================================
-- 2. TABLES  (BRAIN §6)
-- ============================================================================

-- profiles ----------------------------------------------------------------
-- id = auth.users(id). Populated at signup (handle_new_user) then completed
-- at onboarding. verified_status is a TRUST BADGE ONLY — never a gate (§4).
create table if not exists public.profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  name                text,
  email               text,
  phone               text,
  business_name       text,
  account_type        account_type not null default 'individual',
  is_admin            boolean not null default false,          -- granted, not chosen
  address             text,
  city                text,
  state               text,
  zip                 text,
  latitude            double precision,
  longitude           double precision,
  verified_status     boolean not null default false,          -- trust badge only
  rating              numeric not null default 0,              -- computed from reviews
  -- Driver vetting (used when account_type = 'driver'): must be approved
  -- before claiming any job (§4, §6, §7).
  driver_license_url    text,
  driver_insurance_url  text,
  driver_approved       boolean not null default false,
  created_at          timestamptz not null default now()
);

-- listings ----------------------------------------------------------------
create table if not exists public.listings (
  id                     uuid primary key default gen_random_uuid(),
  seller_id              uuid not null references public.profiles(id) on delete cascade,
  title                  text not null,
  pallet_type            pallet_type not null,
  pallet_size            pallet_size not null,
  condition              pallet_condition not null,
  quantity_available     integer not null default 0,
  min_order_quantity     integer not null default 1,
  price_per_pallet       numeric not null default 0,
  is_free                boolean not null default false,
  exchange_allowed       boolean not null default false,
  pickup_available       boolean not null default true,
  delivery_available     boolean not null default false,
  address                text,
  city                   text,
  state                  text,
  zip                    text,
  latitude               double precision,
  longitude              double precision,
  loading_dock_available boolean not null default false,
  forklift_available     boolean not null default false,
  stackable              boolean not null default true,
  photos                 text[] not null default '{}',          -- Storage URLs
  notes                  text,
  status                 listing_status not null default 'active',
  unavailable_since      timestamptz,                           -- drives 24h auto-archive
  expires_at             timestamptz,
  created_at             timestamptz not null default now()
);

-- requests (Special Request) ----------------------------------------------
-- target_seller_id null = broadcast to market; set = targeted to one seller.
create table if not exists public.requests (
  id                   uuid primary key default gen_random_uuid(),
  buyer_id             uuid not null references public.profiles(id) on delete cascade,
  target_seller_id     uuid references public.profiles(id) on delete set null,
  pallet_type_needed   pallet_type,
  pallet_size_needed   pallet_size,
  quantity_needed      integer not null default 0,
  preferred_condition  pallet_condition,
  max_price            numeric,
  pickup_or_delivery   text not null default 'pickup'
                         check (pickup_or_delivery in ('pickup', 'delivery')),
  needed_by_date       date,
  location             text,
  notes                text,
  status               request_status not null default 'open',
  created_at           timestamptz not null default now()
);

-- deals (was transactions) ------------------------------------------------
-- total_price is derived (quantity × price_per_pallet) by trigger.
-- delivery_paid_by is decided PER DEAL (buyer|seller); null until set (§7).
create table if not exists public.deals (
  id                 uuid primary key default gen_random_uuid(),
  listing_id         uuid not null references public.listings(id) on delete restrict,
  buyer_id           uuid not null references public.profiles(id) on delete cascade,
  seller_id          uuid not null references public.profiles(id) on delete cascade,
  driver_id          uuid references public.profiles(id) on delete set null,
  quantity           integer not null default 1,
  price_per_pallet   numeric not null default 0,
  total_price        numeric not null default 0,
  fulfillment_method text not null default 'pickup'
                       check (fulfillment_method in ('pickup', 'delivery')),
  delivery_address   text,
  delivery_fee       numeric not null default 0,               -- seller-quoted
  delivery_paid_by   text check (delivery_paid_by in ('buyer', 'seller')),
  payment_status     payment_status not null default 'unpaid',
  deal_status        deal_status not null default 'pending',
  pickup_time        timestamptz,
  completed_at       timestamptz,                              -- set on completion
  notes              text,
  created_at         timestamptz not null default now()
);

-- messages ----------------------------------------------------------------
-- Thread ties to whichever of listing/deal/request started it (no bare DMs).
create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id text not null,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  receiver_id     uuid not null references public.profiles(id) on delete cascade,
  listing_id      uuid references public.listings(id) on delete set null,
  deal_id         uuid references public.deals(id) on delete set null,
  request_id      uuid references public.requests(id) on delete set null,
  body            text not null,
  read_status     boolean not null default false,
  created_at      timestamptz not null default now()
);

-- reviews -----------------------------------------------------------------
-- One review per user per deal (UNIQUE deal_id, reviewer_id).
create table if not exists public.reviews (
  id                   uuid primary key default gen_random_uuid(),
  deal_id              uuid not null references public.deals(id) on delete cascade,
  reviewer_id          uuid not null references public.profiles(id) on delete cascade,
  reviewed_user_id     uuid not null references public.profiles(id) on delete cascade,
  rating               integer not null check (rating between 1 and 5),
  communication_rating integer check (communication_rating between 1 and 5),
  accuracy_rating      integer check (accuracy_rating between 1 and 5),
  delivery_rating      integer check (delivery_rating between 1 and 5),
  review_text          text,
  created_at           timestamptz not null default now(),
  constraint reviews_one_per_user_per_deal unique (deal_id, reviewer_id)
);

-- reports -----------------------------------------------------------------
create table if not exists public.reports (
  id            uuid primary key default gen_random_uuid(),
  reported_by   uuid not null references public.profiles(id) on delete cascade,
  reported_user uuid references public.profiles(id) on delete set null,
  listing_id    uuid references public.listings(id) on delete set null,
  deal_id       uuid references public.deals(id) on delete set null,
  reason        text not null,
  description   text,
  status        report_status not null default 'open',
  admin_notes   text,
  created_at    timestamptz not null default now()
);

-- deliveries (driver job board) -------------------------------------------
create table if not exists public.deliveries (
  id                uuid primary key default gen_random_uuid(),
  deal_id           uuid not null references public.deals(id) on delete cascade,
  driver_id         uuid references public.profiles(id) on delete set null,
  pickup_address    text not null,
  dropoff_address   text not null,
  pickup_time       timestamptz,
  delivery_time     timestamptz,
  delivery_status   delivery_status not null default 'requested',
  proof_of_pickup   text,                                      -- Storage URL
  proof_of_delivery text,                                      -- Storage URL
  delivery_notes    text,
  created_at        timestamptz not null default now()
);


-- ============================================================================
-- 3. INDEXES
-- ============================================================================
create index if not exists idx_listings_status        on public.listings (status);
create index if not exists idx_listings_seller         on public.listings (seller_id);
create index if not exists idx_listings_type_size      on public.listings (pallet_type, pallet_size);
create index if not exists idx_requests_buyer          on public.requests (buyer_id);
create index if not exists idx_requests_target_seller  on public.requests (target_seller_id);
create index if not exists idx_deals_buyer             on public.deals (buyer_id);
create index if not exists idx_deals_seller            on public.deals (seller_id);
create index if not exists idx_deals_driver            on public.deals (driver_id);
create index if not exists idx_deals_listing           on public.deals (listing_id);
create index if not exists idx_messages_conversation   on public.messages (conversation_id);
create index if not exists idx_messages_sender         on public.messages (sender_id);
create index if not exists idx_messages_receiver       on public.messages (receiver_id);
create index if not exists idx_reviews_reviewed_user   on public.reviews (reviewed_user_id);
create index if not exists idx_reports_status          on public.reports (status);
create index if not exists idx_deliveries_driver       on public.deliveries (driver_id);
create index if not exists idx_deliveries_deal         on public.deliveries (deal_id);


-- ============================================================================
-- 4. FUNCTIONS & TRIGGERS  (BRAIN §6 triggers, §7 logic)
-- ============================================================================

-- 4a. is_admin() — SECURITY DEFINER so it can read profiles without tripping
--     RLS recursion. Used across policies.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- 4b. handle_new_user() — on auth.users INSERT, create the profiles row.
--     Remaining fields are filled at onboarding.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4c. enforce_profile_privileges() — non-admins cannot change privileged
--     columns (verified_status / is_admin / driver_approved). They are reset
--     to their prior values unless the caller is an admin.
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
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_profile_privileges on public.profiles;
create trigger trg_enforce_profile_privileges
  before update on public.profiles
  for each row execute function public.enforce_profile_privileges();

-- 4d. recompute_rating() — keep profiles.rating = avg(reviews.rating) for the
--     reviewed user (BRAIN §6 rating recalc).
create or replace function public.recompute_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target uuid;
begin
  target := coalesce(new.reviewed_user_id, old.reviewed_user_id);
  update public.profiles
     set rating = coalesce(
       (select avg(rating)::numeric from public.reviews where reviewed_user_id = target), 0)
   where id = target;
  return null;
end;
$$;

drop trigger if exists trg_recompute_rating on public.reviews;
create trigger trg_recompute_rating
  after insert or update or delete on public.reviews
  for each row execute function public.recompute_rating();

-- 4e. set_deal_total() — total_price = quantity × price_per_pallet.
create or replace function public.set_deal_total()
returns trigger
language plpgsql
as $$
begin
  new.total_price := coalesce(new.quantity, 0) * coalesce(new.price_per_pallet, 0);
  return new;
end;
$$;

drop trigger if exists trg_set_deal_total on public.deals;
create trigger trg_set_deal_total
  before insert or update on public.deals
  for each row execute function public.set_deal_total();

-- 4f. deal transition (BEFORE) — stamp completed_at on completion.
create or replace function public.handle_deal_before()
returns trigger
language plpgsql
as $$
begin
  if new.deal_status = 'completed'
     and old.deal_status is distinct from 'completed'
     and new.completed_at is null then
    new.completed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_deal_before on public.deals;
create trigger trg_deal_before
  before update on public.deals
  for each row
  when (new.deal_status is distinct from old.deal_status)
  execute function public.handle_deal_before();

-- 4g. deal transition (AFTER) — reserve-on-accept inventory (BRAIN §7):
--     → accepted   : decrement listing.quantity_available by deal.quantity
--                    (floor 0 → status sold_out).
--     accepted → cancelled/declined : restore quantity (sold_out → active).
create or replace function public.handle_deal_inventory()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.deal_status = 'accepted' and old.deal_status is distinct from 'accepted' then
    update public.listings
       set quantity_available = greatest(quantity_available - new.quantity, 0)
     where id = new.listing_id;
    update public.listings
       set status = 'sold_out'
     where id = new.listing_id and quantity_available = 0 and status = 'active';

  elsif old.deal_status = 'accepted' and new.deal_status in ('cancelled', 'declined') then
    update public.listings
       set quantity_available = quantity_available + new.quantity
     where id = new.listing_id;
    update public.listings
       set status = 'active'
     where id = new.listing_id and status = 'sold_out';
  end if;
  return null;
end;
$$;

drop trigger if exists trg_deal_inventory on public.deals;
create trigger trg_deal_inventory
  after update on public.deals
  for each row
  when (new.deal_status is distinct from old.deal_status)
  execute function public.handle_deal_inventory();


-- ============================================================================
-- 5. ROW-LEVEL SECURITY  (BRAIN §6 RLS)
-- ============================================================================
alter table public.profiles   enable row level security;
alter table public.listings   enable row level security;
alter table public.requests   enable row level security;
alter table public.deals      enable row level security;
alter table public.messages   enable row level security;
alter table public.reviews    enable row level security;
alter table public.reports    enable row level security;
alter table public.deliveries enable row level security;

-- profiles: public business info readable; owner writes own row; privileged
-- columns are protected by the trigger above; admin can do anything.
drop policy if exists profiles_select_public on public.profiles;
create policy profiles_select_public on public.profiles
  for select using (true);

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- listings: public marketplace = active; owner sees/manages own (any status);
-- admin all.
drop policy if exists listings_select on public.listings;
create policy listings_select on public.listings
  for select using (
    status = 'active' or seller_id = auth.uid() or public.is_admin()
  );

drop policy if exists listings_insert_own on public.listings;
create policy listings_insert_own on public.listings
  for insert with check (seller_id = auth.uid());

drop policy if exists listings_update_own on public.listings;
create policy listings_update_own on public.listings
  for update using (seller_id = auth.uid() or public.is_admin())
  with check (seller_id = auth.uid() or public.is_admin());

drop policy if exists listings_delete_own on public.listings;
create policy listings_delete_own on public.listings
  for delete using (seller_id = auth.uid() or public.is_admin());

-- requests: buyer or the targeted seller (or admin).
drop policy if exists requests_select on public.requests;
create policy requests_select on public.requests
  for select using (
    buyer_id = auth.uid() or target_seller_id = auth.uid() or public.is_admin()
  );

drop policy if exists requests_insert_own on public.requests;
create policy requests_insert_own on public.requests
  for insert with check (buyer_id = auth.uid());

drop policy if exists requests_update on public.requests;
create policy requests_update on public.requests
  for update using (buyer_id = auth.uid() or public.is_admin())
  with check (buyer_id = auth.uid() or public.is_admin());

-- deals: only the involved parties (buyer/seller/driver); admin all.
drop policy if exists deals_select on public.deals;
create policy deals_select on public.deals
  for select using (
    buyer_id = auth.uid() or seller_id = auth.uid()
    or driver_id = auth.uid() or public.is_admin()
  );

drop policy if exists deals_insert on public.deals;
create policy deals_insert on public.deals
  for insert with check (
    buyer_id = auth.uid() or seller_id = auth.uid()
  );

drop policy if exists deals_update on public.deals;
create policy deals_update on public.deals
  for update using (
    buyer_id = auth.uid() or seller_id = auth.uid()
    or driver_id = auth.uid() or public.is_admin()
  ) with check (
    buyer_id = auth.uid() or seller_id = auth.uid()
    or driver_id = auth.uid() or public.is_admin()
  );

-- messages: only sender or receiver (or admin).
drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages
  for select using (
    sender_id = auth.uid() or receiver_id = auth.uid() or public.is_admin()
  );

drop policy if exists messages_insert on public.messages;
create policy messages_insert on public.messages
  for insert with check (sender_id = auth.uid());

drop policy if exists messages_update on public.messages;
create policy messages_update on public.messages
  for update using (
    -- receiver marks read; either party (or admin) may update their thread
    sender_id = auth.uid() or receiver_id = auth.uid() or public.is_admin()
  ) with check (
    sender_id = auth.uid() or receiver_id = auth.uid() or public.is_admin()
  );

-- reviews: readable/writable by the involved parties (or admin).
drop policy if exists reviews_select on public.reviews;
create policy reviews_select on public.reviews
  for select using (
    reviewer_id = auth.uid() or reviewed_user_id = auth.uid() or public.is_admin()
  );

drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews
  for insert with check (reviewer_id = auth.uid());

-- reports: any authenticated user may file; only admins read/resolve.
drop policy if exists reports_insert on public.reports;
create policy reports_insert on public.reports
  for insert with check (reported_by = auth.uid());

drop policy if exists reports_select_admin on public.reports;
create policy reports_select_admin on public.reports
  for select using (public.is_admin());

drop policy if exists reports_update_admin on public.reports;
create policy reports_update_admin on public.reports
  for update using (public.is_admin()) with check (public.is_admin());

-- deliveries: the assigned driver + the deal's buyer/seller (+ admin) can see.
-- Approved drivers can see UNCLAIMED jobs and claim one (set driver_id = self).
drop policy if exists deliveries_select on public.deliveries;
create policy deliveries_select on public.deliveries
  for select using (
    driver_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.deals d
      where d.id = deliveries.deal_id
        and (d.buyer_id = auth.uid() or d.seller_id = auth.uid())
    )
    or (
      driver_id is null and exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
          and p.account_type = 'driver'
          and p.driver_approved
      )
    )
  );

drop policy if exists deliveries_insert on public.deliveries;
create policy deliveries_insert on public.deliveries
  for insert with check (
    public.is_admin()
    or exists (
      select 1 from public.deals d
      where d.id = deliveries.deal_id and d.seller_id = auth.uid()
    )
  );

drop policy if exists deliveries_update on public.deliveries;
create policy deliveries_update on public.deliveries
  for update using (
    driver_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.deals d
      where d.id = deliveries.deal_id
        and (d.buyer_id = auth.uid() or d.seller_id = auth.uid())
    )
    or (
      -- an approved driver claiming an open job
      driver_id is null and exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
          and p.account_type = 'driver'
          and p.driver_approved
      )
    )
  ) with check (
    driver_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.deals d
      where d.id = deliveries.deal_id
        and (d.buyer_id = auth.uid() or d.seller_id = auth.uid())
    )
  );


-- ============================================================================
-- 6. GRANTS
-- ============================================================================
-- RLS is the real gate; these grants let the API roles reach the tables.
grant usage on schema public to anon, authenticated;

-- Guest browse: active listings + public business profiles.
grant select on public.profiles, public.listings to anon;

-- Authenticated users operate through the policies above.
grant select, insert, update, delete on
  public.profiles, public.listings, public.requests, public.deals,
  public.messages, public.reviews, public.reports, public.deliveries
  to authenticated;

-- ============================================================================
-- End of schema.
-- ============================================================================
