-- ============================================================================
-- PalletXchange — in-app notifications (feed + auto-create triggers)
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- This is the in-app feed; push delivery (FCM) is layered on later. Rows are
-- inserted by SECURITY DEFINER triggers so they can target the recipient under
-- RLS. Contains NO secrets.
-- ============================================================================

-- 1) Table
create table if not exists public.notifications (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  type            text not null,
  title           text not null,
  body            text,
  deal_id         uuid references public.deals(id) on delete set null,
  request_id      uuid references public.requests(id) on delete set null,
  conversation_id text,
  read            boolean not null default false,
  created_at      timestamptz not null default now()
);

create index if not exists idx_notifications_user
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

-- 2) RLS: a user sees + marks read only their own; inserts come from triggers.
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, update on public.notifications to authenticated;

-- Helper: display name for a profile (business name for warehouses, else name).
create or replace function public.notify_display_name(p_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    nullif(case when account_type = 'warehouse' then business_name else name end, ''),
    nullif(name, ''),
    'Someone')
  from public.profiles where id = p_id;
$$;

-- 3a) New deal → notify the SELLER (deal_requested).
create or replace function public.on_deal_insert_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  buyer_name text := public.notify_display_name(new.buyer_id);
begin
  insert into public.notifications (user_id, type, title, body, deal_id)
  values (new.seller_id, 'deal_requested', 'New deal request',
          buyer_name || ' requested ' || new.quantity || ' pallet(s).', new.id);
  return new;
end;
$$;

drop trigger if exists trg_notify_deal_insert on public.deals;
create trigger trg_notify_deal_insert
  after insert on public.deals
  for each row execute function public.on_deal_insert_notify();

-- 3b) Deal status change → accepted (→buyer), completed (→other party),
--     declined/cancelled (→ the other party).
create or replace function public.on_deal_status_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.deal_status = old.deal_status then
    return new;
  end if;

  if new.deal_status = 'accepted' then
    insert into public.notifications (user_id, type, title, body, deal_id)
    values (new.buyer_id, 'deal_accepted', 'Deal accepted',
            public.notify_display_name(new.seller_id) || ' accepted your deal.',
            new.id);

  elsif new.deal_status = 'completed' then
    -- notify both parties
    insert into public.notifications (user_id, type, title, body, deal_id)
    values (new.buyer_id, 'deal_completed', 'Deal completed',
            'Your deal is complete. Leave a review!', new.id),
           (new.seller_id, 'deal_completed', 'Deal completed',
            'Your deal is complete. Leave a review!', new.id);

  elsif new.deal_status in ('declined', 'cancelled') then
    -- notify the party who didn't trigger it isn't known; notify buyer + seller
    insert into public.notifications (user_id, type, title, body, deal_id)
    values (new.buyer_id, 'deal_update',
            'Deal ' || new.deal_status, 'A deal was ' || new.deal_status || '.', new.id),
           (new.seller_id, 'deal_update',
            'Deal ' || new.deal_status, 'A deal was ' || new.deal_status || '.', new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_deal_status on public.deals;
create trigger trg_notify_deal_status
  after update on public.deals
  for each row
  when (new.deal_status is distinct from old.deal_status)
  execute function public.on_deal_status_notify();

-- 3c) New message → notify the RECEIVER (new_message).
create or replace function public.on_message_insert_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications
    (user_id, type, title, body, deal_id, request_id, conversation_id)
  values (new.receiver_id, 'new_message',
          'New message from ' || public.notify_display_name(new.sender_id),
          left(new.body, 120), new.deal_id, new.request_id, new.conversation_id);
  return new;
end;
$$;

drop trigger if exists trg_notify_message_insert on public.messages;
create trigger trg_notify_message_insert
  after insert on public.messages
  for each row execute function public.on_message_insert_notify();

-- 3d) New review → notify the reviewed user (review_received).
create or replace function public.on_review_insert_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, type, title, body, deal_id)
  values (new.reviewed_user_id, 'review_received', 'New review',
          public.notify_display_name(new.reviewer_id) || ' left you a '
            || new.rating || '★ review.', new.deal_id);
  return new;
end;
$$;

drop trigger if exists trg_notify_review_insert on public.reviews;
create trigger trg_notify_review_insert
  after insert on public.reviews
  for each row execute function public.on_review_insert_notify();

-- ============================================================================
-- End.
-- ============================================================================
