// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {SimpleToken, ToyOracle} from "./Toys.sol";

// 講義用のアルゴリズム型。担保の金庫なし
// 1ドル相当のVOLをバーンするとAUSD 1個、AUSD 1個をバーンすると1ドル相当のVOLを新しく発行する
// VOLの値は前のブロックまでに書かれた価格(settledPrice)で数える
contract AlgoStable {
    SimpleToken public immutable ausd;
    SimpleToken public immutable vol;
    ToyOracle public immutable oracle;

    constructor(ToyOracle oracle_, address firstHolder, uint256 firstVol) {
        oracle = oracle_;
        ausd = new SimpleToken("Algo USD", address(this));
        vol = new SimpleToken("Volatile", address(this));
        vol.mint(firstHolder, firstVol); // 最初の配分
    }

    // VOLをバーンしてそのドル建ての値だけAUSDを発行する
    function mintStable(uint256 volIn) external returns (uint256 ausdOut) {
        ausdOut = volIn * oracle.settledPrice() / 1e18;
        vol.burn(msg.sender, volIn);
        ausd.mint(msg.sender, ausdOut);
    }

    // AUSDをバーンして1ドル相当のVOLを新しく発行する。発行量に上限なし
    function redeemStable(uint256 ausdIn) external returns (uint256 volOut) {
        volOut = ausdIn * 1e18 / oracle.settledPrice();
        ausd.burn(msg.sender, ausdIn);
        vol.mint(msg.sender, volOut);
    }
}
