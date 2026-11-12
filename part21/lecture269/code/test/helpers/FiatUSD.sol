// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 講義用の法定通貨担保型トークン。準備金はチェーンの外の銀行口座にあると仮定、コードには準備金の欄なし
// 発行体の鍵一つが発行・凍結を担う
contract FiatUSD {
    string public constant name = "Fiat USD";
    string public constant symbol = "FUSD";
    uint8 public constant decimals = 6;

    address public immutable issuer;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozen;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Redeemed(address indexed holder, uint256 value); // ドルの支払いはチェーンの外
    event Frozen(address indexed account, bool isFrozen);

    error NotIssuer(address caller);
    error AccountFrozen(address account);
    error InsufficientBalance(uint256 have, uint256 want);
    error InsufficientAllowance(uint256 have, uint256 want);

    constructor(address issuer_) {
        issuer = issuer_;
    }

    modifier onlyIssuer() {
        if (msg.sender != issuer) revert NotIssuer(msg.sender);
        _;
    }

    // 発行体がチェーンの外でドルを受け取ったあとに発行する。受け取ったかはコードが確認しない
    function mint(address to, uint256 value) external onlyIssuer {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    // 保有者がバーンしてドルを請求する。ドルを送る行はない
    function redeem(uint256 value) external {
        _move(msg.sender, address(0), value);
        totalSupply -= value;
        emit Redeemed(msg.sender, value);
    }

    function setFrozen(address account, bool isFrozen) external onlyIssuer {
        frozen[account] = isFrozen;
        emit Frozen(account, isFrozen);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _move(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        if (a < value) revert InsufficientAllowance(a, value);
        allowance[from][msg.sender] = a - value;
        _move(from, to, value);
        return true;
    }

    function _move(address from, address to, uint256 value) internal {
        if (frozen[from]) revert AccountFrozen(from);
        if (frozen[to]) revert AccountFrozen(to);
        uint256 b = balanceOf[from];
        if (b < value) revert InsufficientBalance(b, value);
        balanceOf[from] = b - value;
        if (to != address(0)) balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
