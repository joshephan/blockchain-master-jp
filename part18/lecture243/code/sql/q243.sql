-- [243-1] 表三つの行数
select (select count(*) from anvil.blocks) as blocks, (select count(*) from anvil.transactions) as transactions, (select count(*) from anvil.logs) as logs;
-- [243-2] リバートした取引: transactionsにはあってlogsにはない
select t.block_number, t.block_time, who(t."from") as sender, who(t."to") as "to", t.success, t.gas_used,
       (select count(*) from anvil.logs l where l.tx_hash = t.hash) as log_count
from anvil.transactions t where t.success = 0;
-- [243-3] 元のlogsでDepositedのtopic0だけで数えると(アドレスで絞らない)
select who(contract_address) as emitter, count(*) as n, sum(varbinary_to_uint256(data)) as amount_sum
from anvil.logs where topic0 = '0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7'
group by contract_address;
-- [243-4] 同じログを手でほどく: topic1・topic2は後ろ20バイトがアドレス、data 32バイトが金額
select block_number, who('0x' || substr(varbinary_substring(topic1, 13, 20), 3)) as asset,
       who('0x' || substr(varbinary_substring(topic2, 13, 20), 3)) as user,
       varbinary_to_uint256(varbinary_substring(data, 1, 32)) as amount
from anvil.logs
where contract_address = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512'
  and topic0 = '0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7'
order by block_number limit 5;
-- [243-5] デコードされた表: 申請したアドレスのログだけが入っている
select who(contract_address) as contract, who(asset) as asset, count(*) as n, sum(amount) as amount_sum
from market67_anvil.Market_evt_Deposited group by contract_address, asset;
-- [243-6] 日付ごとの預け入れ件数と金額(ブロック時刻の日付でまとめる)
select evt_block_date as day, who(asset) as asset, count(*) as n, sum(amount) as amount
from market67_anvil.Market_evt_Deposited group by day, asset order by day;
;
-- [243-7] デプロイ取引のdataの末尾に付いたコンストラクタ引数からトークンシンボルを読む: 最後の32バイトの欄の先頭3バイトが文字のバイト
select block_number, who(t."from") as deployer, varbinary_length(data) as data_len,
       varbinary_to_uint256(varbinary_substring(data, varbinary_length(data) - 63, 32)) as str_len,
       varbinary_substring(data, varbinary_length(data) - 31, 3) as str_bytes,
       from_utf8(varbinary_substring(data, varbinary_length(data) - 31, 3)) as symbol
from anvil.transactions t where t."to" is null and t.block_number in (1, 31)
