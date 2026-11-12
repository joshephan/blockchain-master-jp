// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 第78講
    function transfer(address to, uint256 amount) external returns (bool); // 第83講
}

// ユーザー一人分 (第70講)
struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

// 資産一つの設定
struct AssetConfig {
    Ratio collateralRatio;
    bool listed;
}

// 第90講: 預け入れより多く引き出そうとする要求
error InsufficientDeposit(uint256 have, uint256 want);
// 第108講: 文字列の理由十一個を名前と引数に変える。ファイルレベルの宣言なので、このファイルをインポートする側も名前で使う
error ZeroAdmin();
error NotAdmin(address caller);
error MarketFrozen();
error NotActive(MarketBase.MarketStatus status); // ABIではNotActive(uint8)
error ZeroAsset();
error AlreadyListed(address asset);
error RatioAboveCap(Ratio ratio, Ratio cap); // ABIではRatioAboveCap(uint8,uint8)
error NotListed(address asset);
error ZeroAmount();
error TransferFromFailed(address asset);
error TransferFailed(address asset);

// 第25章 第112講末の版: 第111講の版 + 上場資産の一覧をAssetRegistryに、預け入れの帳簿と引き出しをLedgerに切り出す。Marketは三つを継承
// 第110講: 市場の状態(status、StatusChanged、notFrozen・whenActive)を親に切り出す。Marketが継承し、デプロイ物一つにまとまる
// 親の変数が前のスロットなので、statusはそのままスロット0
// 第111講: この版にはvirtualが一つもない。継承するコントラクトが書き直せる関数・modifierなし
contract MarketBase {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;

    event StatusChanged(MarketStatus from, MarketStatus to);

    // 第103講・第104講のmodifier二つ。virtualは付けない
    modifier notFrozen() {
        _checkNotFrozen();
        _;
    }

    modifier whenActive() {
        if (status != MarketStatus.Active) revert NotActive(status); // 第108講
        _;
    }

    // 第110講: 状態を変えて記録を出す部分。誰が呼べるかは呼ぶ側(MarketのsetStatus)が決める
    function _setStatus(MarketStatus s) internal {
        MarketStatus from = status;
        status = s;
        emit StatusChanged(from, s); // 第105講: 処理をすべて終えた後、最後の行で出力
    }

    function _checkNotFrozen() internal view {
        if (status == MarketStatus.Frozen) revert MarketFrozen(); // 第108講
    }
}

// 第112講: 上場資産の一覧。市場の状態を見ないのでMarketBaseを継承しない
contract AssetRegistry {
    IERC20[] public assets;
    mapping(address asset => AssetConfig) public assetConfig;

    // 第105講・第106講
    event AssetAdded(address indexed asset, Ratio ratio);

    // 第112講: 上限capは呼ぶ側(MarketのaddAsset)が渡す。誰が呼べるかも呼ぶ側が決める
    function _listAsset(IERC20 asset, Ratio ratio, Ratio cap) internal {
        if (address(asset) == address(0)) revert ZeroAsset(); // 第90講、第108講
        if (assetConfig[address(asset)].listed) revert AlreadyListed(address(asset)); // 第108講
        if (Ratio.unwrap(ratio) > Ratio.unwrap(cap)) revert RatioAboveCap(ratio, cap); // 第92講、第108講
        assets.push(asset);
        assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
        emit AssetAdded(address(asset), ratio); // 第105講
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }
}

