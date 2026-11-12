// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ShortCircuit {
    bool public flag;
    uint256 public count;

    function setFlag(bool v) external {
        flag = v;
    }

    function mark() internal returns (bool) {
        count += 1;
        return true;
    }

    function orCheck() external returns (bool) {
        return flag || mark();
    }

    function andCheck() external returns (bool) {
        return flag && mark();
    }

    function orSwapped() external returns (bool) {
        return mark() || flag;
    }
}
