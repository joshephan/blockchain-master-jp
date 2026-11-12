// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./MathLib.sol";

contract Vault {
    uint256 public total;

    function deposit(uint256 amount) public {
        total = MathLib.add(total, amount);
    }
}
