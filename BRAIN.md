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

- **Individual & Warehouse = TRADERS.** Both **buy and sell freely** — same screens, no gate. **Anyone can list to sell immediately; there is NO "verify before selling" requirement** (this supersedes any earlier "must be verified before listing" note). Warehouse additionally gets **bulk upload** and inventory/analytics tools.
- **Driver = SERVICE account.** Job board **only** — a driver **cannot buy or sell** on the marketplace.
- **Admin = GRANTED privilege**, never a signup choice. Flagged on an account after the fact (`is_admin`). Oversight panel: verify businesses, remove listings, resolve reports.

**Verification (`verified_status` ✓) is a TRUST BADGE only** — it is *never* a gate on listing, buying, or selling. It signals trust on the card/storefront; it grants no permission.

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
`id` uuid PK · `name` · `email` · `phone` · `business_name` · `account_type` enum · `is_admin` bool (default false, granted) · `address/city/state/zip` · `latitude/longitude` double · `verified_status` bool (default false) **(trust badge only — never a gate)** · `rating` numeric **(computed from reviews)** · `created_at`.
- **Driver vetting fields** (used only when `account_type = driver`): `driver_license_url` text null · `driver_insurance_url` text null (Storage URLs) · `driver_approved` bool (default false). **A driver must submit license + insurance and be `driver_approved` by an admin before they can CLAIM any job.** Unapproved drivers may see the job board but cannot claim.

**listings**
`id` uuid PK · `seller_id` → profiles · `title` · `pallet_type` enum · `pallet_size` enum · `condition` enum · `quantity_available` int · `min_order_quantity` int (default 1) · `price_per_pallet` numeric · `is_free` bool · `exchange_allowed` bool · `pickup_available` bool · `delivery_available` bool · `address/city/state/zip` · `latitude/longitude` double · `loading_dock_available` bool · `forklift_available` bool · `stackable` bool · `photos` text[] **(Storage URLs)** · `notes` · `status` enum (default active) · `unavailable_since` timestamptz null **(drives 24h auto-archive)** · `expires_at` timestamptz · `created_at`.

**requests** (a buyer's need; = Special Request)
`id` uuid PK · `buyer_id` → profiles · `target_seller_id` → profiles **null (null = broadcast to market; set = special request to one seller)** · `pallet_type_needed` enum · `pallet_size_needed` enum · `quantity_needed` int · `preferred_condition` enum · `max_price` numeric null · `pickup_or_delivery` (pickup|delivery) · `needed_by_date` date · `location` · `notes` · `status` enum (default open) · `created_at`.

**deals** (was `transactions`)
`id` uuid PK · `listing_id` → listings · `buyer_id` → profiles · `seller_id` → profiles · `driver_id` → profiles null · `quantity` int · `price_per_pallet` numeric · `total_price` numeric **(= quantity × price_per_pallet)** · `fulfillment_method` (pickup|delivery) · `delivery_address` null · `delivery_fee` numeric (default 0, seller-quoted) · `delivery_paid_by` (buyer|seller) — **who pays the delivery fee, DECIDED PER DEAL (buyer or seller), not a global rule; null until set** · `payment_status` enum · `deal_status` enum (default pending) · `pickup_time` timestamptz null · `completed_at` timestamptz null **(set on completion)** · `notes` · `created_at`.

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

**Pricing:** `total_price = quantity × price_per_pallet`. `payment_status = not_required` if free, else `unpaid`; parties mark `paid`. The app **records** the agreed price + payment status — **how money actually moves is PARKED (see §10)**. No payment processing built now.

**Delivery fee payer:** `delivery_paid_by` is chosen **per deal** (buyer or seller), set on the deal — there is no fixed global rule.

**Driver job assignment:** **first-come "claim"** model at launch — any *approved* driver claims an open job. *(Closest-driver auto-assign is a LATER enhancement.)* A driver must be `driver_approved` (license + insurance on file, admin-approved) before claiming.

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

**Driver:** **Job board (service account only — no buy/sell)** — **onboarding: submit license + insurance, await admin approval (`driver_approved`) before claiming.** Then: open delivery jobs → **claim (first-come)** → pickup + drop-off addresses → status (picked_up → in_transit → delivered) → **proof photos** → earnings.

**Admin:** panel — users, listings (remove), reports (resolve → warn/remove/ban), **verify businesses (badge)**, **approve drivers (license/insurance)**, analytics.

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

**Payment mechanism = PARKED / undecided.** The app **records** the agreed price + a `payment_status` (unpaid/paid) on each deal, and parties mark it paid. **HOW money actually moves — off-platform (invoice / PO / cash on pickup) vs. in-app card vs. both — is an OPEN decision to revisit later.** **Do NOT build any payment processing now (no Stripe, no held funds, no payouts).** Structure the data so a payment method can slot in later without a schema rewrite.

**Revenue = FREE at launch.** No fees, no subscriptions, no boosted/featured listings are built now. **Structure data so they can slot in later** — the following are **FUTURE, not launch:** a **seller completion fee** (industry norm ~6% on completed deals), a **warehouse subscription**, and **featured listings**. Any monetization lands on the **sell side**; buyers are not the target of fees.

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

**LOCKED decisions (were client business calls):**
1. **Revenue — FREE at launch.** No fees/subscriptions/featured listings built now; seller completion fee, warehouse subscription, and featured listings are FUTURE (structure data to slot them in). See §10.
2. **Verification — TRUST BADGE ONLY.** `verified_status` ✓ never gates listing/buying/selling; anyone can sell immediately. How a business earns the badge (proof/approver) is admin-granted oversight. See §4.
3. **Disputes — report → admin review → warn / remove / ban.** Report-only surface for users; admins act. See §5, §8.
4. **Launch market — NATIONWIDE** (supersedes "one city / Atlanta only"). Not geo-restricted; seed/demo data stays Atlanta-flavored but the product is national. How first supply is seeded is an ops task, not a product gate.
5. **Driver vetting — license + insurance required, admin-approved before claiming** (`driver_approved`). **Job assignment — first-come claim at launch;** closest-driver auto-assign is a LATER enhancement. **Delivery fee payer — decided PER DEAL** (`delivery_paid_by` buyer|seller). See §4, §6, §7.
6. **Payment mechanism — PARKED / undecided.** Record price + `payment_status` only; build no processing now. See §10.

**Still open (revisit):**
- Compliance — ISPM-15 / heat-treated (export) flag needed?
- Notifications — push only, or email too.

**Architect defaults applied now (override anytime):**
- **Quantity reserved on Accept**, not Pending (multiple buyers may hold pending deals; seller chooses; stock commits on accept).
- **Unavailable auto-archives after 24h → re-listable, never hard-deleted;** hidden from market + storefront immediately; auto-archive skipped if an active deal is attached.

**Store-required regardless of client input:** in-app account deletion, privacy policy, Terms of Service.

---

## 14. Security & Standards (checked every milestone)

The bar every backend milestone clears before moving on. Sized for a B2B marketplace — safe, not bloated.

### Must-have (non-negotiable)
- RLS enabled on every table, **verified by test** (not assumed): an unauthorized request must actually be blocked.
- No secrets in the repo, ever — API keys/tokens in a gitignored env file; the `service_role` key never ships in the app.
- Critical rules enforced server-side (DB/policies), not just UI: no overselling inventory; no acting on another user's deal/listing; privileged columns (`verified_status`, `is_admin`, `driver_approved`) writable only by an admin.
- Auth required for every real (write) action; email confirmation on.
- Inputs validated; user input never concatenated into raw SQL (use the client/parameterized queries).
- Driver must be approved (license + insurance) before claiming a job.
- App-store gates before launch: in-app account deletion, privacy policy, terms of service.

### Deliberately NOT doing now (avoid over-engineering)
- No custom crypto or exotic auth — Supabase Auth is sufficient.
- No payment processing (parked).
- No premature scaling infra (custom rate-limit layers, CDNs, sharding) before there are users.
- No feature not on the decided list.

### Per-milestone security gate (run at the end of each backend milestone)
1. Prove RLS blocks a wrong/anonymous request (anon cannot read deals/messages; cannot write listings).
2. Confirm no secret was committed (env file gitignored; history clean).
3. Confirm the milestone's critical server-side rule holds (e.g. inventory can't go negative).
Record anything deferred in the list below, with a reason.

