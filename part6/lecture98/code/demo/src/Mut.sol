// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Counter {
    uint256 public n;
    function bump() external returns (uint256) { n += 1; return n; }
    function get() external view returns (uint256) { return n; }
}

// 相手の関数をviewと書いたインターフェース (実際のbumpは状態を変える)
interface ILying { function bump() external view returns (uint256); }
interface IHonest { function bump() external returns (uint256); }

contract Caller {
    function viaView(address c) external view returns (uint256) { return ILying(c).bump(); }
    function viaCall(address c) external returns (uint256) { return IHonest(c).bump(); }
    function readGet(address c) external view returns (uint256) { return Counter(c).get(); }
}

contract Self {
    uint256 public x = 1;
    function viaThis() external view returns (uint256) { return this.x(); }
}

contract Clock {
    uint256 public start;
    constructor() { start = block.timestamp; }
    function elapsed() external view returns (uint256) { return block.timestamp - start; }
    function sig() external pure returns (bytes4) { return msg.sig; }
    function add(uint256 a, uint256 b) external pure returns (uint256) { return a + b; }
}
