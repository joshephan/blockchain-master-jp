// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

contract Market {
    IERC20[] public assets;

    function addAsset(IERC20 a) external {
        assets.push(a);
    }

    function reserves() external view returns (uint256[] memory) {
        uint256[] memory vals = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            vals[i] = assets[i].balanceOf(address(this));
        }
        return vals;
    }
}

contract Token is IERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
}
