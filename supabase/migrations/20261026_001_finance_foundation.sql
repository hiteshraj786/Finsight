-- FinSight: production foundation for local financial data.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finance_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_name text not null,
  masked_account_number text not null,
  account_type text not null check (account_type in ('savings', 'current', 'credit_card', 'loan', 'wallet', 'other')),
  currency char(3) not null default 'INR',
  latest_balance numeric(14,2),
  balance_updated_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider_name, masked_account_number, account_type)
);

create table if not exists public.finance_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid not null references public.finance_accounts(id) on delete cascade,
  provider_reference text,
  dedupe_hash text not null,
  amount numeric(14,2) not null check (amount > 0),
  direction text not null check (direction in ('debit', 'credit')),
  merchant text,
  category text,
  occurred_at timestamptz not null,
  source text not null check (source in ('sms', 'manual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (account_id, dedupe_hash)
);

create index if not exists finance_accounts_user_active_idx
  on public.finance_accounts(user_id, is_active);
create index if not exists finance_transactions_user_occurred_idx
  on public.finance_transactions(user_id, occurred_at desc);
create index if not exists finance_transactions_account_occurred_idx
  on public.finance_transactions(account_id, occurred_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
drop trigger if exists finance_accounts_set_updated_at on public.finance_accounts;
create trigger finance_accounts_set_updated_at before update on public.finance_accounts
for each row execute function public.set_updated_at();
drop trigger if exists finance_transactions_set_updated_at on public.finance_transactions;
create trigger finance_transactions_set_updated_at before update on public.finance_transactions
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    phone = coalesce(excluded.phone, public.profiles.phone);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.finance_accounts enable row level security;
alter table public.finance_transactions enable row level security;

create policy "profiles: owner can read" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profiles: owner can update" on public.profiles
  for update to authenticated using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
create policy "accounts: owner can read" on public.finance_accounts
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "transactions: owner can read" on public.finance_transactions
  for select to authenticated using ((select auth.uid()) = user_id);
