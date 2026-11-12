// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Counter} from "./Inh.sol";

// 第110講のデモ: Counterをimportだけして継承しない版
contract Alone {
    uint256 public extra;

    function useShared() external pure returns (uint256) {
        return 8;
    }
}
