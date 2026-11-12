// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface ICaps {
    function SECONDS_PER_YEAR() external view returns (uint256);
    function Seconds_Per_Year() external view returns (uint256);
}

contract Caps2 {
    uint256 public $balance;
    function SECONDS_PER_DAY() external pure returns (uint256) {
        return 1;
    }
}
