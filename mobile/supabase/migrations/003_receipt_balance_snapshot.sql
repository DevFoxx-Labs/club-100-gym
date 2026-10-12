-- =====================================================================
-- 003 — Installment receipts: snapshot of the bill total and the balance
-- still owed after each payment (safe to run more than once).
--
-- REQUIRED if 001 was applied before this file existed: the app pushes
-- these columns with every receipt, and Supabase rejects rows with
-- unknown columns, so receipts would stop syncing without this.
-- =====================================================================

alter table receipts add column if not exists bill_total double precision;
alter table receipts add column if not exists balance_due double precision;
