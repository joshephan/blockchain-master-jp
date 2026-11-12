// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ToyPool} from "./Mev172.sol";

// 第173講のトイのスポット価格。プール残高の比率をその瞬間のまま読む
contract SpotOracle {
    ToyPool public immutable pool;

    constructor(ToyPool p) {
        pool = p;
    }

    // A一個がB何個か(1e18倍率)。一つのブロック内でプールを揺さぶると、そのまま揺れる
    function price() external view returns (uint256) {
        return pool.reserveB() * 1e18 / pool.reserveA();
    }
}

// 第173講のトイの時間加重平均価格。累積値を二回読んで、その間の平均を出す
contract TwapOracle {
    ToyPool public immutable pool;
    uint256 public priceCumulative;
    uint256 public lastTimestamp;
    uint256 public lastPrice;

    constructor(ToyPool p) {
        pool = p;
        lastTimestamp = block.timestamp;
        lastPrice = p.reserveB() * 1e18 / p.reserveA();
    }

    // ブロックが変わるたびに、前の区間の価格 × 経過時間を累積
    function update() external {
        uint256 elapsed = block.timestamp - lastTimestamp;
        priceCumulative += lastPrice * elapsed;
        lastPrice = pool.reserveB() * 1e18 / pool.reserveA();
        lastTimestamp = block.timestamp;
    }

    // ウィンドウの開始のスナップショットを外で持っておき、今の値と比べて平均
    function consult(uint256 startCumulative, uint256 startTimestamp) external view returns (uint256) {
        uint256 elapsed = block.timestamp - startTimestamp;
        if (elapsed == 0) revert NoElapsed();
        return (priceCumulative - startCumulative) / elapsed;
    }

    error NoElapsed();
}

// 第173講のトイの貸出。担保価値をオラクル一つで評価
// readOracleがSpotOracleならその瞬間の価格、TwapOracleのウィンドウの値なら平均
contract ToyLender {
    SpotOracle public immutable oracle;
    mapping(address => uint256) public collateralA;

    constructor(SpotOracle o) {
        oracle = o;
    }

    function putCollateral(address who, uint256 amountA) external {
        collateralA[who] += amountA;
    }

    // 担保Aをスポット価格でBの価値に換算し、その分だけ貸す(最小の形、返済は省略)
    function maxBorrowB(address who) external view returns (uint256) {
        return collateralA[who] * oracle.price() / 1e18;
    }
}
