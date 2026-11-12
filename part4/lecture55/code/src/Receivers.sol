// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1. receiveがないコントラクト
contract NoReceive {
    uint256 public x;
}

// 2. receiveでストレージに一回書き込むコントラクト
contract Writer {
    uint256 public count;

    receive() external payable {
        count += 1;
    }
}

// 3. receiveで無条件に巻き戻すコントラクト
contract Refuser {
    receive() external payable {
        revert();
    }
}

// 受け取ったガスをイベントで残すコントラクト
contract Probe {
    event Gas(uint256 left);

    receive() external payable {
        emit Gas(gasleft());
    }
}
