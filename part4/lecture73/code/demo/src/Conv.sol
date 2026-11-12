// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type Amount18 is uint256;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Conv {
    enum MarketStatus { Active, DepositPaused, Frozen }

    function narrow(uint256 x) external pure returns (uint8) { return uint8(x); }
    function signOnly8(int8 x) external pure returns (uint8) { return uint8(x); }
    function signOnly256(int256 x) external pure returns (uint256) { return uint256(x); }
    function sizeFirst(int8 x) external pure returns (uint256) { return uint256(uint8(x)); }
    function signFirst(int8 x) external pure returns (uint256) { return uint256(int256(x)); }
    function toBytes4(uint32 x) external pure returns (bytes4) { return bytes4(x); }
    function hashToAddr(bytes32 h) external pure returns (address) { return address(uint160(uint256(h))); }
    function mixed(uint8 a, uint16 b) external pure returns (uint16) { return a + b; }
    function toStatus(uint8 v) external pure returns (MarketStatus) { return MarketStatus(v); }
    function toBytes32(bytes memory b) external pure returns (bytes32) { return bytes32(b); }
    function wrap18(uint256 x) external pure returns (Amount18) { return Amount18.wrap(x); }
    function asToken(address a) external pure returns (address) {
        IERC20 token = IERC20(a);
        return address(token);
    }
    function literal() external pure returns (uint8) { uint8 y = 5; return y; }
}
