// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第171講の標準違反トークンとコンポーザビリティの縮小版。トイ、ローカルのforge専用。

// 標準どおりにboolを返すトークン(基準)
contract GoodToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }
}

// 戻り値のないトークン(USDTの形)。標準はboolを返せと言うが、何も返さない
contract NoReturnToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    // returnsなし
    function transfer(address to, uint256 a) external {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
    }
}

// 移すときに手数料を引くトークン。受け取る側は送った量より少なく受け取る
contract FeeToken {
    mapping(address => uint256) public balanceOf;
    uint256 public feeBps = 100; // 1%

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address from, address to, uint256 a) external returns (bool) {
        uint256 fee = (a * feeBps) / 10000;
        balanceOf[from] -= a;
        balanceOf[to] += (a - fee); // 手数料の分だけ少なく届く
        return true;
    }
}

// SafeERC20の縮小版: 戻り値がなければ(コードがあるアドレスなら)成功とみなし、あればtrueでなければならない
library SafeTransferLib {
    error SafeTransferFailed(address token);

    function safeTransfer(address token, address to, uint256 amount) internal {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        (bool ok, bytes memory ret) = token.call(data);
        if (!ok) revert SafeTransferFailed(token);
        // 戻りデータがなければコードの有無で判定、あればtrueでなければならない
        if (ret.length != 0 && !abi.decode(ret, (bool))) revert SafeTransferFailed(token);
        if (ret.length == 0 && token.code.length == 0) revert SafeTransferFailed(token);
    }
}

// boolを必ず受け取ろうとする厳格な利用側(no-returnトークンで壊れる)
contract StrictConsumer {
    function send(address token, address to, uint256 a) external returns (bool) {
        // transfer(address,uint256)がboolを返すと信じてデコード
        return IBoolToken(token).transfer(to, a);
    }
}

// SafeTransferLibを使う利用側(no-returnトークンも処理)
contract SafeConsumer {
    using SafeTransferLib for address;

    function send(address token, address to, uint256 a) external {
        token.safeTransfer(to, a);
    }
}

interface IBoolToken {
    function transfer(address to, uint256 a) external returns (bool);
}
