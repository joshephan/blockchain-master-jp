// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

/// @notice 状態を変えながらMarketを呼ぶ側(ハンドラー)。入力はMarketが実際に読む範囲に狭める
contract MarketHandler is Test {
    Market public market;
    MockToken[3] public tokens; // 0・1は上場、2は上場しない
    address[3] public actors;
    address public admin;
    bool public tuned; // 市場を止めたりトークンを壊したりする呼び出しをまれに

    // 帳簿の外で別に数える値(ゴースト)
    mapping(address asset => uint256) public netDeposited;
    uint256 public panics;
    uint256 public unexpected;
    uint256 public withdrawWhileFrozen; // Frozenで成功した引き出し(第46章の版ではできる)
    uint256 public withdrawBlocked; // 自分の分の範囲内、トークンも正常なのに失敗した引き出し
    uint256 public depositWhileNotActive;
    uint256 public depositUnlisted;
    mapping(bytes4 sel => uint256) public failCount;
    uint256 public okDeposit;
    uint256 public okWithdraw;

    constructor(Market m, MockToken[3] memory t, address[3] memory a, address admin_, bool tuned_) {
        tuned = tuned_;
        market = m;
        tokens = t;
        actors = a;
        admin = admin_;
    }

    function _token(uint256 seed) internal view returns (MockToken) {
        return tokens[seed % 3];
    }

    // 失敗した呼び出しの巻き戻りデータの先頭4バイトを分類
    function _record(bytes memory err) internal {
        bytes4 sel = bytes4(err);
        failCount[sel]++;
        if (sel == 0x4e487b71) {
            panics++;
            return;
        }
        if (
            sel == IMarket.ZeroAmount.selector || sel == IMarket.InsufficientDeposit.selector
                || sel == IMarket.NotActive.selector || sel == IMarket.MarketFrozen.selector
                || sel == IMarket.NotListed.selector || sel == 0x08c379a0 // Error(string): 壊れたトークンの"token paused"
        ) return;
        unexpected++;
    }

    function deposit(uint256 who, uint256 assetSeed, uint256 amount) external {
        address user = actors[who % 3];
        MockToken t = _token(assetSeed);
        amount = _bound(amount, 0, t.balanceOf(user));
        IMarket.MarketStatus s = market.status();
        vm.prank(user);
        try market.deposit(address(t), amount) {
            okDeposit++;
            netDeposited[address(t)] += amount;
            if (s != IMarket.MarketStatus.Active) depositWhileNotActive++;
            if (assetSeed % 3 == 2) depositUnlisted++;
        } catch (bytes memory err) {
            _record(err);
        }
    }

    function withdraw(uint256 who, uint256 assetSeed, uint256 amount) external {
        address user = actors[who % 3];
        MockToken t = _token(assetSeed);
        (Amount dep,,,) = market.positions(address(t), user);
        amount = _bound(amount, 0, Amount.unwrap(dep) + 10);
        IMarket.MarketStatus s = market.status();
        bool shouldPass = amount > 0 && amount <= Amount.unwrap(dep) && !t.broken();
        vm.prank(user);
        try market.withdraw(address(t), amount) {
            okWithdraw++;
            netDeposited[address(t)] -= amount;
            if (s == IMarket.MarketStatus.Frozen) withdrawWhileFrozen++;
        } catch (bytes memory err) {
            _record(err);
            if (shouldPass) withdrawBlocked++;
        }
    }

    function withdrawAll(uint256 who, uint256 assetSeed) external {
        address user = actors[who % 3];
        MockToken t = _token(assetSeed);
        (Amount dep,,,) = market.positions(address(t), user);
        IMarket.MarketStatus s = market.status();
        bool shouldPass = Amount.unwrap(dep) > 0 && !t.broken();
        vm.prank(user);
        try market.withdrawAll(address(t)) {
            okWithdraw++;
            netDeposited[address(t)] -= Amount.unwrap(dep);
            if (s == IMarket.MarketStatus.Frozen) withdrawWhileFrozen++;
        } catch (bytes memory err) {
            _record(err);
            if (shouldPass) withdrawBlocked++;
        }
    }

    function setStatus(uint8 s) external {
        uint8 v = s % 3;
        if (tuned) v = s % 10 < 7 ? 0 : (s % 10 < 9 ? 1 : 2); // 十回に七回はActive、二回はDepositPaused、一回はFrozen
        vm.prank(admin);
        market.setStatus(IMarket.MarketStatus(v));
    }

    function setBroken(uint256 assetSeed, bool b) external {
        if (tuned && b) b = (assetSeed / 3) % 10 == 0; // 故障は十回に一回
        _token(assetSeed).setBroken(b);
    }

    // Marketを通さずにトークンを直接送る(帳簿外のトークン)
    function donate(uint256 who, uint256 assetSeed, uint256 amount) external {
        address user = actors[who % 3];
        MockToken t = _token(assetSeed);
        if (t.broken()) return;
        amount = _bound(amount, 0, t.balanceOf(user));
        vm.prank(user);
        t.transfer(address(market), amount);
    }
}

