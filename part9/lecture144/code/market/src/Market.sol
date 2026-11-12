// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, Amount, Rate, Ratio, Position, AssetConfig} from "./MarketTypes.sol";
import {IMarket} from "./IMarket.sol";
import {InterestMath, PositionLib} from "./MarketMath.sol"; // 第116講

// 第115講: 第108講のファイルレベルのエラー十二個とMarket・親のイベント・enum宣言を消し、IMarket一か所にだけ置く

// 第25章 第115講末の版: 第114講の版 + MarketBaseがIMarketを継承。三つの親はabstract、デプロイするのはMarket一つ
// 第26章 第116講末の版: 第115講の版 + 利息の計算とPositionを直す計算を二つのライブラリ(MarketMath.sol)に切り出す。デプロイするのは変わらずMarket一つ
// 第26章 第117講末の版: 第116講の版とコードは同じ。ライブラリを外に置かないことにする(ランタイムサイズの上限内、一緒に使う別のコントラクトなし、リンクするアドレスを信頼する行が生じない)
// 第26章 第118講末の版: 第117講の版 + Ledgerにusing PositionLib for Position、Amountに演算子+・-(MarketTypes.sol、global)
// 第27章 第119講末の版: 第118講の版とコードは同じ。src内のアセンブリブロック0個(アセンブリブロック一覧の開設)
// 第27章 第120講末の版: 第119講の版とコードは同じ。テスト用のMarketSlots(test/Assembly.t.sol)が.slotでスロットマップの番号を確認
// 第27章 第121講末の版: 第120講の版とコードは同じ。MarketSlotsの二つのブロックはメモリに触れない。0x40の欄はすべてコンパイラが管理
// 第27章 第122講末の版: 第121講の版とコードは同じ。テスト用のRawCaller(test/Assembly.t.sol)が手でかけた呼び出しでMarketのエラーのバイト列を受け取り、そのまま上に送る
// 第27章 第123講末の版: 第122講の版とコードは同じ。Marketにアセンブリを入れないことにする(optimizerをオンにした版で減る実行ガスが小さく、オーバーフローチェックも一緒に抜ける)
// 第28章 第124講末の版: 第123講の版とコードは同じ。ビルド設定四行(optimizerオフ、runs 200、via-IRオフ、evm_version osaka)をfoundry.tomlに書く
// 第28章 第125講末の版: 第124講の版とコードは同じ。Yulだけで書いたファイルなし(セレクター19個、イベント4個、エラー12個をコンパイラがソースから作る)
// 第29章 第126講末の版: 第125講の版とコードは同じ。Market.sol・MarketMath.solが読むグローバルな値はmsg.sender 9か所、block.timestamp 3か所、address(this) 1か所だけ。バージョン・evm_versionによって生じたり止められたりするグローバルな名前なし
// 第29章 第127講末の版: 第126講の版とコードは同じ。srcの五つのファイルがsolc --stop-after parsingを通過。pragma solidity 0.8.30固定なので、文法の判定はsolc 0.8.30のパーサー基準
// 第30章 第128講末の版: 第127講の版とコードは同じ。forgeがsolcに渡すStandard JSON(srcの四つのファイル、settingsの七つの欄)をsolc --standard-jsonにそのまま入れると同じバイトコード
// 第30章 第129講末の版: 第128講の版とコードは同じ。ソースユニット名はsrc/で始まる四つ。forge-stdのremapping一行をfoundry.tomlに書く(lib/forge-stdがなくても同じメタデータ)
// 第30章 第130講末の版: 第129講の版とコードは同じ。デプロイしたコードとビルドし直したコードは、immutableの六つの区間(admin、interestRate、collateralRatio)以外は最後まで同じ
// 第31章 第131講末の版: 第130講の版とコードは同じ。ランタイム7,353バイト = コード7,300バイト + メタデータの末尾53バイト。immutableReferencesの三つのキーはadmin・collateralRatio・interestRate宣言のASTノードid
// 第31章 第132講末の版: 第131講の版とコードは同じ。巻き戻した命令の位置をソースマップでソースの行まで探す。ソースマップはチェーンにないので、ビルド成果物とソースファイルを一緒に保管
// 第32章 第133講末の版: 第132講の版とコードは同じ。デプロイ物はデフォルトの経路(legacy)で作る。二つの経路で結果が分かれる行(継承の初期値、struct delete、_;二回、一つの式の中の計算順、addmod・mulmod、アセンブリ)なし
// 第32章 第134講末の版: 第133講の版とコードは同じ。デプロイ物はvia-IRに変えない(optimizerオフのvia-IR版はサイズ・ガスともに大きい)。foundry.tomlの[profile.ir]で同じテスト55個をvia-IRでも回す
// 第33章 第135講末の版: 第134講の版とコードは同じ。スロットマップにバイト位置と計算式を書き、test/Layout.t.solがvm.loadで照合(assetConfigは一つの欄に二つ、Positionは三つの欄)
// 第33章 第136講末の版: 第135講の版とコードは同じ。transient状態変数なし。一つのトランザクションの中で書いて元の値に戻すスロットがないので、transientに移す値なし
// 第33章 第137講末の版: 第136講の版とコードは同じ。メモリはコンパイラが0x80から使う(コンストラクタはimmutable三つの場所の後ろ0xe0から)。関数一回で256バイト以下
// 第33章 第138講末の版: 第137講の版とコードは同じ。引数の解釈はコンパイラのABIデコーダー(範囲外の値は巻き戻す、後ろに残るバイトは無視)。test/Calldata.t.solが手で作ったcalldataで確認
// 第34章 第139講末の版: 第138講の版とコードは同じ。optimizerをオフにしたビルドでもpeephole・jumpdestRemover・ループカウンターの段階が動く。オンにすると巻き戻りの末尾をまとめる段階(deduplicate)のせいで、ソースマップが別の行を指すことがある
// 第34章 第140講末の版: 第139講の版とコードは同じ。デプロイのビルドをoptimizerオン(runs 200)に変える。巻き戻りの行はFOUNDRY_PROFILE=debug(optimizerオフ)で回し直して探す
// 第35章 第141講末の版: 第140講の版とコードは同じ。引数・戻り値・ログ・巻き戻りデータはすべて長さが決まった型なので、ABIの形に末尾なし。test/AbiShape.t.solがバイト数と形を確認
// 第35章 第142講末の版: 第141講の版とコードは同じ。メタデータのハッシュ(ipfs)を末尾に付ける。検証用にrawMetadataとsrcの四つのファイルを一緒に保管(コンストラクタの引数はメタデータにない)
// 第36章 第143講末の版: 第142講の版とコードは同じ。最初のdepositのガスの78%がストレージの欄の読み書き(トークン呼び出しの内側を含む)。Positionの欄のパッキング(金額の欄uint128)はスロットマップ・ABI・チェックが一緒に変わるので先送り
// 第36章 第144講末の版: 第143講の版とコードは同じ。ガスを節約するために外したチェックなし(unchecked・アセンブリ・狭めた金額の欄・決めておいたガス0か所)。test/Guards.t.solが引き出しのチェック三つを確認
// 第110講: 市場の状態(status、StatusChanged、notFrozen・whenActive)を親に切り出す。Marketが継承し、デプロイ物一つにまとまる
// 親の変数が前のスロットなので、statusはそのままスロット0
// 第111講: この版にはvirtualが一つもない。継承するコントラクトが書き直せる関数・modifierなし
// 第113講: virtualは_checkDepositの一つ。モジュールごとに自分のチェックを足し、superで前の順番を呼ぶ
// 第115講: IMarketを継承するので、IMarketの関数のうち本体のないものが残る。だからabstract
abstract contract MarketBase is IMarket {
    MarketStatus public status; // 第115講: MarketStatusはIMarketから継承したenum
    // 第92講、第102講、第114講: Marketから移した管理者の欄。値はMarketのコンストラクタがMarketBase(admin_)へ渡す
    address public immutable admin;

    // 第114講: 線形化の順番の最後なので、コンストラクタの中で最初に実行
    constructor(address admin_) {
        if (admin_ == address(0)) revert ZeroAdmin(); // 第108講
        admin = admin_;
    }

    // 第103講: チェックの行をmodifierへ移す。宣言の行に書いた順番どおりに実行
    // 第109講: requireの二つ目の引数は条件が真でも先に計算される。require(条件, エラー)の十三か所をすべてifの形に変える。成功した呼び出しはエラーの引数を計算しない
    // 第104講: 二か所以上に付くチェックは内部関数に一度だけ書き、modifierはその関数を呼ぶ。virtualは付けない
    // 第114講: onlyAdminもadminと一緒に移す
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    // 第103講・第104講のmodifier二つ。virtualは付けない
    modifier notFrozen() {
        _checkNotFrozen();
        _;
    }

    modifier whenActive() {
        if (status != MarketStatus.Active) revert NotActive(status); // 第108講
        _;
    }

    // 第103講: 市場の状態を変える関数。Activeはすべて許可、DepositPausedは預け入れだけ止める、Frozenは資産の追加と引き出しまで止める
    // 第114講: Marketから移し、第110講の_setStatusをまとめる
    function setStatus(MarketStatus s) external onlyAdmin {
        MarketStatus from = status;
        status = s;
        emit StatusChanged(from, s); // 第105講: 処理をすべて終えた後、最後の行で出力
    }

    function _checkAdmin() internal view {
        if (msg.sender != admin) revert NotAdmin(msg.sender); // 第108講
    }

    function _checkNotFrozen() internal view {
        if (status == MarketStatus.Frozen) revert MarketFrozen(); // 第108講
    }

    // 第113講: 預け入れの前にモジュールごとに足すチェック。ここは空の本体、列の一番最後
    function _checkDeposit(address asset, uint256 amount) internal view virtual {}
}

