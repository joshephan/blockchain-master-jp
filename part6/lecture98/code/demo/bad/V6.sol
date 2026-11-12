// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract E {}

contract V6 {
    function f() external view { new E(); }
}
