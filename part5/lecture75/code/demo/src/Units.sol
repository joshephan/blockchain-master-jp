// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Units {
    uint256 public constant ONE_WEI = 1 wei;
    uint256 public constant ONE_GWEI = 1 gwei;
    uint256 public constant ONE_ETHER = 1 ether;
    uint256 public constant TWO_AND_HALF = 2.5 ether;

    uint256 public constant ONE_SECOND = 1 seconds;
    uint256 public constant ONE_MINUTE = 1 minutes;
    uint256 public constant ONE_HOUR = 1 hours;
    uint256 public constant ONE_DAY = 1 days;
    uint256 public constant ONE_WEEK = 1 weeks;
    uint256 public constant HALF_DAY = 0.5 days;

    uint64 public small = 1 ether;
    uint256 public mixed = 1 days + 1 ether;

    function lockFor(uint256 x) external pure returns (uint256) {
        return x * 1 days;
    }
}
