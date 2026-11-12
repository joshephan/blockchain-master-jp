// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Wipe {
    enum Status { Active, DepositPaused, Frozen }
    struct Pair {
        uint256 x;
        bool y;
    }

    uint256 public u;
    bool public b;
    address public a;
    bytes32 public h;
    Status public s;
    uint256[3] public fixedArr;
    uint256[] public dyn;
    bytes public bs;
    string public str;
    Pair public pair;

    function fill() external {
        u = 7;
        b = true;
        a = msg.sender;
        h = keccak256("x");
        s = Status.Frozen;
        fixedArr = [uint256(1), 2, 3];
        dyn.push(10);
        dyn.push(20);
        bs = hex"0102";
        str = "abc";
        pair = Pair(5, true);
    }

    function wipe() external {
        delete u;
        delete b;
        delete a;
        delete h;
        delete s;
        delete fixedArr;
        delete dyn;
        delete bs;
        delete str;
        delete pair;
    }

    function wipeU() external {
        delete u;
    }

    function setU(uint256 v) external {
        u = v;
    }

    function dynLength() external view returns (uint256) {
        return dyn.length;
    }
}
