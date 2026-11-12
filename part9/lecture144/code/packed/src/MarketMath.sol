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
}

// 第116講: ユーザー一人分(Position)を直す計算
// ライブラリに状態変数がないので、直す欄はLedgerがstorage引数で渡す(第82講)
// 第118講: Ledgerがusing PositionLib for Positionと書き、positions[asset][user].credit(amount)の形で呼ぶ。最初の引数pがドットの前の値
library PositionLib {
    // 預けた量を増やし、更新時刻を書く
    function credit(Position storage p, uint256 amount) internal {
        uint256 d = uint256(p.deposited) + amount;
        if (d > type(uint128).max) revert IMarket.AmountTooLarge(d);
        p.deposited = uint128(d);
        p.lastUpdate = uint64(block.timestamp);
    }

    // 預けた量を減らし、更新時刻を書く。足りなければ巻き戻す
    function debit(Position storage p, uint256 amount) internal {
        uint256 have = p.deposited;
        if (have < amount) revert IMarket.InsufficientDeposit(have, amount); // 第90講、第108講: この行がLedgerからここへ移ってくる
        p.deposited = uint128(have - amount);
        p.lastUpdate = uint64(block.timestamp);
    }
}
