// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 講義用のトークン。minterだけが新しく発行する
contract ToyToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public owner;
    address public minter;

    error NotOwner();
    error NotMinter();

    constructor() {
        owner = msg.sender;
        minter = msg.sender;
    }

    // 発行の権限を誰に渡すかはownerの席が決める
    function setMinter(address m) external {
        if (msg.sender != owner) revert NotOwner();
        minter = m;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter();
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    // 講義用なので承認の確認なし
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// 出どころ1: 借りた人が払った利息。担保の確認は省略(利息の流れだけ)
contract LendPool202 {
    ToyToken public immutable token;
    uint256 public immutable ratePerYear; // 倍率は10の18乗
    uint256 public cash; // 金庫にあるトークン
    uint256 public lent; // 貸し出した元本
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    address public borrower;
    uint256 public borrowedAt;

    error NoCash();

    constructor(ToyToken t, uint256 rate) {
        token = t;
        ratePerYear = rate;
    }

    function totalAssets() public view returns (uint256) {
        return cash + lent;
    }

    function deposit(uint256 amount) external {
        uint256 s = totalShares == 0 ? amount : amount * totalShares / totalAssets();
        token.transferFrom(msg.sender, address(this), amount);
        cash += amount;
        totalShares += s;
        sharesOf[msg.sender] += s;
    }

    function withdraw(uint256 s) external returns (uint256 amount) {
        amount = s * totalAssets() / totalShares;
        if (amount > cash) revert NoCash();
        sharesOf[msg.sender] -= s;
        totalShares -= s;
        cash -= amount;
        token.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        if (amount > cash) revert NoCash();
        borrower = msg.sender;
        borrowedAt = block.timestamp;
        cash -= amount;
        lent += amount;
        token.transfer(msg.sender, amount);
    }

    function owed() public view returns (uint256) {
        return lent + lent * ratePerYear * (block.timestamp - borrowedAt) / 365 days / 1e18;
    }

    // 預け入れ者の持ち分が増える行。このtransferFromが収益の出どころ
    function repay() external {
        uint256 amount = owed();
        token.transferFrom(msg.sender, address(this), amount);
        cash += amount;
        lent = 0;
    }
}

// 出どころ2: 取引した人が払った手数料。定数積、手数料0.3%はプールに残す
contract FeePool202 {
    ToyToken public immutable a;
    ToyToken public immutable b;
    uint256 public reserveA;
    uint256 public reserveB;

    constructor(ToyToken a_, ToyToken b_) {
        a = a_;
        b = b_;
    }

    function addLiquidity(uint256 inA, uint256 inB) external {
        a.transferFrom(msg.sender, address(this), inA);
        b.transferFrom(msg.sender, address(this), inB);
        reserveA += inA;
        reserveB += inB;
    }

    function removeAll(address to) external returns (uint256 outA, uint256 outB) {
        outA = reserveA;
        outB = reserveB;
        reserveA = 0;
        reserveB = 0;
        a.transfer(to, outA);
        b.transfer(to, outB);
    }

    function swapAForB(uint256 inA) external returns (uint256 outB) {
        uint256 inFee = inA * 997 / 1000;
        outB = reserveB * inFee / (reserveA + inFee);
        a.transferFrom(msg.sender, address(this), inA);
        reserveA += inA; // 手数料の分まで丸ごとプールに残る行
        reserveB -= outB;
        b.transfer(msg.sender, outB);
    }

    function swapBForA(uint256 inB) external returns (uint256 outA) {
        uint256 inFee = inB * 997 / 1000;
        outA = reserveA * inFee / (reserveB + inFee);
        b.transferFrom(msg.sender, address(this), inB);
        reserveB += inB;
        reserveA -= outA;
        a.transfer(msg.sender, outA);
    }
}

// 出どころ3: 新しく発行したトークン。終了時刻まで毎秒rewardPerSecondを発行して配る(預けた人一人が前提)
contract Farm202 {
    ToyToken public immutable stakeToken;
    ToyToken public immutable rewardToken;
    uint256 public immutable rewardPerSecond;
    uint256 public immutable endTime;
    mapping(address => uint256) public staked;
    mapping(address => uint256) public lastClaim;

    constructor(ToyToken s, ToyToken r, uint256 perSecond, uint256 end) {
        stakeToken = s;
        rewardToken = r;
        rewardPerSecond = perSecond;
        endTime = end;
    }

    function stake(uint256 amount) external {
        stakeToken.transferFrom(msg.sender, address(this), amount);
        staked[msg.sender] += amount;
        lastClaim[msg.sender] = block.timestamp;
    }

    function pending(address who) public view returns (uint256) {
        if (staked[who] == 0) return 0;
        uint256 until = block.timestamp < endTime ? block.timestamp : endTime;
        if (until <= lastClaim[who]) return 0;
        return (until - lastClaim[who]) * rewardPerSecond;
    }

    // 報酬が出ていく行。金庫の残高ではなくmint
    function claim() external {
        uint256 r = pending(msg.sender);
        lastClaim[msg.sender] = block.timestamp;
        rewardToken.mint(msg.sender, r);
    }
}

// 出どころ4: あとから入った人の預け入れ金。1日1%の単利を約束するが外から入ってくる収入の行はない
contract FixedYield202 {
    ToyToken public immutable token;
    uint256 public constant DAILY_BPS = 100; // 1日1%
    mapping(address => uint256) public principal;
    mapping(address => uint256) public since;
    address[] public depositors;

    error NoCash(uint256 have, uint256 want);

    constructor(ToyToken t) {
        token = t;
    }

    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        principal[msg.sender] = amount;
        since[msg.sender] = block.timestamp;
        depositors.push(msg.sender);
    }

    function owedTo(address who) public view returns (uint256) {
        uint256 p = principal[who];
        return p + p * DAILY_BPS * ((block.timestamp - since[who]) / 1 days) / 10_000;
    }

    // 約束した持ち分の合計
    function totalOwed() external view returns (uint256 sum) {
        for (uint256 i = 0; i < depositors.length; i++) {
            sum += owedTo(depositors[i]);
        }
    }

    // 支払いの行。引き出して渡すトークンは金庫の残高、つまり他の人が預けたお金
    function withdraw() external returns (uint256 amount) {
        amount = owedTo(msg.sender);
        uint256 have = token.balanceOf(address(this));
        if (amount > have) revert NoCash(have, amount);
        principal[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }
}
