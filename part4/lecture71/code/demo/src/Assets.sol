// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Ratio is uint8; // 担保比率、倍率100

contract AssetsNoFlag {
    mapping(address asset => Ratio collateralRatio) public assetConfig;
    address public admin = msg.sender;

    function setAsset(address asset, Ratio ratio) external {
        require(msg.sender == admin, "not admin");
        assetConfig[asset] = ratio;
    }
}

contract AssetsListed {
    struct AssetConfig {
        Ratio collateralRatio;
        bool listed;
    }

    mapping(address asset => AssetConfig) public assetConfig;
    address public admin = msg.sender;

    function setAsset(address asset, Ratio ratio) external {
        require(msg.sender == admin, "not admin");
        assetConfig[asset] = AssetConfig({collateralRatio: ratio, listed: true});
    }
}
