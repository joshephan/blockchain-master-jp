// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {GovToken, Gov58} from "./GovParts58.sol";
import {TimelockController} from "../vendor/oz/governance/TimelockController.sol";
import {IGovernor} from "../vendor/oz/governance/IGovernor.sol";

// ガバナンストークンの票がどこに積み上がるかを見るテスト。Marketのソースはそのまま、admin = タイムロック
contract Politics271Test is Test {
    GovToken gtoken;
    TimelockController tl;
    Gov58 gov;
    Market market;
    MockToken token;
    address d1 = address(0xD1);
    address d2 = address(0xD2);
    address d3 = address(0xD3);
    address d4 = address(0xD4);
    address d5 = address(0xD5);
    address bob = address(0xB0B);

    function setUp() public {
        gtoken = new GovToken(1000); // 1000個全部デプロイしたアカウントへ
        address[] memory none = new address[](0);
        tl = new TimelockController(2 days, none, none, address(this));
        gov = new Gov58(gtoken, tl, 1, 50, 0, 4);
        tl.grantRole(tl.PROPOSER_ROLE(), address(gov));
        tl.grantRole(tl.CANCELLER_ROLE(), address(gov));
        tl.grantRole(tl.EXECUTOR_ROLE(), address(0));
        tl.renounceRole(tl.DEFAULT_ADMIN_ROLE(), address(this));
        token = new MockToken();
        market = new Market(address(tl), Rate.wrap(5e16), Ratio.wrap(80));
        token.transfer(bob, 1000);
        // 代理人五人に450、残りの550はデプロイしたアカウントが委任せずに持っている
        _give(d1, 160);
        _give(d2, 120);
        _give(d3, 90);
        _give(d4, 50);
        _give(d5, 30);
        vm.roll(10);
    }

    function _give(address who, uint256 amount) internal {
        gtoken.transfer(who, amount);
        vm.prank(who);
        gtoken.delegate(who);
    }

    function _propose(bytes memory data, string memory desc)
        internal
        returns (uint256 id, address[] memory t, uint256[] memory v, bytes[] memory c)
    {
        t = new address[](1);
        v = new uint256[](1);
        c = new bytes[](1);
        t[0] = address(market);
        c[0] = data;
        vm.prank(d1);
        id = gov.propose(t, v, c, desc);
        vm.roll(vm.getBlockNumber() + 2);
    }

    function _addAsset() internal pure returns (bytes memory) {
        return abi.encodeCall(IMarket.addAsset, (IERC20(address(0x7070)), Ratio.wrap(75)));
    }

    // アドレスを四つに分けても票の合計はそのまま
    function test_splitAddsNoVotes() public {
        address[4] memory parts = [address(0xA1), address(0xA2), address(0xA3), address(0xA4)];
        uint256 before = gtoken.getVotes(d1);
        for (uint256 i = 0; i < 4; i++) {
            vm.prank(d1);
            gtoken.transfer(parts[i], 40);
            vm.prank(parts[i]);
            gtoken.delegate(parts[i]);
        }
        uint256 sum;
        for (uint256 i = 0; i < 4; i++) {
            sum += gtoken.getVotes(parts[i]);
        }
        assertEq(before, 160);
        assertEq(gtoken.getVotes(d1), 0);
        assertEq(sum, 160);
    }

    // 委任していない550は票がなく、定足数の分母には入る
    function test_idleTokensHaveNoVotes() public view {
        assertEq(gtoken.balanceOf(address(this)), 550);
        assertEq(gtoken.getVotes(address(this)), 0);
        uint256 delegated = gtoken.getVotes(d1) + gtoken.getVotes(d2) + gtoken.getVotes(d3)
            + gtoken.getVotes(d4) + gtoken.getVotes(d5);
        assertEq(delegated, 450);
        assertEq(gov.quorum(9), 40);
    }

    // 代理人一人が単独で定足数を満たし、提案を可決させる
    function test_oneDelegatePasses() public {
        (uint256 id,,,) = _propose(_addAsset(), "list 0x7070 at 75");
        vm.prank(d1);
        gov.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + 50);
        assertEq(uint256(gov.state(id)), uint256(IGovernor.ProposalState.Succeeded));
    }

    // 代理人二人(280)が残りの三人(170)を上回る
    function test_twoDelegatesOutvoteThree() public {
        (uint256 id,,,) = _propose(_addAsset(), "list 0x7070 at 75");
        vm.prank(d1);
        gov.castVote(id, 1);
        vm.prank(d2);
        gov.castVote(id, 1);
        vm.prank(d3);
        gov.castVote(id, 0);
        vm.prank(d4);
        gov.castVote(id, 0);
        vm.prank(d5);
        gov.castVote(id, 0);
        (uint256 against, uint256 forVotes,) = gov.proposalVotes(id);
        assertEq(forVotes, 280);
        assertEq(against, 170);
        vm.roll(vm.getBlockNumber() + 50);
        assertEq(uint256(gov.state(id)), uint256(IGovernor.ProposalState.Succeeded));
    }

    // お金を預けたbobは票が0。停止の提案が待っているあいだに引き出して出ていく
    function test_depositorHasNoVoteButCanLeave() public {
        vm.prank(address(tl));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        vm.prank(bob);
        market.deposit(address(token), 100);
        (uint256 id, address[] memory t, uint256[] memory v, bytes[] memory c) =
            _propose(abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.DepositPaused)), "pause deposits");
        vm.prank(bob);
        uint256 weight = gov.castVote(id, 0);
        assertEq(weight, 0);
        vm.prank(d1);
        gov.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + 50);
        gov.queue(t, v, c, keccak256(bytes("pause deposits")));
        // 待機2日のあいだにbobが預けた100を全部引き出す
        vm.prank(bob);
        market.withdraw(address(token), 100);
        assertEq(token.balanceOf(bob), 1000);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("pause deposits")));
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.DepositPaused));
    }

    // 眠っていた550が一回の委任で目を覚まし、代理人五人(450)を全員上回る
    function test_idleHolderWakesUp() public {
        gtoken.delegate(address(this));
        vm.roll(vm.getBlockNumber() + 1);
        assertEq(gtoken.getVotes(address(this)), 550);
        (uint256 id,,,) = _propose(_addAsset(), "list 0x7070 at 75");
        gov.castVote(id, 1);
        vm.prank(d1);
        gov.castVote(id, 0);
        vm.prank(d2);
        gov.castVote(id, 0);
        vm.prank(d3);
        gov.castVote(id, 0);
        vm.prank(d4);
        gov.castVote(id, 0);
        vm.prank(d5);
        gov.castVote(id, 0);
        (uint256 against, uint256 forVotes,) = gov.proposalVotes(id);
        assertEq(forVotes, 550);
        assertEq(against, 450);
        vm.roll(vm.getBlockNumber() + 50);
        assertEq(uint256(gov.state(id)), uint256(IGovernor.ProposalState.Succeeded));
    }

    // 金庫(タイムロック)が持つトークンは票がなかったが、投票で委任すると一人の代理人に積み上がる
    function test_treasuryVotesMovedByVote() public {
        gtoken.transfer(address(tl), 550);
        assertEq(gtoken.getVotes(address(tl)), 0);
        address[] memory t = new address[](1);
        uint256[] memory v = new uint256[](1);
        bytes[] memory c = new bytes[](1);
        t[0] = address(gtoken);
        c[0] = abi.encodeWithSignature("delegate(address)", d1);
        vm.prank(d1);
        uint256 id = gov.propose(t, v, c, "delegate treasury to d1");
        vm.roll(vm.getBlockNumber() + 2);
        vm.prank(d1);
        gov.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + 50);
        gov.queue(t, v, c, keccak256(bytes("delegate treasury to d1")));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("delegate treasury to d1")));
        assertEq(gtoken.getVotes(d1), 710);
    }
}
