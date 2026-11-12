// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract AfterEarly {
    uint256 public post;
    uint256 public calls;

    modifier tail() {
        _;
        post += 1;
    }

    function early(bool stop) external tail returns (uint256) {
        if (stop) {
            return 5;
        }
        calls += 1;
        return 9;
    }
}
