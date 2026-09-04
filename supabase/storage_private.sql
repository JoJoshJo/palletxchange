-- ============================================================================
-- PalletXchange — private bucket RLS + driver lifecycle RPCs
-- ============================================================================
-- HOW TO RUN: paste into Supabase → SQL Editor → Run. Safe to re-run.
-- Prereq: buckets 'driver-docs' and 'delivery-proof' exist (private), and
-- schema.sql (for public.is_admin()) has been run. Contains NO secrets.
--
-- Path conventions the app uses:
--   driver-docs:    {uid}/{license|insurance}/{file}
--   delivery-proof: {dealId}/{pickup|delivery}/{file}
-- so storage.foldername(name)[1] is the uid (driver-docs) or the deal id
-- (delivery-proof), which the policies below key off.
-- ============================================================================

-- ── driver-docs: owner writes; owner + admins read ──
drop policy if exists driver_docs_owner_insert on storage.objects;
create policy driver_docs_owner_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'driver-docs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists driver_docs_owner_update on storage.objects;
create policy driver_docs_owner_update on storage.objects
  for update to authenticated
  using (bucket_id = 'driver-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists driver_docs_owner_delete on storage.objects;
create policy driver_docs_owner_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'driver-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists driver_docs_read on storage.objects;
create policy driver_docs_read on storage.objects
  for select to authenticated
  using (bucket_id = 'driver-docs'
         and ((storage.foldername(name))[1] = auth.uid()::text
              or public.is_admin()));

-- ── delivery-proof: assigned driver writes; deal parties + admins read ──
drop policy if exists delivery_proof_driver_insert on storage.objects;
create policy delivery_proof_driver_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'delivery-proof'
    and exists (
      select 1 from public.deals d
      where d.id::text = (storage.foldername(name))[1]
        and d.driver_id = auth.uid()));

drop policy if exists delivery_proof_driver_update on storage.objects;
create policy delivery_proof_driver_update on storage.objects
  for update to authenticated
  using (bucket_id = 'delivery-proof'
    and exists (
      select 1 from public.deals d
      where d.id::text = (storage.foldername(name))[1]
        and d.driver_id = auth.uid()));

drop policy if exists delivery_proof_driver_delete on storage.objects;
create policy delivery_proof_driver_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'delivery-proof'
    and exists (
      select 1 from public.deals d
      where d.id::text = (storage.foldername(name))[1]
        and d.driver_id = auth.uid()));

drop policy if exists delivery_proof_read on storage.objects;
create policy delivery_proof_read on storage.objects
  for select to authenticated
  using (bucket_id = 'delivery-proof'
    and (public.is_admin()
      or exists (
        select 1 from public.deals d
        where d.id::text = (storage.foldername(name))[1]
          and (d.buyer_id = auth.uid()
               or d.seller_id = auth.uid()
               or d.driver_id = auth.uid()))));

-- ============================================================================
-- Driver lifecycle RPCs (SECURITY DEFINER so they can write privileged rows /
-- notifications under RLS). Requires the notifications table (notifications.sql).
-- ============================================================================

-- Admin approves/rejects a driver, and notifies them.
create or replace function public.admin_set_driver_approved(
  p_driver uuid, p_approved boolean, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only';
  end if;

  update public.profiles set driver_approved = p_approved where id = p_driver;

  insert into public.notifications (user_id, type, title, body)
  values (
    p_driver,
    case when p_approved then 'driver_approved' else 'driver_rejected' end,
    case when p_approved then 'You are approved to drive'
         else 'Driver application needs attention' end,
    case when p_approved then 'You can now claim delivery jobs.'
         else coalesce(p_reason, 'Please re-check your license and insurance.') end
  );
end;
$$;

grant execute on function public.admin_set_driver_approved(uuid, boolean, text)
  to authenticated;

-- Driver notifies the delivery requester that proof was uploaded.
-- Requester = buyer or seller depending on deals.delivery_paid_by (default buyer).
create or replace function public.notify_delivery_proof(
  p_deal uuid, p_kind text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.deals%rowtype;
  target uuid;
begin
  select * into d from public.deals where id = p_deal;
  if not found then
    return;
  end if;
  -- only the assigned driver may trigger this
  if d.driver_id is null or d.driver_id <> auth.uid() then
    raise exception 'not the assigned driver';
  end if;

  target := case when d.delivery_paid_by = 'seller' then d.seller_id
                 else d.buyer_id end;

  insert into public.notifications (user_id, type, title, body, deal_id)
  values (target, 'delivery_update', 'Delivery proof uploaded',
          'Driver uploaded ' || p_kind || ' proof.', p_deal);
end;
$$;

grant execute on function public.notify_delivery_proof(uuid, text)
  to authenticated;

-- ============================================================================
-- End.
-- ============================================================================
