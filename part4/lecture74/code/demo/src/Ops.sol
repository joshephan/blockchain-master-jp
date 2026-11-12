// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ops {
    uint8 public small = 255;
    uint8 public bits = 128;
    uint256[3] public arr;
    uint256 public i;

    function post(uint256 x) external pure returns (uint256 returned, uint256 after_) {
        returned = x++;
        after_ = x;
    }

    function pre(uint256 x) external pure returns (uint256 returned, uint256 after_) {
        returned = ++x;
        after_ = x;
    }

    function bump() external {
        small++;
    }

    function shift() external {
        bits <<= 1;
    }

    function touch() external {
        arr[i++] += 1;
    }
}
