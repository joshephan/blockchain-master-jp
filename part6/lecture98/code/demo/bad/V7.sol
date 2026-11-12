// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V7 {
    function f() external view { assembly { sstore(0, 1) } }
}
