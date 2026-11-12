// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// EVMの形: 関数の途中で外を呼ぶ
contract Direct249 {
    uint256 public a;
    uint256 public b;
    bool public lastOk;

    function update(address target) external {
        a = 1;
        (bool ok,) = target.call(abi.encodeWithSignature("ping(address)", address(this)));
        lastOk = ok;
        b = 1;
    }

    function updateFailing(address target) external {
        a = 2;
        (bool ok,) = target.call(abi.encodeWithSignature("fail()"));
        lastOk = ok;
        b = 2;
    }
}
