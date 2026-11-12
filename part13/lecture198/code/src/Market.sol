// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, IPriceFeed, Amount, Rate, Ratio, Position, AssetConfig, Reserve, PriceConfig} from "./MarketTypes.sol";
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
// 第36章 第144講末の版: 第143講の版とコードは同じ。ガスを節約するために外したチェックなし(unchecked・アセンブリ・狭めた金額の欄・決めておいたガス0か所)。test/Guards.t.solがInsufficientDepositのチェックを、LibraryTest:test_amountOperatorsがAmount `-` のオーバーフローチェックを確認。Ledger._debitのassertの行は前の二つのチェックが先に止めるので捕まえるテストなし(第146講で修正)
// 第36章 第145講末の版: 第144講の版とコードは同じ。デプロイのビルドをvia-IR(optimizerオン)に変える。ガスの記録はtest/Gas.t.sol(snapshots/Market.json)と.gas-snapshot、確認はci.sh
// 第37章 第146講末の版: 第145講の版とコードは同じ。NatSpecはIMarketに書き、Marketの関数・自動ゲッターは継承する。コントラクトの上のドキュメントとコンストラクタのドキュメントは継承しないのでMarketに書く。ランタイムは末尾のメタデータハッシュだけが違う
// 第37章 第147講末の版: 第146講の版とコードは同じ。test/Docs.t.solがABIの項目ごとにuserdocのnoticeを確認(rawMetadataから読む)。ドキュメントのページはci.shの最後でforge docで作る
// 第38章 第148講末の版: 第147講の版とコードは同じ。forge fmtでsrc・testの空白と改行だけを直す(Market.solはコンストラクタ宣言の一か所)。宣言の順番とファイル分割はそのまま(スタイルの例外一覧)
// 第38章 第149講末の版: 第148講の版とコードは同じ。PositionLibの最初の引数名だけをselfに変える。ABIに出る名前(関数・イベント・エラー・自動ゲッター)はそのまま。名前チェック四つはci.shのforge lint
// 第39章 第150講末の版: 第149講の版とコードは同じ。引き出しは各自が取りに来る形(withdraw)、帳簿を先に減らしてからトークンを送る。Marketが他人に送ってあげる行と送るループなし。test/Pull.t.solが受け取る側で止まった引き出しとトークンが見る帳簿を確認
// 第39章 第151講末の版: 第150講の版とコードは同じ。管理者専用はaddAsset・setStatusの二つ(msg.senderを確認、tx.originは使わない)。adminはimmutableなので譲ったり空にしたりする関数なし。test/Access.t.solが権限の一覧を確認
// 第39章 第152講末の版: 第151講の版とコードは同じ。市場の三つの状態の間は管理者が任意の順番で変える(同じ状態に変える呼び出しもイベントを出す)。時間で変わる状態なし。test/StatusTable.t.solが状態表を確認
// 第41章 第154講末の版: 第152講・第153講の版とコードは同じ。Marketが呼ぶトークン関数はIERC20の三つ(balanceOf・transferFrom・transfer)。test/Standard.t.solが承認を要求するテスト用の標準トークン(test/StdToken.sol)とのかみ合わせを確認。MockTokenは承認なしで移すテスト用のまま
// 第41章 第155講末の版: 第154講の版とコードは同じ。Marketが使う承認はdepositのtransferFrom(msg.sender, Market, amount)の一か所。fromを引数で受け取る関数なし。test/Allowance.t.solが確認
// 第41章 第156講末の版: 第155講の版とコードは同じ。ERC-721のアドレスを資産として上場すると、transferFromの戻り値がないのでdepositが巻き戻る。onERC721Receivedなし。test/Nft.t.solが確認
// 第41章 第157講末の版: 第156講の版とコードは同じ。資産の欄はアドレス一つにトークン一つ。ERC-1155のアドレスはtransferFromがないのでdepositが巻き戻る。test/Multi.t.solが確認
// 第41章 第158講末の版: 第157講の版とコードは同じ。金庫の標準(ERC-4626)には従わない。帳簿はtotalDeposits・positionsなので、depositを通さずに入ってきたトークンは数えない。test/Donation.t.solが確認
// 第41章 第159講末の版: 第158講の版とコードは同じ。supportsInterface(ERC-165)なし。IMarketのインターフェースID 0xab691738。test/Introspection.t.solが確認
// 第42章 第160講末の版: 第159講の版とコードは同じ。プロキシなし。テスト用プロキシ(test/SlotProxy.sol)の後ろに置くと、immutable三つは実装コードから、帳簿はプロキシのストレージから出てくる。test/Proxy.t.solが確認
// 第42章 第161講末の版: 第160講の版とコードは同じ。プロキシのアップグレード関数のセレクター(0x3659cfe6・0x4f1ef286)はMarketにない。test/ProxySelectors.t.solが確認
// 第42章 第162講末の版: 第161講の版とコードは同じ。UUPSの関数(proxiableUUID・upgradeToAndCall)なし。Market自身にはコードを変える道がない。test/Uups.t.solが確認
// 第42章 第163講末の版: 第162講の版とコードは同じ。ランタイムがサイズ上限(24,576バイト)内なので、関数をファセット(facet)に分けない。test/Size.t.solが確認
// 第42章 第164講末の版: 第163講の版とコードは同じ。プロキシを置かないことにする(アップグレード判断の記録)。プロキシの後ろで実装を変えるとimmutableの管理者も変わる。test/Upgrade.t.solが確認
// 第46章 第178講末の版: 第164講の版 + withdrawからnotFrozenを外す。Frozenは資産の追加と預け入れだけを止め、引き出しは止めない。管理者の席にはマルチシグのアドレスを置く(デプロイの決定)。test/Keys.t.solが確認
// 第53章 第197講末の版: 第178講の版 + 借り入れ・返済、資産ごとの利息の指数(借りた比率の曲線)、時間加重平均価格で担保の上限。test/Borrow.t.solが確認
// 第53章 第198講末の版: 第197講の版 + 清算(清算ライン = 担保比率 + 5、ボーナス5%、一度に借金の50%まで、受け取った担保は帳簿の欄へ)。test/Liquidate.t.solが確認
// 第110講: 市場の状態(status、StatusChanged、notFrozen・whenActive)を親に切り出す。Marketが継承し、デプロイ物一つにまとまる
// 親の変数が前のスロットなので、statusはそのままスロット0
// 第111講: その版にはvirtualが一つもなかった(第113講で_checkDepositに付ける)
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
    // 第178講: Frozenは資産の追加と預け入れだけを止める。引き出しはどの状態でもできる(管理者の鍵で預けたお金を縛れない)
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
// 第178講: 引き出しのnotFrozenは外す。預け入れのwhenActiveのためにMarketBaseはそのまま継承
// 第114講: AssetRegistryと同じ理由でabstract
abstract contract Ledger is MarketBase {
    // 第118講: positions[asset][user].credit(amount)はPositionLib.credit(positions[asset][user], amount)と同じ呼び出し
    // この行はLedgerの中でだけ通る。Ledgerを継承したMarketでは.creditを使えない(Error 9582)
    using PositionLib for Position;

    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;
    mapping(address asset => Amount) public totalBorrows;
    // 第197講: 資産ごとの利息の指数(スロット6)。totalDeposits・totalBorrows・positionsの金額はこの指数で割った取り分
    mapping(address asset => Reserve) public reserves;

    // 第113講: Marketから移す。チェックは_checkDepositの列全体が受け持つ
    // 第146講: @devを書くとIMarketのドキュメントを継承しないので@inheritdocで取ってくる
    /// @inheritdoc IMarket
    /// @dev チェックの順番は_checkDepositの列。上場確認の後に金額確認
    function deposit(address asset, uint256 amount) external whenActive {
        _checkDeposit(asset, amount);
        (, uint256 s) = _accrue(asset); // 第197講: 利息を今まで積み、取り分に変える(切り捨て)
        _credit({asset: asset, user: msg.sender, amount: amount * 1e18 / s});
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
    // 第178講: notFrozenを外す。管理者の鍵を失くしたり奪われたりしても、預けた人は自分の分を引き出せる
    function withdraw(address asset, uint256 amount) public {
        if (amount == 0) revert ZeroAmount(); // 第90講、第108講
        (uint256 b, uint256 s) = _accrue(asset); // 第197講
        uint256 have = Amount.unwrap(positions[asset][msg.sender].deposited) * s / 1e18;
        if (have < amount) revert InsufficientDeposit(have, amount); // 第197講: トークンの量で比較
        uint256 cash = _cash(asset, b, s);
        if (cash < amount) revert InsufficientLiquidity(cash, amount); // 第197講: 貸し出された分は引き出せない
        _debit({asset: asset, user: msg.sender, amount: InterestMath.divUp(amount * 1e18, s)});
        _checkWithdraw(asset, msg.sender); // 第197講: 担保に使う資産なら、借金が上限内かを確認
        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
        if (!ok) revert TransferFailed(asset); // 第108講
        emit Withdrawn(asset, msg.sender, amount); // 第105講: withdrawAllもこの行で出力される
    }

    // 第100講: withdraw(address)でオーバーロードせず、名前を別に付ける
    // 第103講: modifierを別に付けない。内部で呼ぶwithdrawのnotFrozenが実行される
    // 第178講: withdrawからnotFrozenを外したので、withdrawAllもどの状態でも引き出せる
    // 第197講: 取り分ではなく利息を足したトークンの量で引き出す
    function withdrawAll(address asset) external {
        withdraw(asset, depositOf(asset, msg.sender));
    }

    // 第197講: 利息を足した預けた量(切り捨て)
    function depositOf(address asset, address user) public view returns (uint256) {
        (, uint256 s) = _indexesNow(asset);
        return Amount.unwrap(positions[asset][user].deposited) * s / 1e18;
    }

    // 第197講: 利息を足した返す量(切り上げ)
    function debtOf(address asset, address user) public view returns (uint256) {
        (uint256 b,) = _indexesNow(asset);
        return InterestMath.divUp(Amount.unwrap(positions[asset][user].borrowed) * b, 1e18);
    }

    // 第197講: 借りた比率。預けた量に対する貸し出された量
    function utilization(address asset) public view returns (uint256) {
        (uint256 b, uint256 s) = _indexesNow(asset);
        return InterestMath.utilization(
            Amount.unwrap(totalBorrows[asset]) * b / 1e18, Amount.unwrap(totalDeposits[asset]) * s / 1e18
        );
    }

    // 第197講: 今の借りた比率での年利
    function borrowRate(address asset) external view returns (Rate) {
        return InterestMath.borrowRate(utilization(asset), _rateAtKink());
    }

    // 第197講: 利息の指数を今の時刻まで上げた値。経過した時間の間、借りた比率の曲線の利率で借りた側の指数を上げ、
    // その分付いた利息を預けた取り分に分けて、預けた側の指数を上げる。同じブロック内ではそのまま
    function _indexesNow(address asset) internal view returns (uint256 b, uint256 s) {
        Reserve storage r = reserves[asset];
        b = r.borrowIndex == 0 ? 1e18 : r.borrowIndex;
        s = r.supplyIndex == 0 ? 1e18 : r.supplyIndex;
        uint256 scaledBorrows = Amount.unwrap(totalBorrows[asset]);
        uint256 elapsed = block.timestamp - r.lastAccrual;
        if (elapsed == 0 || scaledBorrows == 0) return (b, s);
        uint256 scaledDeposits = Amount.unwrap(totalDeposits[asset]);
        uint256 borrows = scaledBorrows * b / 1e18;
        Rate rate = InterestMath.borrowRate(InterestMath.utilization(borrows, scaledDeposits * s / 1e18), _rateAtKink());
        uint256 newB = b + InterestMath.interestFor(b, rate, elapsed);
        uint256 interest = scaledBorrows * newB / 1e18 - borrows;
        if (scaledDeposits != 0) s += interest * 1e18 / scaledDeposits; // 預けた側の取り分は切り捨て
        b = newB;
    }

    // 第197講: 利息の指数を今の時刻まで上げて書く。貸し出された取り分がなければ利息が付かないので書かない
    function _accrue(address asset) internal returns (uint256 b, uint256 s) {
        (b, s) = _indexesNow(asset);
        if (Amount.unwrap(totalBorrows[asset]) == 0) return (b, s);
        Reserve storage r = reserves[asset];
        r.borrowIndex = b;
        r.supplyIndex = s;
        r.lastAccrual = uint64(block.timestamp);
    }

    // 第197講: 市場に残ったトークン。預けた量 - 貸し出された量(帳簿で数える、直接送られたトークンは数えない)
    function _cash(address asset, uint256 b, uint256 s) internal view returns (uint256) {
        uint256 d = Amount.unwrap(totalDeposits[asset]) * s / 1e18;
        uint256 bw = InterestMath.divUp(Amount.unwrap(totalBorrows[asset]) * b, 1e18);
        return d > bw ? d - bw : 0;
    }

    // 第197講: 借りた取り分を増やす(切り上げ)。貸し出された取り分が0から始まるなら利息の時刻を今に
    function _addDebt(address asset, address user, uint256 amount, uint256 b) internal {
        if (Amount.unwrap(totalBorrows[asset]) == 0) reserves[asset].lastAccrual = uint64(block.timestamp);
        uint256 scaled = InterestMath.divUp(amount * 1e18, b);
        positions[asset][user].borrowed = positions[asset][user].borrowed + Amount.wrap(scaled);
        totalBorrows[asset] = totalBorrows[asset] + Amount.wrap(scaled);
    }

    // 第197講: 借りた取り分を減らす。借金より多ければ借金の分だけ。一部だけ返すなら減らす取り分は切り捨て
    function _subDebt(address asset, address user, uint256 amount, uint256 b) internal returns (uint256 paid) {
        Position storage p = positions[asset][user];
        uint256 scaledHave = Amount.unwrap(p.borrowed);
        if (scaledHave == 0) revert NoDebt(asset);
        uint256 debt = InterestMath.divUp(scaledHave * b, 1e18);
        uint256 scaled;
        if (amount >= debt) {
            paid = debt;
            scaled = scaledHave;
        } else {
            paid = amount;
            scaled = amount * 1e18 / b;
        }
        p.borrowed = p.borrowed - Amount.wrap(scaled);
        totalBorrows[asset] = totalBorrows[asset] - Amount.wrap(scaled);
    }

    // 第197講: 折れ点の年利。値はMarketのinterestRate
    function _rateAtKink() internal view virtual returns (Rate);

    // 第197講: 引き出し後のチェック。ここは空の本体、Marketが借金の確認を足す
    function _checkWithdraw(address asset, address user) internal view virtual {}

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
/// @title レンディング市場
/// @notice 管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket
/// @dev デプロイするのはこのコントラクト一つ。三つの親(MarketBase、AssetRegistry、Ledger)はabstract
contract Market is AssetRegistry, Ledger {
    // 第102講: コンストラクタで一度決め、変える関数がない値はimmutable。ストレージスロットなしでランタイムコードに入る
    // 第114講: adminはMarketBaseへ、collateralRatioはAssetRegistryへ移し、interestRateだけを残す
    Rate public immutable interestRate;

    // 第197講: 資産ごとの価格の出どころと小数点以下の桁数(スロット7)
    mapping(address asset => PriceConfig) public priceConfig;
    // 第197講: 時間加重平均を出すウィンドウ。定数なので管理者も変えられない
    uint32 public constant TWAP_WINDOW = 30 minutes;
    // 第198講: 清算の定数三つ。定数なので管理者も変えられない
    uint256 public constant LIQUIDATION_GAP = 5; // 清算ライン = 資産ごとの担保比率 + 5(パーセントポイント)
    uint256 public constant LIQUIDATION_BONUS = 5; // 清算した人が返した値に加えて受け取る分(パーセント)
    uint256 public constant CLOSE_FACTOR = 50; // 一度に返せる借金(パーセント)

    // 第114講: デプロイ引数三つを受け取り、二つを親のコンストラクタへ渡す。実行の順番は書いた順番ではなくMarketBase、AssetRegistry、Ledger、Market
    /// @notice 市場を作る
    /// @param admin_ 管理者のアドレス。0ならZeroAdmin
    /// @param interestRate_ 借りた比率が折れ点(80%)のときの年利(倍率10の18乗)
    /// @param collateralRatio_ 資産ごとに決める担保比率の上限(パーセント)
    constructor(address admin_, Rate interestRate_, Ratio collateralRatio_)
        MarketBase(admin_)
        AssetRegistry(collateralRatio_)
    {
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

    // 第197講: Ledgerの利息の積み上げが使う利率
    function _rateAtKink() internal view override returns (Rate) {
        return interestRate;
    }

    // 第197講: 管理者が資産ごとに価格の出どころを一回だけ決める。決めた後に変える関数なし
    function setPriceFeed(address asset, IPriceFeed feed) external onlyAdmin notFrozen {
        if (!assetConfig[asset].listed) revert NotListed(asset);
        if (address(feed) == address(0)) revert ZeroFeed();
        if (address(priceConfig[asset].feed) != address(0)) revert PriceFeedAlreadySet(asset);
        uint8 d = IERC20(asset).decimals();
        priceConfig[asset] = PriceConfig({feed: feed, decimals: d});
        emit PriceFeedSet(asset, address(feed));
    }

    // 第197講: 預けた資産を担保に使うかを決める。オンにするときは価格の出どころが必要で、オフにするときは借金が上限内でなければならない
    function setCollateral(address asset, bool on) external {
        if (on && address(priceConfig[asset].feed) == address(0)) revert NoPriceFeed(asset);
        positions[asset][msg.sender].useAsCollateral = on;
        if (!on) _checkHealth(msg.sender);
        emit CollateralSet(asset, msg.sender, on);
    }

    // 第197講: 借り入れ。市場がActiveのときだけ。帳簿を先に直し、上限を確認してからトークンを送る
    function borrow(address asset, uint256 amount) external whenActive {
        if (amount == 0) revert ZeroAmount();
        if (address(priceConfig[asset].feed) == address(0)) revert NoPriceFeed(asset);
        (uint256 b, uint256 s) = _accrue(asset);
        uint256 cash = _cash(asset, b, s);
        if (cash < amount) revert InsufficientLiquidity(cash, amount);
        _addDebt(asset, msg.sender, amount, b);
        _checkHealth(msg.sender);
        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
        if (!ok) revert TransferFailed(asset);
        emit Borrowed(asset, msg.sender, amount);
    }

    // 第197講: 返済。市場の状態と関係なし。価格を読まない
    function repay(address asset, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        (uint256 b,) = _accrue(asset);
        uint256 paid = _subDebt(asset, msg.sender, amount, b);
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), paid); // 第83講
        if (!ok) revert TransferFromFailed(asset);
        emit Repaid(asset, msg.sender, paid);
    }

    // 第198講: 清算。借金が清算ラインを超えたアカウントの借金を代わりに返し、返した値にボーナスを足した分の担保を帳簿の欄で受け取る
    // マーケットの状態に関係なし。誰でも呼べる。帳簿を全部直したあと最後にトークンを受け取る
    function liquidate(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount) external {
        if (repayAmount == 0) revert ZeroAmount();
        (uint256 b,) = _accrue(debtAsset);
        _accrue(collateralAsset);
        _checkLiquidation(borrower, debtAsset, collateralAsset, repayAmount);
        uint256 seize = _seizeFor(debtAsset, collateralAsset, repayAmount);
        uint256 paid = _subDebt(debtAsset, borrower, repayAmount, b);
        _moveCollateral(collateralAsset, borrower, msg.sender, seize);
        bool ok = IERC20(debtAsset).transferFrom(msg.sender, address(this), paid); // 第83講
        if (!ok) revert TransferFromFailed(debtAsset);
        emit Liquidated(borrower, msg.sender, collateralAsset, debtAsset, paid, seize);
    }

    // 第198講: 清算前の確認三つ。借金が清算ラインを超えたか、受け取る資産が担保か、一度に返す量が借金のCLOSE_FACTOR%以下か
    function _checkLiquidation(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount)
        internal
        view
    {
        (uint256 limit, uint256 debtValue) = _health(borrower, LIQUIDATION_GAP);
        if (debtValue <= limit) revert NotLiquidatable(limit, debtValue);
        if (!positions[collateralAsset][borrower].useAsCollateral) revert NotCollateral(collateralAsset);
        uint256 maxRepay = debtOf(debtAsset, borrower) * CLOSE_FACTOR / 100;
        if (repayAmount > maxRepay) revert AboveCloseFactor(maxRepay, repayAmount);
    }

    // 第198講: 借金のあるアカウントの担保欄から清算したアカウントの欄へ移す。引く分は切り上げ、入れる分は切り捨て
    function _moveCollateral(address asset, address from, address to, uint256 amount) internal {
        (, uint256 s) = _indexesNow(asset);
        uint256 have = Amount.unwrap(positions[asset][from].deposited) * s / 1e18;
        if (amount > have) revert SeizeExceedsCollateral(have, amount);
        _debit({asset: asset, user: from, amount: InterestMath.divUp(amount * 1e18, s)});
        _credit({asset: asset, user: to, amount: amount * 1e18 / s});
    }

    // 第198講: 返す量の値にボーナスを足して担保トークンの量に(切り捨て)
    function _seizeFor(address debtAsset, address collateralAsset, uint256 repayAmount)
        internal
        view
        returns (uint256)
    {
        uint256 unit = 10 ** priceConfig[collateralAsset].decimals;
        return
            _value(debtAsset, repayAmount, false) * (100 + LIQUIDATION_BONUS) * unit / (100 * priceOf(collateralAsset));
    }

    // 第197講: 価格の出どころからTWAP_WINDOW秒の時間加重平均。その瞬間の価格は読まない
    function priceOf(address asset) public view returns (uint256) {
        IPriceFeed feed = priceConfig[asset].feed;
        if (address(feed) == address(0)) revert NoPriceFeed(asset);
        return (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
    }

    // 第197講: 借りられる上限(担保の価値 × 資産ごとの担保比率)と借金の価値。価値の単位は倍率10の18乗
    // 資産一覧をすべて回る。担保の価値は切り捨て、借金の価値は切り上げ
    // 第198講: 本体を_healthに移した
    function accountHealth(address user) public view returns (uint256 borrowLimit, uint256 debtValue) {
        return _health(user, 0);
    }

    // 第198講: 清算ライン。担保の値 × (資産ごとの担保比率 + LIQUIDATION_GAP)の合計。借金がこの値を超えたら清算
    function liquidationLimit(address user) external view returns (uint256 limit) {
        (limit,) = _health(user, LIQUIDATION_GAP);
    }

    // 第198講: accountHealthの本体。gapは担保比率に足すパーセントポイント(借入上限は0、清算ラインはLIQUIDATION_GAP)
    function _health(address user, uint256 gap) internal view returns (uint256 limit, uint256 debtValue) {
        for (uint256 i = 0; i < assets.length; i++) {
            address a = address(assets[i]);
            Position storage p = positions[a][user];
            if (p.useAsCollateral && Amount.unwrap(p.deposited) != 0) {
                uint256 v = _value(a, depositOf(a, user), false);
                limit += v * (Ratio.unwrap(assetConfig[a].collateralRatio) + gap) / 100;
            }
            if (Amount.unwrap(p.borrowed) != 0) debtValue += _value(a, debtOf(a, user), true);
        }
    }

    // 第197講: トークンの量を価値に。資産ごとの小数点以下の桁数で割る(10のdecimals乗)
    function _value(address asset, uint256 amount, bool roundUp) internal view returns (uint256) {
        uint256 x = amount * priceOf(asset);
        uint256 unit = 10 ** priceConfig[asset].decimals;
        return roundUp ? InterestMath.divUp(x, unit) : x / unit;
    }

    // 第197講: 借金が借りられる上限を超えると巻き戻す
    function _checkHealth(address user) internal view {
        (uint256 limit, uint256 debt) = accountHealth(user);
        if (debt > limit) revert InsufficientCollateral(limit, debt);
    }

    // 第197講: 担保に使う資産を引き出した後にだけ借金を確認
    function _checkWithdraw(address asset, address user) internal view override {
        if (positions[asset][user].useAsCollateral) _checkHealth(user);
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
