// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ViewWrite {
    uint256 public hits;
    modifier counted() { hits += 1; _; }
    function get() external view counted returns (uint256) { return 1; }
}
