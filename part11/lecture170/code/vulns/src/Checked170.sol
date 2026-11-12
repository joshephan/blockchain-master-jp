// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// Ignorerに結果確認の一行を足した版。トイ、ローカルのforge専用。
contract IgnorerChecked {
    bool public done;

    error SendFailed(address to);

    function pay(address to, uint256 amount) external {
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert SendFailed(to);
        done = true;
    }

    receive() external payable {}
}
