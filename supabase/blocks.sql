-- ============================================================================
-- PalletXchange — user blocks (trust & safety)
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- A block is one-directional and private to the blocker. Contains NO secrets.
-- ============================================================================

create table if not exists public.blocks (
  id         uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint blocks_unique unique (blocker_id, blocked_id)
);

create index if not exists idx_blocks_blocker on public.blocks (blocker_id);

alter table public.blocks enable row level security;

-- Only the blocker can see or manage their own block rows.
drop policy if exists blocks_select_own on public.blocks;
create policy blocks_select_own on public.blocks
  for select using (blocker_id = auth.uid());

drop policy if exists blocks_insert_own on public.blocks;
create policy blocks_insert_own on public.blocks
  for insert with check (blocker_id = auth.uid());

drop policy if exists blocks_delete_own on public.blocks;
create policy blocks_delete_own on public.blocks
  for delete using (blocker_id = auth.uid());

grant select, insert, delete on public.blocks to authenticated;

-- ============================================================================
-- End.
-- ============================================================================
