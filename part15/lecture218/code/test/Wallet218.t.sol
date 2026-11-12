// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./Base.sol";
import {LooseWallet218, Wallet218} from "../src/Wallet218.sol";

contract Wallet218Test is Base {
    uint256 internal ownerKey = 0xA11CE;
    address internal owner;
    address internal relayer = makeAddr("relayer");
    Wallet218 internal wallet;
    LooseWallet218 internal loose;

    function setUp() public {
        _setUpMarket();
        owner = vm.addr(ownerKey);
        wallet = new Wallet218(owner);
        loose = new LooseWallet218(owner);
        token.transfer(address(wallet), 500);
        token.transfer(address(loose), 500);
        vm.deal(relayer, 1 ether);
    }

    function _signFixed(uint256 n, address target, bytes memory data) internal view returns (uint8, bytes32, bytes32) {
        return vm.sign(ownerKey, wallet.digestOf(n, target, 0, data));
    }

    // 持ち主の鍵にはETHが0、ガスはrelayerが払う
    function test_relayerPaysOwnerSigns() public {
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        (uint8 v, bytes32 r, bytes32 s) = _signFixed(0, address(token), data);
        vm.prank(relayer, relayer);
        wallet.execute(0, address(token), 0, data, v, r, s);
        assertEq(token.balanceOf(makeAddr("bob")), 100);
        assertEq(owner.balance, 0);
        assertEq(wallet.nonce(), 1);
    }

    // 承認とMarketへの預け入れを署名一つ、トランザクション一つで
    function test_batchApproveDeposit() public {
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = address(token);
        datas[0] = abi.encodeCall(token.approve, (address(market), 100));
        targets[1] = address(market);
        datas[1] = abi.encodeCall(market.deposit, (address(token), 100));
        bytes32 digest = keccak256(abi.encode(block.chainid, address(wallet), uint256(0), targets, datas));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        vm.prank(relayer, relayer);
        wallet.executeBatch(0, targets, datas, v, r, s);
        assertEq(_deposited(address(wallet)), 100);
        assertEq(token.balanceOf(address(wallet)), 400);
    }

    // 材料がやること三つだけの版: 同じ署名が二回通る
    function test_looseSameSigPassesTwice() public {
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, keccak256(abi.encode(address(token), uint256(0), data)));
        loose.execute(address(token), 0, data, v, r, s);
        loose.execute(address(token), 0, data, v, r, s);
        assertEq(token.balanceOf(makeAddr("bob")), 200);
    }

    // 使用番号を入れた版: 同じ署名の二回目はBadNonce
    function test_sameSigRejected() public {
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        (uint8 v, bytes32 r, bytes32 s) = _signFixed(0, address(token), data);
        wallet.execute(0, address(token), 0, data, v, r, s);
        vm.expectRevert(abi.encodeWithSelector(Wallet218.BadNonce.selector, 1, 0));
        wallet.execute(0, address(token), 0, data, v, r, s);
        // 番号だけ1に上げて同じ署名を出しても材料が違うのでBadSigner
        vm.expectRevert(Wallet218.BadSigner.selector);
        wallet.execute(1, address(token), 0, data, v, r, s);
        assertEq(token.balanceOf(makeAddr("bob")), 100);
    }

    // チェーン番号を入れた版: 別のチェーン番号で作った署名はBadSigner
    function test_otherChainSigRejected() public {
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        uint256 here = vm.getChainId();
        vm.chainId(1);
        (uint8 v, bytes32 r, bytes32 s) = _signFixed(0, address(token), data);
        vm.chainId(here);
        vm.expectRevert(Wallet218.BadSigner.selector);
        wallet.execute(0, address(token), 0, data, v, r, s);
    }

    // アカウントのアドレスを入れた版: 同じ持ち主の別のウォレットに出した署名はBadSigner
    function test_otherWalletSigRejected() public {
        Wallet218 second = new Wallet218(owner);
        token.transfer(address(second), 500);
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        (uint8 v, bytes32 r, bytes32 s) = _signFixed(0, address(token), data);
        vm.expectRevert(Wallet218.BadSigner.selector);
        second.execute(0, address(token), 0, data, v, r, s);
    }

    // でたらめな署名: ecrecoverがaddress(0)を返してBadSigner
    function test_garbageSigRejected() public {
        bytes memory data = abi.encodeCall(token.transfer, (makeAddr("bob"), 100));
        vm.expectRevert(Wallet218.BadSigner.selector);
        wallet.execute(0, address(token), 0, data, 29, bytes32(0), bytes32(0));
    }
}
