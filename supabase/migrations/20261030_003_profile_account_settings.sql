-- Profile preferences and user-managed account operations.
-- Apply with `supabase db push` before shipping these profile screens.

alter table public.profiles
  add column if not exists preferred_currency char(3) not null default 'INR',
  add column if not exists preferred_language text not null default 'English (EN)',
  add column if not exists theme_preference text not null default 'light'
    check (theme_preference in ('light', 'dark', 'system')),
  add column if not exists security_method text not null default 'pin'
    check (security_method in ('pin', 'biometric')),
  add column if not exists expense_alerts_enabled boolean not null default true,
  add column if not exists budget_alerts_enabled boolean not null default true,
  add column if not exists tips_enabled boolean not null default false;

-- The auth trigger normally creates this row. This policy also lets the app
-- recover gracefully for users created before that trigger was installed.
create policy "profiles: owner can insert" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);

create policy "accounts: owner can insert" on public.finance_accounts
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "accounts: owner can update" on public.finance_accounts
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "accounts: owner can delete" on public.finance_accounts
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy "transactions: owner can insert" on public.finance_transactions
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "transactions: owner can update" on public.finance_transactions
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "transactions: owner can delete" on public.finance_transactions
  for delete to authenticated using ((select auth.uid()) = user_id);
