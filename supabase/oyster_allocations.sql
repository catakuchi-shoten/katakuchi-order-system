-- 牡蠣の受注(oyster_orders。卸先の冷凍牡蠣も同じ店舗slug・日付で入っている)ごと・サイズごとに、
-- 「冷凍(拓人ストック)」「冷凍(カタクチで冷凍)」に振り分けた数(ケース)。残りは生(拓人指ヶ浜から直送)。
-- 冷凍はどちらもカタクチの冷凍庫に入庫してから配送するので、在庫の仕入れ先「拓人」「カタクチ」の残りから引く。
-- 発注の保存・削除とは別テーブルにして、発注側の上書きで振り分けが消えないようにしている
-- (発注が減って振り分けの方が多くなった場合は、アプリ側で発注数までに切り詰めて計算する)。
create table if not exists oyster_allocations (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null,
  order_date date not null,
  takuto_s numeric not null default 0,
  takuto_m numeric not null default 0,
  katakuchi_s numeric not null default 0,
  katakuchi_m numeric not null default 0,
  updated_at timestamptz not null default now(),
  unique (store_slug, order_date)
);

alter table oyster_allocations enable row level security;
drop policy if exists "oyster_allocations anon select" on oyster_allocations;
drop policy if exists "oyster_allocations anon insert" on oyster_allocations;
drop policy if exists "oyster_allocations anon update" on oyster_allocations;
drop policy if exists "oyster_allocations anon delete" on oyster_allocations;
create policy "oyster_allocations anon select" on oyster_allocations for select using (true);
create policy "oyster_allocations anon insert" on oyster_allocations for insert with check (true);
create policy "oyster_allocations anon update" on oyster_allocations for update using (true);
create policy "oyster_allocations anon delete" on oyster_allocations for delete using (true);

-- 在庫の監査ログ(kaki_stock_audit_log.sql)にも記録する。
drop trigger if exists oyster_allocations_audit on oyster_allocations;
create trigger oyster_allocations_audit
  after insert or update or delete on oyster_allocations
  for each row execute function kaki_stock_audit_trigger();
