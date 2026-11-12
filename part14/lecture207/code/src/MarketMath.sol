// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount, Rate, Position} from "./MarketTypes.sol";
import {IMarket} from "./IMarket.sol";

// 第116講: Marketから切り出した二つの計算。internal関数だけなので別にデプロイしない
// 呼ぶ関数のコードがMarketのランタイムコードに入る。呼ぶことは内部呼び出し(第82講)
// 第117講: public・external関数を置かない。Marketの成果物のlinkReferencesが空で、リンクするアドレスなし
// publicに変えるとライブラリを別にデプロイしてリンクし、呼ぶたびにdelegatecall(第117講のpublic変形版で確認)

// 第116講: 利息の計算。状態を読みも書きもしない
library InterestMath {
    // 第116講: ライブラリには状態変数を置けない(Error 9957)。constantは置ける
    // 第75講の利息の草案: 1年は365 daysとみなす
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    // 第123講: この本体をアセンブリのmul・divで書くとオーバーフローチェックが抜ける。あふれる入力でPanic 0x11の代わりに間違った値を返す
    // amount: 資産の桁数のまま、rate: 年利 倍率10の18乗、elapsed: 秒
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) internal pure returns (uint256) {
        return amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18;
    }

    // 第197講: 金利の曲線。借りた比率が折れ点までは緩やかに、超えると急に上がる
    uint256 internal constant KINK = 0.8e18; // 折れ点、借りた比率80%
    uint256 internal constant JUMP_RATE = 1e18; // 折れ点の後の傾き。借りた比率100%で年100%を足す

    // 第197講: 借りた比率(倍率10の18乗)。預けた量が0なら0
    function utilization(uint256 borrows, uint256 deposits) internal pure returns (uint256) {
        if (deposits == 0) return 0;
        return borrows * 1e18 / deposits;
    }

    // 第197講: 借りた比率に応じた年利。rateAtKinkは折れ点での年利
    function borrowRate(uint256 u, Rate rateAtKink) internal pure returns (Rate) {
        uint256 r = Rate.unwrap(rateAtKink);
        if (u <= KINK) return Rate.wrap(r * u / KINK);
        return Rate.wrap(r + JUMP_RATE * (u - KINK) / (1e18 - KINK));
    }

    // 第197講: 割り算の切り上げ。返す量と借りた取り分は切り上げて数える(市場側に残す)
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}

// 第116講: ユーザー一人分(Position)を直す計算
// ライブラリに状態変数がないので、直す欄はLedgerがstorage引数で渡す(第82講)
// 第118講: Ledgerがusing PositionLib for Positionと書き、positions[asset][user].credit(amount)の形で呼ぶ。最初の引数がドットの前の値
// 第149講: 最初の引数名をpからselfに変える(スタイルガイドの構造体ライブラリの規則)。internal関数なのでABI・セレクターはそのまま
library PositionLib {
    // 預けた量を増やし、更新時刻を書く
    function credit(Position storage self, uint256 amount) internal {
        self.deposited = self.deposited + Amount.wrap(amount); // 第118講: Amountの+(MarketTypes.sol、global)
        self.lastUpdate = uint64(block.timestamp);
    }

    // 預けた量を減らし、更新時刻を書く。足りなければ巻き戻す
    function debit(Position storage self, uint256 amount) internal {
        uint256 have = Amount.unwrap(self.deposited);
        if (have < amount) revert IMarket.InsufficientDeposit(have, amount); // 第90講、第108講: この行がLedgerからここへ移ってくる
        self.deposited = self.deposited - Amount.wrap(amount); // 第118講: Amountの-
        self.lastUpdate = uint64(block.timestamp);
    }
}
