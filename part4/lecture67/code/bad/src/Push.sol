// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Push {
    function pick(uint256[] calldata xs) public pure returns (uint256[] memory) {
        uint256[] memory r;
        for (uint256 i = 0; i < xs.length; i++) {
            if (xs[i] % 2 == 0) r.push(xs[i]);
        }
        return r;
    }
}
