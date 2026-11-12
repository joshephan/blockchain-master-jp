// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Assign {
    uint[] public x;
    uint[] public y;

    constructor() {
        x.push(1); x.push(2); x.push(3);
        y.push(10); y.push(20); y.push(30);
    }

    // 1. 状態変数 = 状態変数
    function stateToState() external {
        x = y;
        y[0] = 99;
    }

    // 2. storage -> storageローカル変数
    function storageToLocal() external {
        uint[] storage s = x;
        s[0] = 5;
    }

    // 3. storage -> memory
    function storageToMemory() external view returns (uint, uint) {
        uint[] memory m = x;
        m[0] = 777;
        return (m[0], x[0]);
    }

    // 4. memory -> 状態変数
    function memoryToState() external {
        uint[] memory m = new uint[](3);
        m[0] = 4;
        x = m;
        m[0] = 8;
    }

    // 5. memory -> memory
    function memoryToMemory() external pure returns (uint) {
        uint[] memory a = new uint[](3);
        uint[] memory b = a;
        b[0] = 7;
        return a[0];
    }

    // 6. calldata -> memory
    function calldataToMemory(uint[] calldata c) external pure returns (uint, uint) {
        uint[] memory m = c;
        m[0] = 7;
        return (m[0], c[0]);
    }

    // 関数に渡すとき
    function bumpRef(uint[] storage arr) internal {
        arr[0] += 1;
    }

    function bumpCopy(uint[] memory arr) internal pure returns (uint) {
        arr[0] += 1;
        return arr[0];
    }

    function passRef() external {
        bumpRef(x);
    }

    function passCopy() external view returns (uint, uint) {
        uint inside = bumpCopy(x);
        return (inside, x[0]);
    }
}
