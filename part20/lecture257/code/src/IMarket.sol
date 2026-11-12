// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// レンディングマーケットの外向きの約束(ABI)。関数ごとに担う要件番号はdesign/requirements.md
// 要件の草案で決めた関数・イベント・エラー。誰が呼ぶかはdesign/architecture.md 3節の権限リスト

import {IPriceFeed} from "./MarketTypes.sol";

/// @title レンディング市場
/// @notice 上場したERC-20トークンを預け、担保で借り、返し、清算するマーケット
interface IMarket {
    // 設定(F-10、A-02~A-04)
    /// @notice トークン一つをマーケットに上場する。価格の出どころ・担保比率・預け入れの上限を一緒に決める
    function listAsset(address asset, IPriceFeed feed, uint8 collateralRatio, uint256 supplyCap) external;
    /// @notice 預け入れの上限を変えた
    function setSupplyCap(address asset, uint256 cap) external;
    /// @notice 資産一つの預け入れ・借り入れを止める(bits: 1は預け入れ、2は借り入れ)
    function pause(address asset, uint8 bits) external;
    /// @notice 止めた預け入れ・借り入れを再開する
    function unpause(address asset, uint8 bits) external;
    /// @notice 停止キーを変える
    function setGuardian(address guardian) external;

    // ユーザー(F-01~F-08)
    /// @notice トークンを預ける(F-01)
    function deposit(address asset, uint256 amount) external;
    /// @notice 預けたトークンを引き出す(F-02)。どの状態でもできる(S-01)
    function withdraw(address asset, uint256 amount) external;
    /// @notice 預けたトークンを利息まで全部引き出す(F-02)
    function withdrawAll(address asset) external;
    /// @notice 預けた資産を担保に使うかを決める(F-03)
    function setCollateral(address asset, bool on) external;
    /// @notice 担保の上限の範囲で借りる(F-04)
    function borrow(address asset, uint256 amount) external;
    /// @notice 自分の借金を返す。借金より多く出したら借金の分だけ(F-05)
    function repay(address asset, uint256 amount) external;
    /// @notice 清算ラインを超えたアカウントの借金を代わりに返して担保を受け取る(F-07)
    function liquidate(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount) external;
    /// @notice 担保が残っていないアカウントの借金を消す。損失はその資産を預けた人が持ち分に応じて分ける(F-08)
    function writeOffBadDebt(address borrower, address asset) external;

    // 読み取り(O-02)
    /// @notice 設定キー(デプロイ時はタイムロックのアドレス)
    function admin() external view returns (address);
    /// @notice 停止キー
    function guardian() external view returns (address);
    /// @notice 上場した資産の数
    function assetCount() external view returns (uint256);
    /// @notice 利息を足した預け入れの合計(トークン量)
    function totalDeposits(address asset) external view returns (uint256);
    /// @notice 利息を足した借り入れの合計(トークン量)
    function totalBorrows(address asset) external view returns (uint256);
    /// @notice 利息を足した預けた量
    function depositOf(address asset, address user) external view returns (uint256);
    /// @notice 利息を足した返す量
    function debtOf(address asset, address user) external view returns (uint256);
    /// @notice 借りた比率(倍率10の18乗)
    function utilization(address asset) external view returns (uint256);
    /// @notice 今の借りた比率での年利率(倍率10の18乗)(F-06)
    function borrowRate(address asset) external view returns (uint256);
    /// @notice 30分の時間加重平均価格(F-09)
    function priceOf(address asset) external view returns (uint256);
    /// @notice 借りられる上限と借金の値(倍率10の18乗)
    function accountHealth(address user) external view returns (uint256 borrowLimit, uint256 debtValue);
    /// @notice 清算ライン(担保の値 × (担保比率 + 5))
    function liquidationLimit(address user) external view returns (uint256);

    // イベント(O-01)
    event AssetListed(address indexed asset, address feed, uint8 collateralRatio, uint256 supplyCap);
    event SupplyCapSet(address indexed asset, uint256 cap);
    event PauseSet(address indexed asset, uint8 bits);
    event GuardianSet(address guardian);
    event Deposited(address indexed asset, address indexed user, uint256 amount);
    event Withdrawn(address indexed asset, address indexed user, uint256 amount);
    event CollateralSet(address indexed asset, address indexed user, bool on);
    event Borrowed(address indexed asset, address indexed user, uint256 amount);
    event Repaid(address indexed asset, address indexed user, uint256 amount);
    event Liquidated(
        address indexed borrower,
        address indexed liquidator,
        address indexed collateralAsset,
        address debtAsset,
        uint256 repaid,
        uint256 seized
    );
    event BadDebtWrittenOff(address indexed asset, address indexed borrower, uint256 amount);

    // エラー
    error NotAdmin(address caller);
    error NotGuardian(address caller);
    error ZeroAddress();
    error NotListed(address asset);
    error AlreadyListed(address asset);
    error TooManyAssets(uint256 max);
    error RatioAboveCap(uint8 ratio, uint8 cap);
    error ZeroAmount();
    error ZeroShares();
    error ActionPaused(address asset, uint8 bit);
    error SupplyCapExceeded(uint256 cap, uint256 want);
    error InsufficientDeposit(uint256 have, uint256 want);
    error InsufficientLiquidity(uint256 available, uint256 want);
    error InsufficientCollateral(uint256 limit, uint256 debt);
    error NoDebt(address asset);
    error NotLiquidatable(uint256 limit, uint256 debt);
    error NotCollateral(address asset);
    error AboveCloseFactor(uint256 max, uint256 want);
    error HasCollateral(uint256 collateralValue);
    error LossExceedsDeposits(uint256 loss, uint256 deposits);
    error AmountMismatch(uint256 expected, uint256 received);
}
