// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {InsufficientDeposit} from "./Market.sol";

interface IWithdraw {
    function withdraw(address asset, uint256 amount) external;
}

// デモ用: withdrawを呼び、受け取ったバイト列の先頭4バイトを見る
contract Reader {
    event Insufficient(bytes data);
    event Other(bytes data);

    function tryWithdraw(IWithdraw m, address asset, uint256 amount) external {
        try m.withdraw(asset, amount) {
        } catch (bytes memory data) {
            if (bytes4(data) == InsufficientDeposit.selector) {
                emit Insufficient(data);
            } else {
                emit Other(data);
            }
        }
    }
}

// Marketではないのに同じエラーを投げるコントラクト
contract Liar {
    function withdraw(address, uint256) external pure {
        revert InsufficientDeposit(0, 1);
    }
}
