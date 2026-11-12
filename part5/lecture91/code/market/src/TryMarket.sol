// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market, IERC20} from "./Market.sol";

// デモ用: depositのトークン呼び出しをtryで囲み、catchを空にした版 (プロジェクトには入れない)
contract TryMarket is Market {
    function depositTry(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        require(amount > 0, "zero amount");
        _credit({asset: asset, user: msg.sender, amount: amount});
        try IERC20(asset).transferFrom(msg.sender, address(this), amount) returns (bool ok) {
            require(ok, "transferFrom failed");
        } catch {
        }
    }

    function depositTryRevert(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        require(amount > 0, "zero amount");
        _credit({asset: asset, user: msg.sender, amount: amount});
        try IERC20(asset).transferFrom(msg.sender, address(this), amount) returns (bool ok) {
            require(ok, "transferFrom failed");
        } catch Error(string memory reason) {
            revert(string.concat("token failed: ", reason));
        }
    }
}
