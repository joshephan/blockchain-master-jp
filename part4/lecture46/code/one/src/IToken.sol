// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IToken {
    function transfer(address to, uint amount) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract Caller {
    function send(IToken token, address to, uint amount) external returns (bool) {
        return token.transfer(to, amount);
    }
}

contract FakeToken {
    function transfer(address, uint) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint) {
        return 1000000;
    }
}
