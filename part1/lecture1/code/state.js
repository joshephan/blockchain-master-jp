// state.js: 同じ二つのトランザクション、順番だけを変えて
const genesis = { alice: 10, bob: 0, carol: 0 };

function apply(state, tx) {
  if (state[tx.from] < tx.amount) {
    console.log(`  拒否: ${tx.from} -> ${tx.to} ${tx.amount} (残高 ${state[tx.from]})`);
    return state;
  }
  console.log(`  承認: ${tx.from} -> ${tx.to} ${tx.amount}`);
  return {
    ...state,
    [tx.from]: state[tx.from] - tx.amount,
    [tx.to]: state[tx.to] + tx.amount,
  };
}

function run(label, txs) {
  console.log(label);
  const final = txs.reduce(apply, genesis);
  console.log('  結果:', JSON.stringify(final));
}

const toBob = { from: 'alice', to: 'bob', amount: 10 };
const toCarol = { from: 'alice', to: 'carol', amount: 10 };

run('アジアのノード [ボブが先]', [toBob, toCarol]);
run('ヨーロッパのノード [キャロルが先]', [toCarol, toBob]);
