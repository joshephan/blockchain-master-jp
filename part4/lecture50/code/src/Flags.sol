// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract OneFlag {
    bool public paused;

    function pause() external {
        paused = true;
    }
}

contract TwoFlags {
    bool public paused;
    bool public frozen;

    function pause() external {
        paused = true;
    }

    function freeze() external {
        frozen = true;
    }
}
