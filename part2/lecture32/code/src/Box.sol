// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PriceLogic {
    uint256 public price;

    function set(uint256 v) external {
        price = v;
    }
}

contract Box {
    uint256 public price;

    function setVia(address logic, uint256 v) external {
        (bool ok, ) = logic.delegatecall(abi.encodeCall(PriceLogic.set, (v)));
        require(ok);
    }
}
