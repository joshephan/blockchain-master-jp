// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Fee {
    uint8 public percent;

    function setPercent(uint8 p) external {
        percent = p;
    }
}

contract FeeChecked {
    uint8 public percent;

    function setPercent(uint8 p) external {
        require(p <= 100, "percent > 100");
        percent = p;
    }
}
