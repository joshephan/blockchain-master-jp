// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Fee {
    // 0.3%の手数料を引いて残る金額
    function mulFirst(uint256 amount) external pure returns (uint256) {
        return amount * 997 / 1000;
    }

    function divFirst(uint256 amount) external pure returns (uint256) {
        return amount / 1000 * 997;
    }
}
