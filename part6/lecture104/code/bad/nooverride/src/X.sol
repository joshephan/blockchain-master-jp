// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Base {
    address public owner = msg.sender;
    uint256 public x;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setX(uint256 v) external onlyOwner {
        x = v;
    }
}

contract Child is Base {
    modifier onlyOwner() {
        _;
    }
}
