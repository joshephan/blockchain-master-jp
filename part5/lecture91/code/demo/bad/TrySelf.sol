// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TrySelf {
    function check(uint256 x) public pure {
        require(x > 0, "zero");
    }

    function run(uint256 x) external pure returns (string memory) {
        try check(x) {
            return "ok";
        } catch Error(string memory reason) {
            return reason;
        }
    }
}
