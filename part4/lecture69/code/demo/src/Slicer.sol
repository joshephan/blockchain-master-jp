// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Slicer {
    // 先頭4バイトを除き、残りを新しいメモリに1バイトずつ移す版
    function restLoop(bytes calldata data) external pure returns (uint256, bytes1) {
        bytes memory rest = new bytes(data.length - 4);
        for (uint256 i = 0; i < rest.length; i++) {
            rest[i] = data[i + 4];
        }
        return (rest.length, rest[0]);
    }

    // 同じことをスライス一行で
    function restSlice(bytes calldata data) external pure returns (uint256, bytes1) {
        bytes calldata rest = data[4:];
        return (rest.length, rest[0]);
    }

    // スライスをmemory変数に入れる版
    function restCopy(bytes calldata data) external pure returns (uint256, bytes1) {
        bytes memory rest = data[4:];
        return (rest.length, rest[0]);
    }

    function parts(bytes calldata data)
        external
        pure
        returns (bytes memory head, bytes memory mid, bytes memory tail)
    {
        head = data[:4];
        mid = data[2:6];
        tail = data[4:];
    }

    function selectorOf(bytes calldata data) external pure returns (bytes4) {
        return bytes4(data[:4]);
    }

    function sumTail(uint256[] calldata xs) external pure returns (uint256 s) {
        uint256[] calldata t = xs[1:];
        for (uint256 i = 0; i < t.length; i++) {
            s += t[i];
        }
    }
}
