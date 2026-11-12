// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 呼び出し元のコード長で人のアカウントかを見分けるチェック
contract Gate {
    function callerHasCode() external view returns (bool) {
        return msg.sender.code.length > 0;
    }
}

contract Visitor {
    bool public seenInCtor;

    constructor(Gate g) {
        seenInCtor = g.callerHasCode();
    }

    function askNow(Gate g) external view returns (bool) {
        return g.callerHasCode();
    }
}
