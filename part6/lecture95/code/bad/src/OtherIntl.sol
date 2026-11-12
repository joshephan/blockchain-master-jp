// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract O2 {
    function intl() internal pure returns (uint256) { return 3; }
}

contract OtherIntl {
    function g(O2 o) external pure returns (uint256) {
        return o.intl();
    }
}
