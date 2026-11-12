// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ThisIntl {
    function intl() internal pure returns (uint256) { return 3; }

    function g() external view returns (uint256) {
        return this.intl();
    }
}
