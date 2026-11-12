// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SelfMaker {
    function copy() external returns (SelfMaker) {
        return new SelfMaker();
    }
}
