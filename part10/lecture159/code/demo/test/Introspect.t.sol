// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Nft} from "../src/Nft.sol";
import {Multi} from "../src/Multi.sol";
import {OzToken} from "../src/OzToken.sol";
import {Asset, Vault} from "../src/Vault.sol";
import {Liar, SelectiveLiar, GasHog} from "../src/Claims.sol";
import {Market, IERC20 as MarketIERC20, Ratio, Rate} from "../src/market/Market.sol";
import {IMarket} from "../src/market/IMarket.sol";

contract IntrospectTest is Test {
    function test_ids() public pure {
        console.log("IERC165");
        console.logBytes4(type(IERC165).interfaceId);
        console.log("IERC20 (OZ)");
        console.logBytes4(type(IERC20).interfaceId);
        console.log("IERC721");
        console.logBytes4(type(IERC721).interfaceId);
        console.log("IERC721Receiver");
        console.logBytes4(type(IERC721Receiver).interfaceId);
        console.log("IERC1155");
        console.logBytes4(type(IERC1155).interfaceId);
        console.log("IERC1155Receiver");
        console.logBytes4(type(IERC1155Receiver).interfaceId);
        console.log("IERC4626");
        console.logBytes4(type(IERC4626).interfaceId);
        console.log("Market IERC20");
        console.logBytes4(type(MarketIERC20).interfaceId);
        console.log("IMarket");
        console.logBytes4(type(IMarket).interfaceId);
    }

    function _report(string memory name, address a) internal view {
        bool is165 = ERC165Checker.supportsERC165(a);
        bool is721 = ERC165Checker.supportsInterface(a, type(IERC721).interfaceId);
        bool is1155 = ERC165Checker.supportsInterface(a, type(IERC1155).interfaceId);
        console.log(name, is165, is721, is1155);
    }

    function test_detect() public {
        _report("Nft", address(new Nft()));
        _report("Multi", address(new Multi()));
        _report("OzToken", address(new OzToken(1)));
        _report("Vault", address(new Vault(IERC20(address(new Asset())))));
        _report("Market", address(new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80))));
        _report("Liar", address(new Liar()));
        _report("SelectiveLiar", address(new SelectiveLiar()));
        _report("GasHog", address(new GasHog()));
        _report("EOA", address(0xB0B));
    }

    // 直接聞くと: Liarは0xffffffffにもtrue、GasHogは3万ガス以内に終わらない
    function test_rawAnswers() public {
        Liar l = new Liar();
        console.log("Liar ffffffff", l.supportsInterface(0xffffffff));
        GasHog g = new GasHog();
        (bool ok,) = address(g).staticcall{gas: 30000}(abi.encodeWithSelector(0x01ffc9a7, bytes4(0x01ffc9a7)));
        console.log("GasHog with 30000 gas ok", ok);
        uint256 before = gasleft();
        g.supportsInterface(0x01ffc9a7);
        console.log("GasHog gas", before - gasleft());
        Market m = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        (bool ok2, bytes memory d2) =
            address(m).staticcall{gas: 30000}(abi.encodeWithSelector(0x01ffc9a7, bytes4(0x01ffc9a7)));
        console.log("Market ok", ok2, d2.length);
    }

    // SelectiveLiarをERC-721と信じて呼ぶと
    function test_selectiveLiarCall() public {
        SelectiveLiar s = new SelectiveLiar();
        assertTrue(ERC165Checker.supportsInterface(address(s), type(IERC721).interfaceId));
        (bool ok, bytes memory d) = address(s).call(abi.encodeCall(IERC721.ownerOf, (1)));
        console.log("ownerOf ok", ok, d.length);
    }
}
