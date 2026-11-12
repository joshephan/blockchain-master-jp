// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market, IERC20} from "./Market.sol";

contract Types {
    function info()
        external
        pure
        returns (string memory name, bytes4 iid, uint64 maxU64, uint256 creationLen, uint256 runtimeLen)
    {
        name = type(Market).name;
        iid = type(IERC20).interfaceId;
        maxU64 = type(uint64).max;
        creationLen = type(Market).creationCode.length;
        runtimeLen = type(Market).runtimeCode.length;
    }
}
