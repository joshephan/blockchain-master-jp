-- [244-1] 帳簿で数えた預け入れ残高(TVL): 日付ごとの入ったもの、出たもの、累計
with flows as (
  select evt_block_date as day, asset, amount as delta from market67_anvil.Market_evt_Deposited
  union all
  select evt_block_date, asset, -amount from market67_anvil.Market_evt_Withdrawn
), daily as (
  select day, asset, sum(case when delta > 0 then delta else 0 end) as inflow,
         sum(case when delta < 0 then -delta else 0 end) as outflow, sum(delta) as net
  from flows group by day, asset
)
select day, who(asset) as asset, inflow, outflow, net,
       sum(net) over (partition by asset order by day) as ledger_tvl
from daily order by asset, day;
-- [244-2] 金庫に実際に入っているトークン: TransferでMarketに入ったもの引く出たもの
select who(contract_address) as token,
       sum(case when "to" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else 0 end) as in_sum,
       sum(case when "from" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else 0 end) as out_sum,
       sum(case when "to" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else 0 end)
     - sum(case when "from" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else 0 end) as vault_balance
from toy67_anvil.ToyToken67_evt_Transfer group by contract_address;
-- [244-3] 日付ごとの利用者数(預け入れか出金をした異なるアドレス)
select day, count(distinct user) as active_users from (
  select evt_block_date as day, user from market67_anvil.Market_evt_Deposited
  union all select evt_block_date, user from market67_anvil.Market_evt_Withdrawn
) group by day order by day;
-- [244-4] 最後のブロック時点の預け入れ者ごとの持ち分と比率(TKA)
with pos as (
  select user, sum(amount) as amt from (
    select user, amount from market67_anvil.Market_evt_Deposited where asset = '0x5fbdb2315678afecb367f032d93f642f64180aa3'
    union all select user, -amount from market67_anvil.Market_evt_Withdrawn where asset = '0x5fbdb2315678afecb367f032d93f642f64180aa3'
  ) group by user
)
select who(user) as user, amt, round(100.0 * amt / (select sum(amt) from pos), 1) as share_pct from pos order by amt desc;
-- [244-5] Marketへ行った取引の日付ごとの失敗率
select block_date as day, count(*) as txs, sum(1 - success) as failed, round(100.0 * sum(1 - success) / count(*), 1) as failed_pct
from anvil.transactions where "to" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' group by day order by day;
-- [244-6] 検算: ログで数え直した値と最後のブロックでeth_callで読んだ状態(Duneにはない表)
select who(asset) as asset, block_number, total_deposits, vault_balance, status
from anvil.local_state where block_number = (select max(block_number) from anvil.local_state);
;
-- [244-7] リバートした取引が使った手数料(gas_used × gas_price、wei)
select block_date as day, who("from") as sender, gas_used, gas_price, gas_used * gas_price as fee_wei
from anvil.transactions where success = 0 order by block_number
