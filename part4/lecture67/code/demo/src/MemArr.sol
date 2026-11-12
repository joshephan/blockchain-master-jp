// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemArr {
    function make(uint256 n) public pure returns (uint256[] memory) {
        uint256[] memory r = new uint256[](n);
        return r;
    }

    function freePtr(uint256 n) public pure returns (uint256 before, uint256 afterNew) {
        assembly { before := mload(0x40) }
        uint256[] memory r = new uint256[](n);
        assembly { afterNew := mload(0x40) }
        r;
    }

    function twoArrays() public pure returns (uint256 at1, uint256 at2, uint256 ptr) {
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](2);
        assembly {
            at1 := a
            at2 := b
            ptr := mload(0x40)
        }
    }

    function alias7() public pure returns (uint256) {
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = a;
        b[0] = 7;
        return a[0];
    }

    function evens(uint256[] calldata xs) public pure returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < xs.length; i++) {
            if (xs[i] % 2 == 0) count++;
        }
        uint256[] memory r = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < xs.length; i++) {
            if (xs[i] % 2 == 0) {
                r[j] = xs[i];
                j++;
            }
        }
        return r;
    }

    function literal() public pure returns (uint8[3] memory) {
        return [1, 2, 3];
    }

    function literalFixed() public pure returns (uint256[3] memory) {
        uint256[3] memory a = [uint256(1), 2, 3];
        return a;
    }

    function literalToDynamic() public pure returns (uint256[] memory) {
        uint256[3] memory a = [uint256(1), 2, 3];
        uint256[] memory b = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            b[i] = a[i];
        }
        return b;
    }
}
