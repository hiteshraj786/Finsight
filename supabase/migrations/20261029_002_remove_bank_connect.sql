-- Removes Account Aggregator/Setu artifacts from projects where the original
-- finance foundation migration was already applied.

drop table if exists public.consent_audit_events;

alter table public.finance_accounts
  drop column if exists consent_id;

drop table if exists public.finance_consents;

delete from public.finance_transactions where source = 'aa';

alter table public.finance_transactions
  drop constraint if exists finance_transactions_source_check;

alter table public.finance_transactions
  add constraint finance_transactions_source_check
  check (source in ('sms', 'manual'));
