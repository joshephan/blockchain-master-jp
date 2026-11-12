// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract None {
    function hello() external pure returns (uint256) { return 1; }
}

contract R {
    uint256 public hits;
    receive() external payable { hits += 1; }
}

contract F {
    uint256 public hits;
    fallback() external { hits += 1; }
}

contract FP {
    uint256 public hits;
    fallback() external payable { hits += 1; }
}

contract RF {
    string public last;
    receive() external payable { last = "receive"; }
    fallback() external payable { last = "fallback"; }
}

// 受け取ったcalldataをそのまま別のアドレスに渡すfallback
contract Fwd {
    address public target;
    constructor(address t) { target = t; }
    fallback(bytes calldata input) external returns (bytes memory) {
        (bool ok, bytes memory out) = target.call(input);
        require(ok, "forward failed");
        return out;
    }
}

// 受け取る側を送る三つの方法で呼ぶ (第55講)
contract Sender {
    constructor() payable {}
    function viaTransfer(address payable to) external { to.transfer(1); }
    function viaSend(address payable to) external returns (bool) { return to.send(1); }
    function viaCall(address payable to) external returns (bool ok) { (ok, ) = to.call{value: 1}(""); }
}

// 受け取る関数の中で何も書き込まない版
contract RQuiet {
    receive() external payable {}
}
