// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第172講のトイプール。積が一定の交換(x*y=k)。実際のDEXではない、講義用の最小の形
contract ToyPool {
    uint256 public reserveA;
    uint256 public reserveB;

    constructor(uint256 a, uint256 b) {
        reserveA = a;
        reserveB = b;
    }

    // Aを入れてBを受け取る。手数料なし(最小の形)
    function _outB(uint256 inA) internal view returns (uint256) {
        uint256 k = reserveA * reserveB;
        uint256 newA = reserveA + inA;
        return reserveB - k / newA;
    }

    function quoteAForB(uint256 inA) external view returns (uint256) {
        return _outB(inA);
    }

    // スリッページの上限なし。受け取る量をあらかじめ固定できない
    function swapAForB(uint256 inA) external returns (uint256 outB) {
        outB = _outB(inA);
        reserveA += inA;
        reserveB -= outB;
    }

    // スリッページの上限あり。受け取る量がminOutより少なければ巻き戻す
    function swapAForBMin(uint256 inA, uint256 minOut) external returns (uint256 outB) {
        outB = _outB(inA);
        if (outB < minOut) revert Slippage(outB, minOut);
        reserveA += inA;
        reserveB -= outB;
    }

    // Bを入れてAを受け取る(攻撃者が売り戻すとき)
    function swapBForA(uint256 inB) external returns (uint256 outA) {
        uint256 k = reserveA * reserveB;
        uint256 newB = reserveB + inB;
        outA = reserveA - k / newB;
        reserveB += inB;
        reserveA -= outA;
    }

    error Slippage(uint256 got, uint256 minOut);
}
