// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

contract Holder {
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }
}

contract HolderChecked {
    IERC20 public token;

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "token is zero");
        token = token_;
    }
}
