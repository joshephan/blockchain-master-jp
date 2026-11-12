// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// OpenZeppelin Contracts 5.4.0のERC721に、誰でも発行できるmintだけを足したトークン(デモ用)
contract Nft is ERC721 {
    constructor() ERC721("Deed", "DEED") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
