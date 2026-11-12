// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";

interface IReceiver721 {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// 第156講: ERC-721の移転二つだけを書いたテスト用NFT。transferFromは戻り値なし(EIP-721のまま)、
// safeTransferFromは受け取る側がコントラクトならonERC721Receivedを呼び、決まった4バイトを確認
contract MiniNft {
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, uint256 tokenId) external {
        ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender, "not owner");
        getApproved[tokenId] = to;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "not owner");
        require(msg.sender == from || getApproved[tokenId] == msg.sender, "not allowed");
        delete getApproved[tokenId];
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
        if (to.code.length > 0) {
            bytes4 got = IReceiver721(to).onERC721Received(msg.sender, from, tokenId, "");
            require(got == IReceiver721.onERC721Received.selector, "bad receiver");
        }
    }
}

// 第156講: MarketにNFTのアドレスを資産として上場したとき。transferFromのセレクター(0x23b872dd)はERC-20と同じだが
// 戻り値がないので、Marketのboolの読み取りでdeposit全体が巻き戻る。MarketはonERC721Receivedがない
contract NftTest is Test {
    Market market;
    MiniNft nft;
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        nft = new MiniNft();
        nft.mint(alice, 1);
        nft.mint(alice, 2);
    }

    function test_nftDepositReverts() public {
        market.addAsset(IERC20(address(nft)), Ratio.wrap(75));
        vm.startPrank(alice);
        nft.approve(address(market), 1);
        (bool ok, bytes memory data) =
            address(market).call(abi.encodeWithSignature("deposit(address,uint256)", address(nft), 1));
        vm.stopPrank();
        assertFalse(ok);
        assertEq(data.length, 0);
        assertEq(nft.ownerOf(1), alice);
        assertEq(Amount.unwrap(market.totalDeposits(address(nft))), 0);
        assertEq(IERC20.transferFrom.selector, MiniNft.transferFrom.selector);
    }

    function test_nftSentDirectlyStays() public {
        vm.prank(alice);
        (bool ok,) = address(nft)
            .call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(market), 2));
        assertFalse(ok);
        assertEq(nft.ownerOf(2), alice);
        vm.prank(alice);
        nft.transferFrom(alice, address(market), 2);
        assertEq(nft.ownerOf(2), address(market));
    }
}
