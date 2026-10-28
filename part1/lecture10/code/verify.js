const crypto = require('crypto');
const [data, nonce] = [process.argv[2], process.argv[3]];
const h = crypto.createHash('sha256').update(data + '|nonce:' + nonce).digest('hex');
console.log(h);
