// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// 受け取る関数なし。受け取ったNFTを送り出す関数もなし
contract Plain {}

// 受け取る関数で巻き戻す
contract Rejecter is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        revert("no thanks");
    }
}

// 決まった値ではない4バイトを返す
contract WrongMagic is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0x12345678;
    }
}

// 受け取る関数が動く瞬間に、トークンコントラクトが示す持ち主を記録しておく
contract Acceptor is IERC721Receiver {
    address public seenOwner;
    address public seenOperator;
    address public seenFrom;
    uint256 public calls;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata)
        external
        returns (bytes4)
    {
        seenOwner = IERC721(msg.sender).ownerOf(tokenId);
        seenOperator = operator;
        seenFrom = from;
        calls++;
        return IERC721Receiver.onERC721Received.selector;
    }
}

// 受け取る関数で終わりなく回る
contract Burner is IERC721Receiver {
    uint256 public n;

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        while (true) {
            n++;
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

// 景品一つをsafeTransferFromで当選者に送って終える
contract Prize {
    IERC721 public immutable nft;
    uint256 public immutable tokenId;
    bool public awarded;

    constructor(IERC721 nft_, uint256 tokenId_) {
        nft = nft_;
        tokenId = tokenId_;
    }

    function award(address winner) external {
        require(!awarded, "awarded");
        awarded = true;
        nft.safeTransferFrom(address(this), winner, tokenId);
    }
}
