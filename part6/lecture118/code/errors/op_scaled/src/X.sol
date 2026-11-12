// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
type Wad is uint256; // 倍率10の18乗
function mulWad(Wad a, Wad b) pure returns (Wad) {
    return Wad.wrap(Wad.unwrap(a) * Wad.unwrap(b) / 1e18);
}
using {mulWad as *} for Wad global;
contract C { function f(Wad a, Wad b) external pure returns (Wad) { return a * b; } }
