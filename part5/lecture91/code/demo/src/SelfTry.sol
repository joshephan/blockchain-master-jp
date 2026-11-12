// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SelfTry {
    function check(uint256 x) public pure {
        require(x > 0, "zero");
    }

    function run(uint256 x) external view returns (string memory) {
        try this.check(x) {
            return "ok";
        } catch Error(string memory reason) {
            return reason;
        }
    }
}

contract Child {
    uint256 public x;

    constructor(uint256 x_) {
        require(x_ > 0, "x is zero");
        x = x_;
    }
}

contract Factory {
    function make(uint256 x) external returns (address) {
        try new Child(x) returns (Child c) {
            return address(c);
        } catch Error(string memory reason) {
            emit Failed(reason);
            return address(0);
        }
    }

    event Failed(string reason);
}
