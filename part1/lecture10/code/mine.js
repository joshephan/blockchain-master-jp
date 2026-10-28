const crypto = require('crypto');

const data = 'prev:0000abcd|alice->bob:10';

function sha256(s) {
  return crypto.createHash('sha256').update(s).digest('hex');
}

function mine(k) {
  const target = '0'.repeat(k);
  const start = process.hrtime.bigint();
  let nonce = 0;
  while (true) {
    const h = sha256(data + '|nonce:' + nonce);
    if (h.startsWith(target)) {
      const ms = Number(process.hrtime.bigint() - start) / 1e6;
      return { k, nonce, tries: nonce + 1, ms: ms.toFixed(1), hash: h };
    }
    nonce++;
  }
}

for (let k = 1; k <= 5; k++) {
  const r = mine(k);
  console.log(`k=${r.k}  nonce=${r.nonce}  tries=${r.tries}  ${r.ms}ms  ${r.hash}`);
}
