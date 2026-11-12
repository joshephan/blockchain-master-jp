// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract AssetList {
    enum MarketStatus { Active, DepositPaused, Frozen }

    address[8] public assets;
    MarketStatus public status;

    function setAsset(uint256 i, address token) external {
        assets[i] = token;
    }

    function listedCount() external view returns (uint256 n) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] != address(0)) {
                n += 1;
            }
        }
    }
}
