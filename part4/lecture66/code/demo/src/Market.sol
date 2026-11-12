// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Market {
    address public admin;
    IERC20[] public assets;

    constructor() {
        admin = msg.sender;
    }

    function addAsset(IERC20 asset) external {
        require(msg.sender == admin, "not admin");
        assets.push(asset);
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }
}
