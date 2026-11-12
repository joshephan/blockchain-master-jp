// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Runner {
    uint256 public jobs;

    function run(uint256 x, function (uint256) external cb) external {
        jobs += 1;
        cb(x * 2);
    }
}

contract Alice {
    uint256 public got;

    function onDone(uint256 v) external {
        got = v;
    }
}

contract Bob {
    address public lastCaller;

    function ping(uint256) external {
        lastCaller = msg.sender;
    }
}
