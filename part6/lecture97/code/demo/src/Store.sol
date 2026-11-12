// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Store {
    uint256 public v = 5;

    function readOnce() external view returns (uint256) { return v; }
    function readThrice() external view returns (uint256) { return v + v + v; }
    function readCached() external view returns (uint256) { uint256 x = v; return x + x + x; }
    function readViaThis() external view returns (uint256) { return this.v(); }
}

contract Reader {
    function readFrom(Store s) external view returns (uint256) { return s.v(); }
}
