// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// HuffドキュメントのチュートリアルSimpleStorageと同じ関数二つ(setValue・getValue)、同じスロット0
contract Store251 {
    uint256 private value;

    function setValue(uint256 v) external {
        value = v;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}
