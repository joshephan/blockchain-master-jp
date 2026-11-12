// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Counter} from "./Inh.sol";

// 名前を書き間違えた版: overrideなし
contract ChildTypo is Counter {
    function stpe() public pure returns (uint256) {
        return 10;
    }
}

// 名前は合っていて本体が違う版
contract ChildZero is Counter {
    function step() public pure override returns (uint256) {
        return 0;
    }
}
