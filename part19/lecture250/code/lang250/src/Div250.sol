// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 負の数の割り算と余り。EVMのSDIV・SMODそのまま
contract Div250 {
    function div(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    function mod(int256 a, int256 b) external pure returns (int256) {
        return a % b;
    }
}
