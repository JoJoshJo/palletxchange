# PalletXchange — BRAIN (Architecture & Build Spec)

**Master source of truth. Read this fully at the start of every session before writing any code.**

**Workflow:** Claude (architect) maintains this brain → Claude Code (executor) builds from it → J tests on device + operates dashboards.

**STANDING RULE — every Claude Code session opens with `pwd && git remote -v`** to confirm you are in the PalletXchange repo. The shell defaults to `findmcar`. **Never write code until the remote shows `palletxchange`.**

**Repo:** `git@github.com:JoJoshJo/palletxchange.git`

---

## 1. Product

PalletXchange is a **mobile-first B2B marketplace** (iOS + Android) where businesses buy, sell, and move pallets. Warehouses sit on surplus pallets while nearby businesses need them; PalletXchange connects them, opens the deal, and coordinates pickup or delivery. Trust comes from verified businesses + ratings.

This is a **full product — no MVP cuts, no v1/v2 descoping.** The build *sequence* below orders the work; nothing is dropped.

---

## 2. What we're rebuilding (context)

A prior **Base44 web prototype exists but is throwaway**: `localStorage` only, no backend, no real auth, all data faked, single-browser. **We are NOT migrating it.** We build a real backend + native app and do correctly what it faked. Its field names and flows are reused where noted below.

**Gaps in the prototype the build MUST fix:**
1. Real persistence + multi-user + realtime (was single-browser localStorage)
2. **One identity system** — the authenticated user *is* the app user; role lives on their profile (was two disconnected user systems + a demo role switcher)
3. **Row-Level Security** — users see only what they're allowed to (was: everyone saw all data)
4. **Enums + validation enforced at the DB layer** (was: enforced only by UI dropdowns)
5. `deals.completed_at` written on completion (was: never set)
6. `messages.read_status` updated on read (was: permanently false)
7. `profiles.rating` recalculated from reviews (was: static seed)
8. "Report" actually inserts a report (was: a toast, no record)
9. Photos actually uploaded to storage from the camera (was: dead button + hardcoded URLs)
10. Notifications actually sent (was: fake "notify nearby sellers" checkbox)
11. Inventory change is atomic/server-side (was: client-side, oversell-prone)
12. Owners can edit/delete/toggle their own listings (was: only admin could remove)

---

## 3. Stack

- **Client:** Flutter (single codebase, iOS + Android)
- **State:** Riverpod · **Routing/deep links:** go_router
- **Backend:** Supabase — Postgres, Auth, Storage, Realtime, Edge Functions
- **Distance:** PostGIS (or `earthdistance`) for radius search
- **Security:** RLS on every table
- **Push:** FCM (`firebase_messaging`), triggered from Supabase DB webhooks / Edge Functions
- **Auth:** email/password + Google

---

## 4. Accounts & actors

**Sign up → choose one: Individual, Warehouse, or Driver.**

- **Individual & Warehouse = TRADERS.** Both post to sell *and* browse to buy — same screens. Warehouse additionally gets the verified-business badge, **bulk upload**, and inventory/analytics tools.
- **Driver = SERVICE account.** No marketplace; lands on a **job board** of delivery gigs.
- **Admin = GRANTED privilege**, never a signup choice. Flagged on an account after the fact (`is_admin`). Oversight panel: verify businesses, remove listings, resolve reports.

**Recyclable is NOT an actor** — it's a listing *condition* (Damaged / Scrap) surfaced through a marketplace filter.

---

## 5. Core flow & interactions

**One loop:** List/Request → Discover → Request Deal → Accept → Hand Off → Complete.

