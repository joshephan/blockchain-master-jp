// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20} from "./Market.sol";

// デモ用: トークンの失敗を捕まえて理由を残すコントラクト
contract Collector {
    uint256 public failures;

    event PullFailed(string reason);

    function pull(IERC20 token, uint256 amount) external returns (bool) {
        try token.transferFrom(msg.sender, address(this), amount) returns (bool ok) {
            return ok;
        } catch Error(string memory reason) {
            failures += 1;
            emit PullFailed(reason);
            return false;
        }
    }
}
