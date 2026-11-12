// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract CallWrong {
    function f(address to) external pure returns (bytes memory) {
        return abi.encodeCall(IERC20.transfer, (to, "1"));
    }
}
