function steps(n) {
  let count = 0;
  while (n !== 1) {
    n = n % 2 === 0 ? n / 2 : 3 * n + 1;
    count++;
  }
  return count;
}
console.log(steps(7));
console.log(steps(27));
