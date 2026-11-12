// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Owned {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner); _; }
}
contract Coin
{
    struct Bank {
        address owner;
        uint balance;
    }
    mapping (uint => uint) map;
    mapping( address => bool ) registered;
    uint [] xs;
    uint x;
    uint y;
    uint longVariable;
    string str;

    event LongAndLotsOfArgs(address sender,
                            address recipient,
                            uint256 publicKey,
                            uint256 amount,
                            bytes32[] options);

    receive () external payable {
    }

    function spam(uint i , uint j) public pure returns (uint){
        return i+j;
    }

    function increment(uint a) pure public returns (uint) {
        return a + 1;
        }

    function align() public {
        x            = 1;
        y            = 2;
        longVariable = 3;
        str = 'bar';
        x=3;
        x = 100/10;
        x = 2*y + 3*x;
        x = (y+x) * (y-x);
    }

    function control(uint a) public pure returns (uint b) {
        if (a < 10)
            b = 1;
        if (a < 3) {
            b += 1;
        }
        else {
            b -= 1;
        }
        while(b > 100){
            b--;
        }
        for (uint k = 0; k < 3; k++) b += k;
    }

    function thisFunctionHasLotsOfArguments(address a, address b, address c,
        address d, address e, address f) public {
        emit LongAndLotsOfArgs(a, b, uint256(uint160(c)), uint256(uint160(d)), new bytes32[](0));
        e; f;
    }

    function shortFunction() public pure returns (uint) { return 1; }
}
