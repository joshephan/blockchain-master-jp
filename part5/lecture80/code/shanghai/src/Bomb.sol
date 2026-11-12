// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bomb {
    uint256 public x = 42;

    constructor() payable {}

    function boom(address payable to) external {
        selfdestruct(to);
    }
}

// receiveもfallbackもない
contract NoReceive {
    uint256 public pings;

    function ping() external {
        pings += 1;
    }
}

// 作って同じトランザクションでselfdestruct
contract OneTx {
    function makeAndBoom(address payable to) external payable {
        Bomb b = new Bomb{value: msg.value}();
        b.boom(to);
    }
}