// 第112講: 上場資産の一覧
// 第113講: 預け入れチェックの列に加わるためにMarketBaseを継承。線形化の順番とスロットは第112講の版のまま
// 第114講: MarketBaseのコンストラクタ引数(admin_)をここで決めないのでabstract。単独でデプロイしない
abstract contract AssetRegistry is MarketBase {
    // 第92講、第102講、第114講: Marketから移した担保比率の上限。値はMarketのコンストラクタがAssetRegistry(collateralRatio_)へ渡す
    Ratio public immutable collateralRatio;
    IERC20[] public assets;
    mapping(address asset => AssetConfig) public assetConfig;

    // 第114講: MarketBaseのコンストラクタの次に実行
    constructor(Ratio cap) {
        collateralRatio = cap;
    }

    // 第114講: Marketから移し、第112講の_listAssetをまとめる
    function addAsset(IERC20 asset, Ratio ratio) external onlyAdmin notFrozen {
        if (address(asset) == address(0)) revert ZeroAsset(); // 第90講、第108講
        if (assetConfig[address(asset)].listed) revert AlreadyListed(address(asset)); // 第108講
        if (Ratio.unwrap(ratio) > Ratio.unwrap(collateralRatio)) revert RatioAboveCap(ratio, collateralRatio); // 第92講、第108講
        assets.push(asset);
        assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
        emit AssetAdded(address(asset), ratio); // 第105講
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    // 第113講: 前の順番(super)を先に呼んでから上場確認
    function _checkDeposit(address asset, uint256 amount) internal view virtual override {
        super._checkDeposit(asset, amount);
        if (!assetConfig[asset].listed) revert NotListed(asset); // 第104講、第108講
    }
}

// 第112講: 預け入れの帳簿と引き出し。凍結した市場で引き出しを止めるnotFrozenが必要なのでMarketBaseを継承
// 第114講: AssetRegistryと同じ理由でabstract
abstract contract Ledger is MarketBase {
    // 第118講: positions[asset][user].credit(amount)はPositionLib.credit(positions[asset][user], amount)と同じ呼び出し
    // この行はLedgerの中でだけ通る。Ledgerを継承したMarketでは.creditを使えない(Error 9582)
    using PositionLib for Position;

    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;
    mapping(address asset => Amount) public totalBorrows;

    // 第113講: Marketから移す。チェックは_checkDepositの列全体が受け持つ
    function deposit(address asset, uint256 amount) external whenActive {
        _checkDeposit(asset, amount);
        _credit({asset: asset, user: msg.sender, amount: amount});
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 第83講
        if (!ok) revert TransferFromFailed(asset); // 第108講
        emit Deposited(asset, msg.sender, amount); // 第105講
    }

    // 第113講: 前の順番(super)を先に呼んでから金額の確認。上場確認が金額確認より先に実行
    function _checkDeposit(address asset, uint256 amount) internal view virtual override {
        super._checkDeposit(asset, amount);
        if (amount == 0) revert ZeroAmount(); // 第90講、第108講
    }

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

    // 第116講: Positionを直す行をPositionLibに切り出す。直す欄はstorage引数で渡す。合計はLedgerの状態変数なのでここに残す
    function _credit(address asset, address user, uint256 amount) internal {
        positions[asset][user].credit(amount);
        totalDeposits[asset] = totalDeposits[asset] + Amount.wrap(amount); // 第118講: Amountの+はMarketTypes.solのaddAmount
    }

    function _debit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        p.debit(amount); // 第116講: 足りないときに巻き戻す行もPositionLib.debitの中へ / 第118講: usingで付けて呼ぶ
        totalDeposits[asset] = totalDeposits[asset] - Amount.wrap(amount); // 第118講: Amountの-はMarketTypes.solのsubAmount
        assert(Amount.unwrap(totalDeposits[asset]) >= Amount.unwrap(p.deposited)); // 第90講 / 第118講: >=は付けていないのでunwrapで比較
    }

    // 第76講: 最後の更新から経過した秒数
    function elapsedOf(address asset, address user) external view returns (uint256) {
        Position storage p = positions[asset][user];
        return block.timestamp - p.lastUpdate;
    }
}

