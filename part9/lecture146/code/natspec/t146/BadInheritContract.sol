// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface I {
    function f() external;
}
/// @inheritdoc I
contract X is I {
    function f() external {}
}
