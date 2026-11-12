// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";

interface IStore {
    function setValue(uint256) external;
    function getValue() external view returns (uint256);
}

contract Value252Test is Test {
    function test_valueOnNonPayable() public {
        IStore s = IStore(address(0x4242));
        s.setValue{value: 0}(1);
    }
}