// 第112講: 基本側から書く。線形化の順番はMarket、Ledger、AssetRegistry、MarketBase
// スロットは逆にMarketBase(0 status)、AssetRegistry(1 assets、2 assetConfig)、Ledger(3・4・5)なので第109講の版のスロットマップと同じ
// 第113講: AssetRegistryとLedgerが両方MarketBaseを継承するので、MarketBaseは書かない。線形化の順番とスロットはそのまま
contract Market is AssetRegistry, Ledger {
    // 第102講: コンストラクタで一度決め、変える関数がない値はimmutable。ストレージスロットなしでランタイムコードに入る
    // 第114講: adminはMarketBaseへ、collateralRatioはAssetRegistryへ移し、interestRateだけを残す
    Rate public immutable interestRate;

    // 第114講: デプロイ引数三つを受け取り、二つを親のコンストラクタへ渡す。実行の順番は書いた順番ではなくMarketBase、AssetRegistry、Ledger、Market
    constructor(address admin_, Rate interestRate_, Ratio collateralRatio_) MarketBase(admin_) AssetRegistry(collateralRatio_) {
        interestRate = interestRate_;
    }

    // 第113講: 二つの親(AssetRegistry、Ledger)が同じ関数を書き換えるので、Marketが両方を書いてsuperで渡す
    // 実行の順番: Market、Ledger、AssetRegistry、MarketBase。チェックはsuperの後ろに書いたのでMarketBase側から実行
    function _checkDeposit(address asset, uint256 amount) internal view override(AssetRegistry, Ledger) {
        super._checkDeposit(asset, amount);
    }

    // 第75講の利息の草案: 1年は365 daysとみなす
    // 第116講: 値はInterestMathに置き、ゲッターはIMarketの関数一覧のためMarketに残す
    uint256 public constant SECONDS_PER_YEAR = InterestMath.SECONDS_PER_YEAR;

    // amount: 資産の桁数のまま、rate: 年利 倍率10の18乗、elapsed: 秒
    // 第95講: 内部で呼ぶ場所がないのでpublicからexternalに
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256) {
        return InterestMath.interestFor(amount, rate, elapsed); // 第116講: 計算の本体はInterestMath
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
