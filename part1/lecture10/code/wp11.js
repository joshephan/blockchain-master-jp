// Bitcoin whitepaper section 11 AttackerSuccessProbability
function P(q, z) {
  const p = 1 - q, lambda = z * (q / p);
  let sum = 1;
  for (let k = 0; k <= z; k++) {
    let poisson = Math.exp(-lambda);
    for (let i = 1; i <= k; i++) poisson *= lambda / i;
    sum -= poisson * (1 - Math.pow(q / p, z - k));
  }
  return sum;
}
for (const q of [0.1, 0.3]) for (const z of [0,1,2,3,4,5,6,10]) console.log(q, z, P(q,z).toFixed(7));
for (const q of [0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45]) { let z=0; while (P(q,z) >= 0.001) z++; console.log('q', q, 'z', z); }
