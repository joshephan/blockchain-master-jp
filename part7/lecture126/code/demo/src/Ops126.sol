// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ops126 {
    function bitEq(uint256 x) external pure returns (bool) { return x & 1 == 0; }
    function negPow(int256 x) external pure returns (int256) { return -x ** 2; }
    function powPow(uint256 a, uint256 b, uint256 c) external pure returns (uint256) { return a ** b ** c; }
    function shiftAdd(uint256 x) external pure returns (uint256) { return 1 << x + 1; }
    function mm(uint256 a, uint256 b, uint256 k) external pure returns (uint256) { return mulmod(a, b, k); }
    function plainMulMod(uint256 a, uint256 b, uint256 k) external pure returns (uint256) { return a * b % k; }
    function am(uint256 a, uint256 b, uint256 k) external pure returns (uint256) { return addmod(a, b, k); }
    function interest(uint256 amount, uint256 rate, uint256 elapsed) external pure returns (uint256) {
        return amount * rate * elapsed / 365 days / 1e18;
    }
    function interestSwapped(uint256 amount, uint256 rate, uint256 elapsed) external pure returns (uint256) {
        return amount * (rate * elapsed / 365 days) / 1e18;
    }
}
