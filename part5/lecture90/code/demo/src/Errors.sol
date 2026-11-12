// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

error Zero();
error TooSmall(uint256 got, uint256 min);

contract Errors {
    function reqMsg(uint256 x) external pure {
        require(x > 0, "zero");
    }

    function reqErr(uint256 x) external pure {
        require(x > 0, Zero());
    }

    function revMsg(uint256 x) external pure {
        if (x == 0) revert("zero");
    }

    function revErr(uint256 x) external pure {
        if (x < 10) revert TooSmall(x, 10);
    }

    function asrt(uint256 x) external pure {
        assert(x != 0);
    }
}

contract Panics {
    bytes b;

    // 0x22: ストレージのbytes欄をわざと壊してから読む
    function p22() external returns (uint256) {
        assembly {
            sstore(b.slot, 3)
        }
        return b.length;
    }

    // 0x41: メモリを大きく取りすぎる
    function p41() external pure returns (uint256) {
        uint256[] memory a = new uint256[](2 ** 64);
        return a.length;
    }
}