/// @notice Marketの不変条件。何回どんな順番で呼んでも常に成り立たなければならないもの
contract MarketInvariantTest is Test {
    Market market;
    MarketHandler handler;
    MockToken[3] tokens;
    address[3] actors = [address(0x1001), address(0x2002), address(0x3003)];

    function _tuned() internal pure virtual returns (bool) {
        return false;
    }

    function setUp() public {
        for (uint256 i = 0; i < 3; i++) {
            tokens[i] = new MockToken();
            for (uint256 j = 0; j < 3; j++) {
                tokens[i].transfer(actors[j], 300);
            }
        }
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(tokens[0])), Ratio.wrap(75));
        market.addAsset(IERC20(address(tokens[1])), Ratio.wrap(50));
        handler = new MarketHandler(market, tokens, actors, address(this), _tuned());
        targetContract(address(handler));
    }

    // 合計の欄 = アカウントの欄の和(アカウント一覧はテストが持っている)
    function invariant_totalsMatchPositions() public view {
        for (uint256 i = 0; i < 3; i++) {
            address a = address(tokens[i]);
            uint256 sum = 0;
            for (uint256 j = 0; j < 3; j++) {
                (Amount d,,,) = market.positions(a, actors[j]);
                sum += Amount.unwrap(d);
            }
            assertEq(Amount.unwrap(market.totalDeposits(a)), sum);
        }
    }

    // 合計の欄 = 成功した預け入れから成功した引き出しを引いた値(ハンドラーが別に数える)
    function invariant_totalsMatchGhost() public view {
        for (uint256 i = 0; i < 3; i++) {
            address a = address(tokens[i]);
            assertEq(Amount.unwrap(market.totalDeposits(a)), handler.netDeposited(a));
        }
    }

    // トークン残高が帳簿より少ないことはない(直接送られたトークンのせいで大きいことはある)
    function invariant_tokenCoversLedger() public view {
        for (uint256 i = 0; i < 3; i++) {
            address a = address(tokens[i]);
            assertGe(tokens[i].balanceOf(address(market)), Amount.unwrap(market.totalDeposits(a)));
        }
    }

    // ドキュメント(IMarket)に書いた文: Activeでなければ預け入れを止める。引き出しはどの状態でもできる。上場していない資産は預けられない
    function invariant_statusRules() public view {
        assertEq(handler.depositWhileNotActive(), 0);
        assertEq(handler.withdrawBlocked(), 0);
        assertEq(handler.depositUnlisted(), 0);
    }

    // 失敗はドキュメントに書いたエラーだけ。assert(Panic 0x01)・オーバーフロー(Panic 0x11)は一度もない
    function invariant_failuresAreListed() public view {
        assertEq(handler.panics(), 0);
        assertEq(handler.unexpected(), 0);
    }
}

