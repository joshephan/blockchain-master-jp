// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IRich {
    function becomeRichest() external payable;
    function withdraw() external;
}

// 受け取るときに巻き戻すコントラクト
contract Rejecter {
    function play(IRich game) external payable {
        game.becomeRichest{value: msg.value}();
    }

    function cashOut(IRich game) external {
        game.withdraw();
    }

    receive() external payable {
        revert("no thanks");
    }
}

// 受け取るときにガスを使い切るコントラクト
contract Burner {
    uint256 public n;

    function play(IRich game) external payable {
        game.becomeRichest{value: msg.value}();
    }

    receive() external payable {
        while (true) {
            n++;
        }
    }
}

// 受け取るときに状態変数を一つだけ直すコントラクト
contract Writer {
    uint256 public got;

    function play(IRich game) external payable {
        game.becomeRichest{value: msg.value}();
    }

    function cashOut(IRich game) external {
        game.withdraw();
    }

    receive() external payable {
        got += msg.value;
    }
}
