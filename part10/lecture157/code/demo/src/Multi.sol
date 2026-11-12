// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// OpenZeppelin Contracts 5.4.0のERC1155に、誰でも発行できるmintBatchだけを足したトークン(デモ用)
contract Multi is ERC1155 {
    constructor() ERC1155("") {}

    // id 1からnまで、それぞれamount個
    function mintRange(address to, uint256 n, uint256 amount) external {
        uint256[] memory ids = new uint256[](n);
        uint256[] memory values = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = i + 1;
            values[i] = amount;
        }
        _mintBatch(to, ids, values, "");
    }
}

// 受け取る関数なし
contract NoHook {}
