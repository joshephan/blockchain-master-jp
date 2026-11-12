// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {MiniSafe} from "./MiniSafe.sol";

// 管理者の席に署名を集めて実行するマルチシグ(三つのうち二つ)。署名の収集、使用番号、実行
contract Safe58Test is Test {
    MockToken token;
    Market market;
    MiniSafe safe;
    uint256[3] keys = [uint256(0xA1), uint256(0xB2), uint256(0xC3)];
    address[3] signers; // アドレスの小さい順
    uint256[3] sortedKeys;

    function setUp() public {
        address[] memory o = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            o[i] = vm.addr(keys[i]);
        }
        // アドレス順に並べる
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (o[j] < o[i]) {
                    (o[i], o[j]) = (o[j], o[i]);
                    (keys[i], keys[j]) = (keys[j], keys[i]);
                }
            }
        }
        for (uint256 i = 0; i < 3; i++) {
            signers[i] = o[i];
            sortedKeys[i] = keys[i];
        }
        safe = new MiniSafe(o, 2);
        token = new MockToken();
        market = new Market(address(safe), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function _sig(uint256 key, bytes32 h) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, h);
        return abi.encodePacked(r, s, v);
    }

    function _two(bytes32 h, uint256 i, uint256 j) internal view returns (bytes[] memory s) {
        s = new bytes[](2);
        s[0] = _sig(sortedKeys[i], h);
        s[1] = _sig(sortedKeys[j], h);
    }

    function _addData() internal view returns (bytes memory) {
        return abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(75)));
    }

    function test_adminIsSafe() public view {
        assertEq(market.admin(), address(safe));
        assertEq(safe.threshold(), 2);
        assertEq(safe.ownerCount(), 3);
        assertEq(safe.nonce(), 0);
    }

    function test_twoSigsExecute() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        emit log_named_bytes32("txHash nonce 0", h);
        safe.execute(address(market), 0, d, _two(h, 0, 2)); // 送るアカウントは誰でも
        assertEq(market.assetCount(), 1);
        assertEq(safe.nonce(), 1);
    }

    function test_oneSigBelowThreshold() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        bytes[] memory s = new bytes[](1);
        s[0] = _sig(sortedKeys[0], h);
        vm.expectRevert(abi.encodeWithSelector(MiniSafe.BelowThreshold.selector, 1, 2));
        safe.execute(address(market), 0, d, s);
    }

    function test_sameSignerTwice() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        vm.expectRevert(abi.encodeWithSelector(MiniSafe.NotSorted.selector, signers[1], signers[1]));
        safe.execute(address(market), 0, d, _two(h, 1, 1));
    }

    function test_unsortedRejected() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        vm.expectRevert(abi.encodeWithSelector(MiniSafe.NotSorted.selector, signers[2], signers[0]));
        safe.execute(address(market), 0, d, _two(h, 2, 0));
    }

    function test_strangerSig() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        bytes[] memory s = new bytes[](2);
        s[0] = _sig(sortedKeys[0], h);
        s[1] = _sig(0xBAD, h);
        vm.expectRevert(abi.encodeWithSelector(MiniSafe.NotOwner.selector, vm.addr(0xBAD)));
        safe.execute(address(market), 0, d, s);
    }

    function test_replayRejected() public {
        bytes memory d = abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.DepositPaused));
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        bytes[] memory s = _two(h, 0, 1);
        safe.execute(address(market), 0, d, s);
        vm.expectPartialRevert(MiniSafe.NotOwner.selector); // もうnonce 1なのでハッシュが違い、別のアドレスが復元される
        safe.execute(address(market), 0, d, s);
    }

    function test_otherChainRejected() public {
        bytes memory d = _addData();
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        bytes[] memory s = _two(h, 0, 1);
        vm.chainId(2);
        assertTrue(safe.txHash(address(market), 0, d, 0) != h);
        vm.expectPartialRevert(MiniSafe.NotOwner.selector);
        safe.execute(address(market), 0, d, s);
    }

    function test_otherSafeRejected() public {
        address[] memory o = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            o[i] = signers[i];
        }
        MiniSafe safe2 = new MiniSafe(o, 2); // 同じ署名者、別のウォレットアドレス
        bytes memory d = _addData();
        bytes[] memory s = _two(safe.txHash(address(market), 0, d, 0), 0, 1);
        vm.expectPartialRevert(MiniSafe.NotOwner.selector);
        safe2.execute(address(market), 0, d, s);
    }

    function test_nonceOrder() public {
        bytes memory dPause = abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.DepositPaused));
        bytes memory dAdd = _addData();
        // nonce 1で先に署名しておいた取引は、nonce 0が使われる前は実行されない
        bytes[] memory s1 = _two(safe.txHash(address(market), 0, dPause, 1), 0, 1);
        vm.expectPartialRevert(MiniSafe.NotOwner.selector);
        safe.execute(address(market), 0, dPause, s1);
        safe.execute(address(market), 0, dAdd, _two(safe.txHash(address(market), 0, dAdd, 0), 1, 2));
        safe.execute(address(market), 0, dPause, s1);
        assertEq(uint8(market.status()), 1);
        assertEq(market.assetCount(), 1);
        assertEq(safe.nonce(), 2);
    }

    function test_failedCallKeepsNonce() public {
        bytes memory d = abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(90))); // 上限80を超える
        bytes32 h = safe.txHash(address(market), 0, d, 0);
        vm.expectPartialRevert(MiniSafe.CallFailed.selector);
        safe.execute(address(market), 0, d, _two(h, 0, 1));
        assertEq(safe.nonce(), 0); // 丸ごとリバートして番号も使わない
    }

    function test_changeThresholdOnlySelf() public {
        vm.prank(signers[0]);
        vm.expectRevert(abi.encodeWithSelector(MiniSafe.NotSelf.selector, signers[0]));
        safe.changeThreshold(3);
        bytes memory d = abi.encodeCall(MiniSafe.changeThreshold, (3));
        safe.execute(address(safe), 0, d, _two(safe.txHash(address(safe), 0, d, 0), 0, 1));
        assertEq(safe.threshold(), 3);
    }

    function test_signerAloneNotAdmin() public {
        vm.prank(signers[0]);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, signers[0]));
        market.setStatus(IMarket.MarketStatus.Frozen);
    }
}
