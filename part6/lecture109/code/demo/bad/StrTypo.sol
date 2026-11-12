// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StrTypo {
    address admin = msg.sender;

    function f() external view {
        require(msg.sender == admin, "not admn");
    }
}
