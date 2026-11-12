-- [246-1] 大きな出金: 出金一件がその直前の帳簿残高の20%以上
with flows as (
  select evt_block_number as bn, evt_index as ix, evt_block_time as t, asset, user, amount as delta, 'D' as kind from market67_anvil.Market_evt_Deposited
  union all select evt_block_number, evt_index, evt_block_time, asset, user, -amount, 'W' from market67_anvil.Market_evt_Withdrawn
), run as (
  select *, sum(delta) over (partition by asset order by bn, ix rows between unbounded preceding and 1 preceding) as before
  from flows
)
select bn, t, who(asset) as asset, who(user) as user, -delta as amount, before as tvl_before,
       round(100.0 * -delta / before, 1) as pct
from run where kind = 'W' and -delta >= 0.2 * before order by bn;
-- [246-2] 1時間の出金合計がその時刻の帳簿の30%以上
with w as (
  select substr(evt_block_time, 1, 13) as hour, asset, sum(amount) as out_sum, min(evt_block_number) as first_bn
  from market67_anvil.Market_evt_Withdrawn group by hour, asset
)
select w.hour, who(w.asset) as asset, w.out_sum, s.total_deposits as tvl_before, round(100.0 * w.out_sum / s.total_deposits, 1) as pct
from w join anvil.local_state s on s.asset = w.asset and s.block_number = w.first_bn - 1
where w.out_sum >= 0.3 * s.total_deposits;
-- [246-3] 帳簿が金庫より大きくなった最初のブロックとその取引
with ev as (
  select evt_block_number as bn, asset, amount as l, 0 as v from market67_anvil.Market_evt_Deposited
  union all select evt_block_number, asset, -amount, 0 from market67_anvil.Market_evt_Withdrawn
  union all select evt_block_number, contract_address, 0,
         case when "to" = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' then value else -value end
  from toy67_anvil.ToyToken67_evt_Transfer where '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512' in ("to", "from")
), per_block as (
  select bn, asset, sum(sum(l)) over (partition by asset order by bn) as ledger, sum(sum(v)) over (partition by asset order by bn) as vault
  from ev group by bn, asset
)
select p.bn, who(p.asset) as asset, p.ledger, p.vault, who(t."from") as sender, t.hash
from per_block p join anvil.transactions t on t.block_number = p.bn
where p.vault < p.ledger and p.bn = (select min(bn) from per_block q where q.asset = p.asset and q.vault < q.ledger);
-- [246-4] Marketのイベントと同じtopic0を別のアドレスが出す
select l.block_number, who(l.contract_address) as emitter, who(l.tx_from) as tx_from, l.topic0
from anvil.logs l
where l.topic0 in ('0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7',
                   '0xd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb')
  and l.contract_address <> '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512';
-- [246-5] リバートした取引(logsにはない): 送った人、先頭4バイト、使ったガス
select block_number, block_time, who("from") as sender, substr(data, 1, 10) as selector, gas_used
from anvil.transactions where success = 0 order by block_number;
-- [246-6] 実装アドレスが変わったプロキシ: 最初の実装と今の実装
select who(contract_address) as proxy, count(*) as upgrades,
       who((select implementation from proxy67_anvil.SlotProxy_evt_Upgraded order by evt_block_number limit 1)) as first_impl,
       who((select implementation from proxy67_anvil.SlotProxy_evt_Upgraded order by evt_block_number desc limit 1)) as now_impl,
       max(evt_block_time) as last_change
from proxy67_anvil.SlotProxy_evt_Upgraded group by contract_address;
-- [246-7] コードの末尾からコンパイラのバージョンを読む: 最後の2バイト = 末尾の長さ、'solc'の後ろ3バイト = バージョン
select name, varbinary_length(code) as code_len,
       varbinary_to_uint256(varbinary_substring(code, varbinary_length(code) - 1, 2)) as tail_len,
       varbinary_substring(code, varbinary_position(code, '0x736f6c6343') + 5, 3) as solc
from anvil.code_now order by name;
;
-- [246-8] 普段との比較: 出金一件をそれ以前の出金の平均・中央値と比べる(同じ資産)
with w as (select evt_block_number as bn, asset, user, amount from market67_anvil.Market_evt_Withdrawn)
select w1.bn, who(w1.asset) as asset, who(w1.user) as user, w1.amount,
       (select count(*) from w w2 where w2.asset = w1.asset and w2.bn < w1.bn) as prev_n,
       round((select avg(amount) from w w2 where w2.asset = w1.asset and w2.bn < w1.bn), 1) as prev_avg,
       (select median(amount) from w w2 where w2.asset = w1.asset and w2.bn < w1.bn) as prev_median,
       round(w1.amount * 1.0 / (select avg(amount) from w w2 where w2.asset = w1.asset and w2.bn < w1.bn), 1) as x_avg,
       round(w1.amount * 1.0 / (select median(amount) from w w2 where w2.asset = w1.asset and w2.bn < w1.bn), 1) as x_median
from w w1 order by w1.asset, w1.bn
