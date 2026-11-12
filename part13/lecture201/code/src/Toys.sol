// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 講義用のトークン。発行とバーンはminter一人だけ
contract SimpleToken {
    string public name;
    address public immutable minter;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error NotMinter(address caller);
    error InsufficientBalance(uint256 have, uint256 want);
    error InsufficientAllowance(uint256 have, uint256 want);

    constructor(string memory name_, address minter_) {
        name = name_;
        minter = minter_;
    }

    function mint(address to, uint256 value) external {
        if (msg.sender != minter) revert NotMinter(msg.sender);
        totalSupply += value;
        balanceOf[to] += value;
    }

    function burn(address from, uint256 value) external {
        if (msg.sender != minter) revert NotMinter(msg.sender);
        uint256 b = balanceOf[from];
        if (b < value) revert InsufficientBalance(b, value);
        balanceOf[from] = b - value;
        totalSupply -= value;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
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
        uint256 b = balanceOf[from];
        if (b < value) revert InsufficientBalance(b, value);
        balanceOf[from] = b - value;
        balanceOf[to] += value;
    }
}

// 講義用の価格記録。値はowner一人が書く(1e18 = 1ドル)
// settledPriceは前のブロックまでに書かれた値だけを返す。同じブロックで新しく書いた値は次のブロックから
contract ToyOracle {
    address public immutable owner;
    uint256 public price;
    uint256 public prevPrice;
    uint256 public updatedBlock;

    error NotOwner(address caller);

    constructor(uint256 price_) {
        owner = msg.sender;
        price = price_;
        prevPrice = price_;
        updatedBlock = block.number;
    }

    function update(uint256 price_) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        if (updatedBlock < block.number) prevPrice = price;
        price = price_;
        updatedBlock = block.number;
    }

    function settledPrice() external view returns (uint256) {
        return updatedBlock < block.number ? price : prevPrice;
    }
}
