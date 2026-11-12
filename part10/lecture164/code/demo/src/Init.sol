// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// コンストラクタで値を入れる実装
contract CtorBox {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
        value = 42;
    }
}

// コンストラクタの代わりに初期化関数。実装自身はロックしない
contract InitBox is Initializable {
    address public owner;
    uint256 public fee;

    function initialize(address owner_) external initializer {
        owner = owner_;
    }

    function initializeV2(uint256 fee_) external reinitializer(2) {
        fee = fee_;
    }
}

// コンストラクタで実装自身の初期化を止めておいた版
contract LockedInitBox is Initializable {
    address public owner;

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) external initializer {
        owner = owner_;
    }
}
