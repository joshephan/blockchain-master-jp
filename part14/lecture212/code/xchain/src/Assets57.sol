// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IReceiver} from "./Msg57.sol";
import {ToyOutbox} from "./Outbox57.sol";

// デモ用の元のトークン。作ったアカウントが1000個を持つ
contract TestToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1000);
    }
}

// outbox・endpointのアドレス・相手側(チェーン番号、アドレス)・受け取り側の確認をまとめた共通部分。相手側はデプロイしたアカウントが一度だけ決める
abstract contract PeerApp is IReceiver {
    error NotEndpoint(address caller);
    error NotPeer(uint256 srcChainId, address sender);
    error NotDeployer(address caller);
    error PeerAlreadySet();

    ToyOutbox public immutable outbox;
    address public immutable endpoint;
    address public immutable deployer;
    uint256 public peerChainId;
    address public peer;

    constructor(ToyOutbox outbox_, address endpoint_) {
        outbox = outbox_;
        endpoint = endpoint_;
        deployer = msg.sender;
    }

    function setPeer(uint256 chainId, address peer_) external {
        if (msg.sender != deployer) revert NotDeployer(msg.sender);
        if (peer != address(0)) revert PeerAlreadySet();
        peerChainId = chainId;
        peer = peer_;
    }

    function onMessage(uint256 srcChainId, address sender, bytes calldata payload) external {
        if (msg.sender != endpoint) revert NotEndpoint(msg.sender);
        if (srcChainId != peerChainId || sender != peer) revert NotPeer(srcChainId, sender);
        (address to, uint256 amount) = abi.decode(payload, (address, uint256));
        _receive(to, amount);
    }

    function _send(address to, uint256 amount) internal returns (bytes32) {
        return outbox.send(peerChainId, peer, abi.encode(to, amount));
    }

    function _receive(address to, uint256 amount) internal virtual;
}

// ロックアップ側の金庫: 元のトークンをロックして向こうに「発行してほしい」メッセージ。向こうでバーンしたというメッセージが来たら解放する
contract LockBox is PeerApp {
    IERC20 public immutable token;
    uint256 public locked;

    constructor(ToyOutbox outbox_, address endpoint_, IERC20 token_) PeerApp(outbox_, endpoint_) {
        token = token_;
    }

    function lock(uint256 amount, address to) external returns (bytes32) {
        token.transferFrom(msg.sender, address(this), amount);
        locked += amount;
        return _send(to, amount);
    }

    function _receive(address to, uint256 amount) internal override {
        locked -= amount;
        token.transfer(to, amount);
    }
}

// 向こうのチェーンのラップトークン。発行とバーンの関数はMinterだけが呼ぶ
contract WrappedToken is ERC20 {
    error NotMinter(address caller);

    address public immutable minter;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        minter = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter(msg.sender);
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter(msg.sender);
        _burn(from, amount);
    }
}

// ミント側: 金庫でロックしたというメッセージが来たらラップトークンを発行する。1日の上限と一時停止があり、止められたら受け取り側の失敗として残り、あとで入れ直す
contract Minter is PeerApp {
    error MintCapExceeded(uint256 wouldBe, uint256 cap);
    error Paused();
    error NotGuardian(address caller);

    WrappedToken public immutable wrapped;
    uint256 public immutable dailyCap;
    address public immutable guardian;
    bool public paused;
    mapping(uint256 day => uint256) public mintedOn;

    constructor(ToyOutbox outbox_, address endpoint_, uint256 dailyCap_, address guardian_)
        PeerApp(outbox_, endpoint_)
    {
        wrapped = new WrappedToken("Wrapped TKA", "wTKA");
        dailyCap = dailyCap_;
        guardian = guardian_;
    }

    function setPaused(bool p) external {
        if (msg.sender != guardian) revert NotGuardian(msg.sender);
        paused = p;
    }

    function burn(uint256 amount, address to) external returns (bytes32) {
        wrapped.burnFrom(msg.sender, amount);
        return _send(to, amount);
    }

    function _receive(address to, uint256 amount) internal override {
        if (paused) revert Paused();
        uint256 day = block.timestamp / 1 days;
        uint256 wouldBe = mintedOn[day] + amount;
        if (wouldBe > dailyCap) revert MintCapExceeded(wouldBe, dailyCap);
        mintedOn[day] = wouldBe;
        wrapped.mint(to, amount);
    }
}

// 流動性方式: 両方のチェーンに本物のトークンのプール。こちらのプールに入れ、向こうのプールが持つお金から払い出す。新しく発行するトークンはない
contract PoolBridge is PeerApp {
    error InsufficientLiquidity(uint256 have, uint256 need);

    IERC20 public immutable token;

    constructor(ToyOutbox outbox_, address endpoint_, IERC20 token_) PeerApp(outbox_, endpoint_) {
        token = token_;
    }

    function send(uint256 amount, address to) external returns (bytes32) {
        token.transferFrom(msg.sender, address(this), amount);
        return _send(to, amount);
    }

    function _receive(address to, uint256 amount) internal override {
        uint256 have = token.balanceOf(address(this));
        if (have < amount) revert InsufficientLiquidity(have, amount);
        token.transfer(to, amount);
    }
}