### Deferred (with reason) — keep current
- **Server-side radius/distance filtering** — DONE: `supabase/geo.sql` (`listings_within_radius` RPC on cube/earthdistance). Marketplace calls it paged (nearest-first, distance attached) with a client-side Haversine fallback.
- **Pagination / infinite scroll** — DONE: marketplace + admin all-rows lists paginate with infinite scroll (`PagedNotifier`); per-user lists (deals, chat, thread messages) are bounded (100/50/100). Conversation list N+1 batched. Remaining: infinite scroll for per-user lists if a single user ever exceeds the bounds (unlikely near-term).
- **Email-confirmation deep link into the app** — deferred: UX polish; bundle it with push-notification deep links (`/listing/:id`, `/deal/:id`, etc.) in the notifications milestone. Today confirmation (when on) is handled via the email link + manual log in.
- **Authenticated cross-user RLS test** — deferred: pending the first confirmed users. Anon-level RLS is verified (anon cannot read deals/messages or write listings); the user-vs-user check (user A cannot read user B's deals) runs once two real accounts exist.
- **Matching as a server-side RPC** (BRAIN §7 scoring) — DONE: `supabase/matching.sql` (`match_listings_for_request`); app calls it via `supabase.rpc` with a client-side fallback.
- **Unavailable → 24h auto-archive job** — DONE: `supabase/jobs.sql` (`set_unavailable_since` trigger + `archive_stale_unavailable()` function, scheduled hourly via pg_cron when available).
- **Storage bucket RLS policies** (listing-photos public-read; driver-docs + delivery-proof private, owner/party/admin only) — deferred: written when camera/upload flows land (photos, driver docs, delivery proof).
- **Google OAuth provider** — deferred: email/password shipped first; Google enabled when its Cloud OAuth client is configured.
- **App-store gates** (in-app account deletion action, privacy policy, ToS) — deferred: pre-launch milestone (§12.14).
- **Push notifications (FCM) + DB webhooks/Edge Functions** — deferred: notifications milestone (§9, §12.13).
- **Post-acceptance quantity change (renegotiation)** — deferred; only pending-stage quantity edits are supported. Changing quantity after accept would require re-reservation/renegotiation of inventory, which is out of scope for now.
