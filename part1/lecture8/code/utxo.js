// ウォレットの中のUTXO三つでボブに0.6 BTCを送る（単位：サトシ、1 BTC = 100,000,000）
const fmt = s => (Number(s) / 1e8).toFixed(8) + " BTC";
let utxos = [
  { id: "A", value: 50_000_000n },
  { id: "B", value: 20_000_000n },
  { id: "C", value: 5_000_000n },
];
const balance = l => l.reduce((a, u) => a + u.value, 0n);
console.log("残高（計算値）:", fmt(balance(utxos)));
const pay = 60_000_000n, fee = 10_000n;
const inputs = [utxos[0], utxos[1]];
const inSum = balance(inputs);
const outputs = [
  { to: "ボブ", value: pay },
  { to: "自分のおつりのアドレス", value: inSum - pay - fee },
];
const outSum = outputs.reduce((a, o) => a + o.value, 0n);
console.log("入力:", inputs.map(u => u.id + " " + fmt(u.value)).join(", "), "合計", fmt(inSum));
outputs.forEach(o => console.log("出力:", o.to, fmt(o.value)));
console.log("手数料 = 入力の合計 - 出力の合計 =", fmt(inSum - outSum));
console.log("おつりの出力を忘れると手数料 =", fmt(inSum - pay));
utxos = utxos.filter(u => !inputs.includes(u)).concat([{ id: "D", value: outputs[1].value }]);
console.log("送金後の自分のUTXO:", utxos.map(u => u.id + " " + fmt(u.value)).join(", "));
console.log("残高（計算値）:", fmt(balance(utxos)));
// 0.5 BTCのUTXO一つで0.3 BTCを送る
const one = 50_000_000n, send = 30_000_000n;
console.log("0.5で0.3を送るときのおつり:", fmt(one - send - fee), "/ 手数料:", fmt(fee), "/ おつりを忘れると手数料:", fmt(one - send));
