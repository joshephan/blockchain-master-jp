// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface I {
    /// @notice n
    function f() external;
}
interface J {
    function f() external;
}
contract X is I {
    /// @inheritdoc J
    function f() external {}
}
