// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract T1ok {
    address public owner;

    function pay() external {
        payable(owner).transfer(1 ether);
    }
}
