// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract DoubleMul {
    function double(uint256 x) external pure returns (uint256) {
        return x * 2;
    }
}

contract DoubleShl {
    function double(uint256 x) external pure returns (uint256) {
        return x << 1;
    }
}

contract DoubleUnchecked {
    function double(uint256 x) external pure returns (uint256) {
        unchecked { return x * 2; }
    }
}
