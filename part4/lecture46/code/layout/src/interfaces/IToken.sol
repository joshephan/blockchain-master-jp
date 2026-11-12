// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IToken {
    function transfer(address to, uint amount) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
}