// 第112講: 預け入れの帳簿と引き出し。凍結した市場で引き出しを止めるnotFrozenが必要なのでMarketBaseを継承
contract Ledger is MarketBase {
    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;
    mapping(address asset => Amount) public totalBorrows;

    // 第105講・第106講
    event Deposited(address indexed asset, address indexed user, uint256 amount);
    event Withdrawn(address indexed asset, address indexed user, uint256 amount);

    // 第100講: withdrawAllが内部で呼ぶのでexternalからpublicに
    function withdraw(address asset, uint256 amount) public notFrozen {
        if (amount == 0) revert ZeroAmount(); // 第90講、第108講
        _debit({asset: asset, user: msg.sender, amount: amount});
        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
        if (!ok) revert TransferFailed(asset); // 第108講
        emit Withdrawn(asset, msg.sender, amount); // 第105講: withdrawAllもこの行で出力される
    }

    // 第100講: withdraw(address)でオーバーロードせず、名前を別に付ける
    // 第103講: modifierを別に付けない。内部で呼ぶwithdrawのnotFrozenが実行される
    function withdrawAll(address asset) external {
        withdraw(asset, Amount.unwrap(positions[asset][msg.sender].deposited));
    }

    function _credit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
        _touch(p);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
    }

    function _debit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        uint256 have = Amount.unwrap(p.deposited);
        if (have < amount) revert InsufficientDeposit(have, amount); // 第90講
        p.deposited = Amount.wrap(have - amount);
        _touch(p);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) - amount);
        assert(Amount.unwrap(totalDeposits[asset]) >= Amount.unwrap(p.deposited)); // 第90講
    }

    function _touch(Position storage p) internal {
        p.lastUpdate = uint64(block.timestamp);
    }

    // 第76講: 最後の更新から経過した秒数
    function elapsedOf(address asset, address user) external view returns (uint256) {
        Position storage p = positions[asset][user];
        return block.timestamp - p.lastUpdate;
    }
}

// 第112講: 基本側から書く。線形化の順番はMarket、Ledger、AssetRegistry、MarketBase
// スロットは逆にMarketBase(0 status)、AssetRegistry(1 assets、2 assetConfig)、Ledger(3・4・5)なので第109講の版のスロットマップと同じ
contract Market is MarketBase, AssetRegistry, Ledger {
    // 第102講: コンストラクタで一度決め、変える関数がない三つはimmutable。ストレージスロットなしでランタイムコードに入る
    Ratio public immutable collateralRatio; // 第92講: 資産ごとに決める担保比率の上限
    address public immutable admin;
    Rate public immutable interestRate;

    constructor(address admin_, Rate interestRate_, Ratio collateralRatio_) {
        if (admin_ == address(0)) revert ZeroAdmin(); // 第108講
        admin = admin_;
        interestRate = interestRate_;
        collateralRatio = collateralRatio_;
    }

    // 第103講: チェックの行をmodifierへ移す。宣言の行に書いた順番どおりに実行
    // 第109講: requireの二つ目の引数は条件が真でも先に計算される。require(条件, エラー)の十三か所をすべてifの形に変える。成功した呼び出しはエラーの引数を計算しない
    // 第104講: 二か所以上に付くチェックは内部関数に一度だけ書き、modifierはその関数を呼ぶ。virtualは付けない
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    // 第103講: 市場の状態を変える関数。Activeはすべて許可、DepositPausedは預け入れだけ止める、Frozenは資産の追加と引き出しまで止める
    function setStatus(MarketStatus s) external onlyAdmin {
        _setStatus(s); // 第110講: 変える本体はMarketBaseにある
    }

    function addAsset(IERC20 asset, Ratio ratio) external onlyAdmin notFrozen {
        _listAsset(asset, ratio, collateralRatio); // 第112講: 一覧に入れる本体はAssetRegistryにある
    }

    // 第112講: 上場確認(AssetRegistry)と帳簿(Ledger)を両方使う関数なのでMarketに残す
    function deposit(address asset, uint256 amount) external whenActive {
        if (!assetConfig[asset].listed) revert NotListed(asset); // 第104講、第108講: この関数一つだけにかかり引数を見るチェックなので本文の一行目に戻す
        if (amount == 0) revert ZeroAmount(); // 第90講、第108講
        _credit({asset: asset, user: msg.sender, amount: amount});
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 第83講
        if (!ok) revert TransferFromFailed(asset); // 第108講
        emit Deposited(asset, msg.sender, amount); // 第105講
    }

    function _checkAdmin() internal view {
        if (msg.sender != admin) revert NotAdmin(msg.sender); // 第108講
    }

    // 第75講の利息の草案: 1年は365 daysとみなす
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // amount: 資産の桁数のまま、rate: 年利 倍率10の18乗、elapsed: 秒
    // 第95講: 内部で呼ぶ場所がないのでpublicからexternalに
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256) {
        return amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18;
    }

    // 第81講: このユーザーが担保に使う資産の数
    // 第112講: 資産一覧(AssetRegistry)と帳簿(Ledger)を一緒に読むのでMarketに残す
    function collateralCount(address user) external view returns (uint256 count) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (positions[address(assets[i])][user].useAsCollateral) {
                count++;
            }
        }
    }
}