- **Found what you need** → open the listing → **Request Deal** (a thread opens).
- **Didn't find it** → **Special Request** — broadcast to the market, *or* targeted to one seller's profile (that seller clearly deals in it but hasn't posted it) → a thread opens.
- **Threads open only from a deal or a request — no bare DMs.** After that, free chat.

**Deal states:** `pending → accepted → completed`. Exit: `cancelled / declined` (the only branch). Disputes = the Report button, not a state.

**Delivery:** pickup, or delivery + **optional Driver** (posts the leg to the job board).

**Interactions:** Trader ↔ Trader = the deal (chat, accept, complete, rate). Driver attaches to a delivery deal at hand-off (sees pickup + drop-off addresses, never negotiates). Admin acts on data, transacts with no one.

---

## 6. Data model

In Supabase, `auth.users` holds credentials; app data hangs off a `profiles` row whose `id` = auth UID. Reuse the prototype's field names for continuity.

### Enums
```
account_type:     individual | warehouse | driver         (signup picks one; admin is a separate flag)
pallet_type:      Standard wooden pallets | Heat-treated pallets | Plastic pallets |
                  Euro pallets | Stringer pallets | Block pallets |
                  Custom-size pallets | Broken or recyclable pallets
pallet_condition: New | Like new | Used, good condition | Used, repairable | Damaged | Scrap/recycling only
pallet_size:      48 x 40 | 42 x 42 | 48 x 48 | 36 x 36 | Euro pallet | Custom size
listing_status:   active | unavailable | sold_out | archived
request_status:   open | matched | closed | cancelled
deal_status:      pending | accepted | completed | cancelled | declined
payment_status:   not_required | unpaid | paid
delivery_status:  requested | accepted | driver_assigned | picked_up | in_transit | delivered | completed | cancelled
report_status:    open | resolved
```

### Tables (field : type — notes)

**profiles** (id = auth UID)
`id` uuid PK · `name` · `email` · `phone` · `business_name` · `account_type` enum · `is_admin` bool (default false, granted) · `address/city/state/zip` · `latitude/longitude` double · `verified_status` bool (default false) · `rating` numeric **(computed from reviews)** · `created_at`.

**listings**
`id` uuid PK · `seller_id` → profiles · `title` · `pallet_type` enum · `pallet_size` enum · `condition` enum · `quantity_available` int · `min_order_quantity` int (default 1) · `price_per_pallet` numeric · `is_free` bool · `exchange_allowed` bool · `pickup_available` bool · `delivery_available` bool · `address/city/state/zip` · `latitude/longitude` double · `loading_dock_available` bool · `forklift_available` bool · `stackable` bool · `photos` text[] **(Storage URLs)** · `notes` · `status` enum (default active) · `unavailable_since` timestamptz null **(drives 24h auto-archive)** · `expires_at` timestamptz · `created_at`.

**requests** (a buyer's need; = Special Request)
`id` uuid PK · `buyer_id` → profiles · `target_seller_id` → profiles **null (null = broadcast to market; set = special request to one seller)** · `pallet_type_needed` enum · `pallet_size_needed` enum · `quantity_needed` int · `preferred_condition` enum · `max_price` numeric null · `pickup_or_delivery` (pickup|delivery) · `needed_by_date` date · `location` · `notes` · `status` enum (default open) · `created_at`.

**deals** (was `transactions`)
`id` uuid PK · `listing_id` → listings · `buyer_id` → profiles · `seller_id` → profiles · `driver_id` → profiles null · `quantity` int · `price_per_pallet` numeric · `total_price` numeric **(= quantity × price_per_pallet)** · `fulfillment_method` (pickup|delivery) · `delivery_address` null · `delivery_fee` numeric (default 0, seller-quoted) · `payment_status` enum · `deal_status` enum (default pending) · `pickup_time` timestamptz null · `completed_at` timestamptz null **(set on completion)** · `notes` · `created_at`.

**messages**
`id` uuid PK · `conversation_id` · `sender_id` → profiles · `receiver_id` → profiles · `listing_id` → listings null · `deal_id` → deals null · `request_id` → requests null **(thread ties to whichever started it)** · `body` · `read_status` bool (default false) · `created_at`.

**reviews**
`id` uuid PK · `deal_id` → deals · `reviewer_id` → profiles · `reviewed_user_id` → profiles · `rating` int(1–5) · `communication_rating` int · `accuracy_rating` int · `delivery_rating` int · `review_text` · `created_at`.

**reports**
`id` uuid PK · `reported_by` → profiles · `reported_user` → profiles null · `listing_id` null · `deal_id` null · `reason` · `description` · `status` enum · `admin_notes` · `created_at`.

**deliveries** (driver job board)
`id` uuid PK · `deal_id` → deals · `driver_id` → profiles null · `pickup_address` · `dropoff_address` · `pickup_time` / `delivery_time` timestamptz null · `delivery_status` enum · `proof_of_pickup` / `proof_of_delivery` text (Storage URLs) · `delivery_notes` · `created_at`.

### Triggers / server-side functions
- **Rating recalc:** on insert/update/delete of `reviews`, recompute `profiles.rating` (avg) for the reviewed user.
- **Inventory (reserve-on-accept — atomic DB function):**
  - `pending` → no inventory change (multiple buyers may have pending deals on one listing).
  - → `accepted`: decrement `listings.quantity_available` by `deal.quantity`; if it hits 0 → `status = sold_out`.
  - → `completed`: set `completed_at = now()` (quantity already reserved at accept).
  - accepted → `cancelled`/`declined`: restore `quantity_available` by `deal.quantity` (if it was `sold_out`, back to `active`).
- **Unavailable auto-archive (scheduled — pg_cron / Edge Function):** set `status = archived` where `status = unavailable` AND `unavailable_since < now() - 24h` AND no attached deal is `pending`/`accepted`.

### RLS
- `listings`: `SELECT` for anyone where `status = active` (public marketplace); full manage where `seller_id = auth.uid()`; admin bypass.
- `deals` / `messages`: visible only to involved parties (`buyer_id`, `seller_id`, `driver_id` / `sender_id`, `receiver_id`).
- `profiles`: public business fields readable; writable by owner; `verified_status` and `is_admin` settable only by admin/service role.
- `reports`: insert by any authed user; read/resolve by admin.

---

## 7. Business logic to port

**Smart matching (request → listings), max score 12:** `type == type_needed` +3 · `size == size_needed` +3 · `quantity_available >= quantity_needed` +2 · `condition == preferred_condition` +2 · `max_price` set & `price <= max_price` +2 · delivery pref & `delivery_available` +1 · pickup pref & `pickup_available` +1. Return score > 0, sorted desc. (Build as a Supabase RPC/Edge Function so match-on-new-request and match-on-new-listing reuse it.)

**Distance:** PostGIS/`earthdistance` server-side; filter marketplace by radius (10/25/50/100 mi) from the user's lat/lon.

**Deal state machine:** `pending → accepted | declined`; `accepted → completed` (triggers inventory + `completed_at`); any non-terminal → `cancelled`.

**Review eligibility:** allowed only when `deal_status = completed` AND no existing review by this `reviewer_id` for this `deal_id`. Reviewed user = the other party.

**Availability rule:** seller sets a listing **Active / Unavailable / Remove**. Unavailable → hidden from marketplace + storefront immediately, restorable, with a 24h countdown; after 24h → auto-archived (re-listable), unless an active deal is attached. Remove → archived immediately. Nothing tied to a live deal disappears.

**Pricing (off-platform):** `total_price = quantity × price_per_pallet`. `payment_status = not_required` if free, else `unpaid`. Money is settled off-platform; parties mark `paid`. No processing.

**Marketplace filters:** search (title/city/state/type) · type · size · condition · recyclable (condition = Damaged/Scrap) · free-only · delivery-only · max price · distance radius. Only `status = active` shown.

---

## 8. Screens (mobile-first, all actors)

**Auth & onboarding:** sign up (email+password + Google) → choose Individual/Warehouse/Driver → create profile. Login · password reset · **in-app account deletion (store-required)**.

**Trader (Individual + Warehouse):**
- **Marketplace/Browse** — location + filters; cards: photo, price, condition grade, qty, seller name + ✓verified + ★rating, distance, pickup/delivery.
- **Listing detail** — hierarchy: photos → price → seller ✓rating → spec grid → sticky **Request Deal** / Message. Exact address gated until a deal exists.
- **Create/Edit listing** — full form + **camera/gallery photo upload**; availability toggle (Active/Unavailable/Remove); prefill address from profile; group into sections (Pallet → Location → Options → Photos).
- **Storefront profile** — business header (✓badge, rating) + that account's **active listings** + **Special Request** button.
- **Special Request** — request form, broadcast or targeted to one seller; runs matching; opens a thread.
- **Deals** — buy side + sell side; detail with state actions (accept/decline/cancel/complete); seller enters delivery-fee quote for delivery deals.
- **Reviews** — after a completed deal (4 categories).
- **Messages** — realtime threads + read receipts.
- **Dashboard** — adaptive: **sell side** (my listings, incoming deals, revenue) + **buy side** (my deals, saved, requests).

**Warehouse extra:** **Bulk upload** (CSV/Excel, native file picker) + inventory tools. *(Bulk is a desktop-leaning workflow; a thin warehouse web companion is a likely later add.)*

**Driver:** **Job board** — open delivery jobs → accept → pickup + drop-off addresses → status (picked_up → in_transit → delivered) → **proof photos** → earnings.

**Admin:** panel — users, listings (remove), reports (resolve), verify businesses, analytics.

**Shared:** notifications, settings, edit profile, **block/report user**, account deletion.

---

## 9. Mobile-native

- **Camera + Storage:** listing photos, driver proof-of-pickup/delivery (`image_picker` → Supabase Storage).
- **Push (FCM):** new deal (→ seller), deal status change (→ buyer), new message, new match (→ trader), delivery update, review received, listing expiring. Fired from DB webhooks / Edge Functions.
- **Geolocation:** `geolocator` — autofill lat/lon, "pallets near me," driver pickup/drop-off hand-off to a maps app.
- **Deep links:** `/listing/:id`, `/deal/:id`, `/conversation/:id`, `/job/:id`.
- **Offline read cache** for low-signal loading docks; optional biometric login (`local_auth`).

---

## 10. Payment & revenue

**Off-platform payment.** The app matches parties, opens the deal, and records the agreed price + `payment_status` (unpaid/paid); the two businesses **settle themselves** (invoice / PO / cash on pickup). No Stripe, no held funds, no payouts. **Buyers never pay a fee.** This matches how pallet B2B actually pays and keeps Apple/Google out of the revenue.

**Revenue = CLIENT DECISION** (see Open Decisions). Monetize the **sell side later** — a completion fee (industry norm ~6% on completed deals) *or* a warehouse subscription. Billed separately; **not built yet.**

---

## 11. Design principles (all proven, from competitor + UX research)

- **Guest browse before login;** gate sensitive detail, not access (price + exact address revealed on registration / open deal).
- **Trust on the card:** verified badge + rating shown on the listing card, not just the profile.
- **Listing detail hierarchy:** photos → price → seller rating → specs → CTA.
- **Location-first search;** filters are the highest-ROI surface.
- **Condition grading** shown as a clear badge.
- **Delivery: quote before commit,** pickup free, then simple tracking.
- **Generous listing life** (long expiry, not days).
- **One primary action per screen;** big touch targets; single-column; skeleton, empty, and error states everywhere.
- **Brand:** dark navy (surfaces) · **orange** (the one primary action) · **green** (positive/verified) · white/slate content.

---

## 12. Build sequence (full product — order, not scope cut)

1. **Supabase** — enums → tables → RLS → triggers (rating, reserve-on-accept, unavailable auto-archive) → Storage buckets → email + Google auth.
2. **Flutter scaffold** — feature-first structure, Riverpod, go_router, Supabase client, theme (§11).
3. **Auth + onboarding** — sign up + Google; choose Individual/Warehouse/Driver; create profile; account deletion.
4. **Models + repositories** for every table.
5. **Trader sell** — create/edit listing + camera upload + availability toggle.
6. **Trader buy** — marketplace + filters + distance + listing detail + Request Deal (creates deal + auto message).
7. **Special Request + matching** (RPC/Edge Function).
8. **Deals** — state machine + reserve-on-accept inventory + reviews.
9. **Storefront profiles.**
10. **Messaging** — realtime + read receipts.
11. **Driver job board** — accept + status + proof photos + earnings.
12. **Admin panel** — users, listings, reports, verify, analytics.
13. **Push + deep links.**
14. **Legal/store gates** — privacy policy, ToS, finalize account deletion.

---

## 13. Open decisions

**Client business calls (questionnaire):**
1. Revenue model — seller completion fee vs. warehouse subscription vs. featured listings vs. free-to-grow.
2. Verification — how a business earns the badge, who approves, what proof (EIN/license), limits on unverified.
3. Disputes — who resolves a deal gone wrong; mediator or report-only.
4. Launch market — one city (Atlanta) or nationwide; how first supply is seeded.
5. Driver pay + vetting — who pays the delivery fee; license/insurance required; job claim first-come or auto-assign.
6. Compliance — ISPM-15 / heat-treated (export) flag needed?
7. Notifications — push only, or email too.

**Architect defaults applied now (override anytime):**
- **Quantity reserved on Accept**, not Pending (multiple buyers may hold pending deals; seller chooses; stock commits on accept).
- **Unavailable auto-archives after 24h → re-listable, never hard-deleted;** hidden from market + storefront immediately; auto-archive skipped if an active deal is attached.

**Store-required regardless of client input:** in-app account deletion, privacy policy, Terms of Service.
