// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P {
    function priv() private pure returns (uint256) { return 4; }
}

contract ChildPriv is P {
    function g() external pure returns (uint256) {
        return priv();
    }
}
