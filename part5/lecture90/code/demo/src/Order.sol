// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Order {
    uint256 public count; // スロット0

    event Ordered(address who, uint256 n);

    function place(uint256 n) external {
        count += 1;
        emit Ordered(msg.sender, n);
        require(n <= 10, "too many");
    }

    // ガス切れ比較用
    function burn(uint256 n) external pure returns (uint256 s) {
        for (uint256 i = 0; i < n; i++) {
            s += i;
        }
    }
}

// 内側の呼び出しだけが巻き戻る版
contract Outer {
    uint256 public tries; // スロット0
    bool public lastOk;

    function tryPlace(Order o, uint256 n) external {
        tries += 1;
        (bool ok, ) = address(o).call(abi.encodeCall(Order.place, (n)));
        lastOk = ok;
    }
}
