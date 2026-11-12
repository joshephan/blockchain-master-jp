// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// EVMの形: コードとストレージスロットが一つのアドレスにまとまる
contract Counter247 {
    uint64 public count;

    function increment() external {
        count += 1;
    }
}
