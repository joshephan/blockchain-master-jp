// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第104講: virtual modifierは子が丸ごと置き換える
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
    modifier onlyOwner() override {
        _;
    }
}

// 第104講: 状態を変えるmodifierは順番が結果を変える
contract Once {
    uint256 public calls;

    modifier bump() {
        calls += 1;
        _;
    }

    modifier first() {
        require(calls == 0, "not first");
        _;
    }

    function bumpThenFirst() external bump first {}
    function firstThenBump() external first bump {}
}

// 第104講: _;を飛ばすmodifier
contract Count {
    uint256 public count;

    modifier onlyIf(bool c) { if (c) { _; } }

    function maybe(bool c) external onlyIf(c) returns (uint256) {
        count += 1;
        return 7;
    }
}
