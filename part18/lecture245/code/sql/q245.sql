-- [245-1] データの時点: この画面のすべての数字はこのブロックまでの答え
select max(number) as last_block, max(time) as last_block_time from anvil.blocks;
-- [245-2] パネル1。資産ごとの帳簿と金庫(ログで数え直す)、差と判定
with ledger as (
  select asset, sum(amount) as amt from (
    select asset, amount from market67_anvil.Market_evt_Deposited
    union all select asset, -amount from market67_anvil.Market_evt_Withdrawn) group by asset
), vault as (
  select contract_address as asset,
         sum(case when "to" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else -value end) as amt
  from toy67_anvil.ToyToken67_evt_Transfer
  where '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' in ("to", "from") group by contract_address
)
select who(l.asset) as asset, l.amt as ledger, v.amt as vault, v.amt - l.amt as diff,
       case when v.amt < l.amt then '警報: 金庫が帳簿より少ない'
            when v.amt > l.amt then '注意: 帳簿の外のトークン'
            else '正常' end as verdict
from ledger l join vault v on v.asset = l.asset;
-- [245-3] パネル2。検算: ログで数えた帳簿とeth_callで読んだtotalDeposits(最後のブロック)
select who(s.asset) as asset, s.total_deposits as state_total, s.vault_balance as state_vault, s.block_number
from anvil.local_state s where s.block_number = (select max(block_number) from anvil.local_state);
-- [245-4] パネル3。マーケットの状態: ログには数字だけ、名前はソースのenumの順番(0 Active、1 DepositPaused、2 Frozen)
select evt_block_time, "from", "to",
       case "to" when 0 then 'Active' when 1 then 'DepositPaused' when 2 then 'Frozen' end as to_name
from market67_anvil.Market_evt_StatusChanged order by evt_block_number desc limit 1;
-- [245-5] パネル4。最大の預け入れ者の比率(資産ごと)、40%を超えたら注意
with pos as (
  select asset, user, sum(amount) as amt from (
    select asset, user, amount from market67_anvil.Market_evt_Deposited
    union all select asset, user, -amount from market67_anvil.Market_evt_Withdrawn) group by asset, user
)
select who(asset) as asset, who(user) as top_user, amt, round(100.0 * amt / tot, 1) as share_pct,
       case when 100.0 * amt / tot > 40 then '注意' else '正常' end as verdict
from (select asset, user, amt, sum(amt) over (partition by asset) as tot,
             row_number() over (partition by asset order by amt desc) as rk from pos) where rk = 1;
-- [245-6] パネル5。管理者の行動の記録(上場、状態の変更、実装の変更)
select evt_block_time as t, 'AssetAdded' as what, who(asset) as detail from market67_anvil.Market_evt_AssetAdded
union all select evt_block_time, 'StatusChanged', "from" || ' -> ' || "to" from market67_anvil.Market_evt_StatusChanged
union all select evt_block_time, 'Upgraded', who(implementation) from proxy67_anvil.SlotProxy_evt_Upgraded
order by t;
-- [245-7] パネル6。帳簿と金庫の差をブロックごとに(FEE): いつから開いたか
select block_number, block_time, total_deposits as ledger, vault_balance as vault, vault_balance - total_deposits as diff
from anvil.local_state where asset = '0xb7f8bc63bbcad18155201308c8f3540b07f84f5e'
  and block_number in (32, 36, 37, 38, 43, 44, 45, 46) order by block_number;
;
-- [245-8] ブロックごとの照合: ログで数えた帳簿と同じブロックハッシュで読んだtotalDepositsが違うブロックの数
with ev as (
  select evt_block_number as bn, asset, amount as d from market67_anvil.Market_evt_Deposited
  union all select evt_block_number, asset, -amount from market67_anvil.Market_evt_Withdrawn
)
select who(s.asset) as asset, count(*) as blocks_checked,
       sum(case when coalesce((select sum(d) from ev where ev.asset = s.asset and ev.bn <= s.block_number), 0) <> s.total_deposits then 1 else 0 end) as mismatched
from anvil.local_state s group by s.asset