/// @notice 同じ不変条件、ハンドラーだけを調整した版(停止・故障の呼び出しをまれに)
contract MarketInvariantTunedTest is MarketInvariantTest {
    function _tuned() internal pure override returns (bool) {
        return true;
    }
}

/// @notice 不変条件を間違えて書いた版: トークン残高 = 帳簿(直接送られたトークンを忘れる)
contract WrongInvariantTest is Test {
    Market market;
    MarketHandler handler;
    MockToken[3] tokens;
    address[3] actors = [address(0x1001), address(0x2002), address(0x3003)];

    function setUp() public {
        for (uint256 i = 0; i < 3; i++) {
            tokens[i] = new MockToken();
            for (uint256 j = 0; j < 3; j++) {
                tokens[i].transfer(actors[j], 300);
            }
        }
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(tokens[0])), Ratio.wrap(75));
        market.addAsset(IERC20(address(tokens[1])), Ratio.wrap(50));
        handler = new MarketHandler(market, tokens, actors, address(this), false);
        targetContract(address(handler));
    }

    function invariant_tokenEqualsLedger() public view {
        for (uint256 i = 0; i < 2; i++) {
            address a = address(tokens[i]);
            assertEq(tokens[i].balanceOf(address(market)), Amount.unwrap(market.totalDeposits(a)));
        }
    }
}

/// @notice ハンドラーなしでMarketを直接叩く版(入力を狭めない)
contract NoHandlerInvariantTest is Test {
    Market market;
    MockToken token;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        targetContract(address(market));
    }

    function invariant_tokenCoversLedger() public view {
        assertGe(token.balanceOf(address(market)), Amount.unwrap(market.totalDeposits(address(token))));
    }
}

/// @notice 同じランダムな呼び出し2,000回(番号iのkeccakで選ぶ)を二つのハンドラーに入れ、成功した呼び出しを数える
contract HandlerYieldTest is Test {
    function _run(bool tuned) internal returns (MarketHandler h) {
        MockToken[3] memory tokens;
        address[3] memory actors = [address(0x1001), address(0x2002), address(0x3003)];
        for (uint256 i = 0; i < 3; i++) {
            tokens[i] = new MockToken();
            for (uint256 j = 0; j < 3; j++) {
                tokens[i].transfer(actors[j], 300);
            }
        }
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(tokens[0])), Ratio.wrap(75));
        market.addAsset(IERC20(address(tokens[1])), Ratio.wrap(50));
        h = new MarketHandler(market, tokens, actors, address(this), tuned);
        for (uint256 i = 0; i < 2000; i++) {
            uint256 r = uint256(keccak256(abi.encode(i)));
            uint256 a = uint256(keccak256(abi.encode(r)));
            uint256 k = r % 6;
            if (k == 0) h.deposit(a, a >> 8, a >> 16);
            else if (k == 1) h.withdraw(a, a >> 8, a >> 16);
            else if (k == 2) h.withdrawAll(a, a >> 8);
            else if (k == 3) h.setStatus(uint8(a));
            else if (k == 4) h.setBroken(a, (a >> 8) % 2 == 1);
            else h.donate(a, a >> 8, a >> 16);
        }
    }

    function test_yield() public {
        MarketHandler plain = _run(false);
        MarketHandler tuned = _run(true);
        console.log("plain ok deposit", plain.okDeposit(), "ok withdraw", plain.okWithdraw());
        console.log("tuned ok deposit", tuned.okDeposit(), "ok withdraw", tuned.okWithdraw());
        console.log("plain NotActive", plain.failCount(IMarket.NotActive.selector), "MarketFrozen", plain.failCount(IMarket.MarketFrozen.selector));
        console.log("tuned NotActive", tuned.failCount(IMarket.NotActive.selector), "MarketFrozen", tuned.failCount(IMarket.MarketFrozen.selector));
        console.log("plain token paused", plain.failCount(0x08c379a0), "tuned token paused", tuned.failCount(0x08c379a0));
        console.log("plain frozen withdraw ok", plain.withdrawWhileFrozen(), "tuned", tuned.withdrawWhileFrozen());
    }
}
