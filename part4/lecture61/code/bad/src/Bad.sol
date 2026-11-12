// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bad {
    function use(uint256 x, function (uint256) internal pure returns (uint256) f)
        external pure returns (uint256)
    {
        return f(x);
    }
}
