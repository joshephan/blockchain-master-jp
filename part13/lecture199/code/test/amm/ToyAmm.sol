// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ToyErc20} from "./ToyErc20.sol";

// 第194講の講義用の定積プール(x * y = k)。実在のプロトコルのコードではない、最小の形
// プールのシェア(LPトークン)はこのコントラクト自身が発行するトークン(第195講)
contract ToyAmm is ToyErc20 {
    ToyErc20 public immutable token0;
    ToyErc20 public immutable token1;
    uint256 public immutable feeBps; // 30なら0.3%

    uint256 public reserve0;
    uint256 public reserve1;

    error ZeroAmount();
    error BadToken(address token);
    error Slippage(uint256 got, uint256 minOut);
    error KDecreased(uint256 before, uint256 afterSwap);

    constructor(ToyErc20 t0, ToyErc20 t1, uint256 feeBps_) ToyErc20(18) {
        token0 = t0;
        token1 = t1;
        feeBps = feeBps_;
    }

    // 入れる量は引数ではなく残高の差で数える(手数料トークンも実際に入ってきた分だけ)
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        uint256 in0 = token0.balanceOf(address(this)) - reserve0;
        uint256 in1 = token1.balanceOf(address(this)) - reserve1;
        if (totalSupply == 0) {
            shares = Math.sqrt(in0 * in1);
        } else {
            shares = Math.min(in0 * totalSupply / reserve0, in1 * totalSupply / reserve1);
        }
        if (shares == 0) revert ZeroAmount();
        _mint(msg.sender, shares);
        _sync();
    }

    // シェアの比率の分だけ二つのトークンを返す。割り算の余りはプールに残る
    function removeLiquidity(uint256 shares) external returns (uint256 out0, uint256 out1) {
        out0 = shares * reserve0 / totalSupply;
        out1 = shares * reserve1 / totalSupply;
        if (out0 == 0 && out1 == 0) revert ZeroAmount();
        _burn(msg.sender, shares);
        token0.transfer(msg.sender, out0);
        token1.transfer(msg.sender, out1);
        _sync();
    }

    // 受け取る量: 手数料を引いた後に積がそのままになる量を切り捨て
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public view returns (uint256) {
        uint256 inWithFee = amountIn * (10_000 - feeBps);
        return inWithFee * reserveOut / (reserveIn * 10_000 + inWithFee);
    }

    // 入れる量: 欲しい量を受け取るにはいくら入れればよいかを切り上げ
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) public view returns (uint256) {
        return
            Math.mulDiv(reserveIn * amountOut, 10_000, (reserveOut - amountOut) * (10_000 - feeBps), Math.Rounding.Ceil);
    }

    function quote(address tokenIn, uint256 amountIn) external view returns (uint256) {
        (uint256 rIn, uint256 rOut) = tokenIn == address(token0) ? (reserve0, reserve1) : (reserve1, reserve0);
        return getAmountOut(amountIn, rIn, rOut);
    }

    // 受け取る最小量(minOut)を下回れば巻き戻す。最後に積が減っていないかを確認
    function swap(address tokenIn, uint256 amountIn, uint256 minOut) external returns (uint256 out) {
        bool zeroIn = tokenIn == address(token0);
        if (!zeroIn && tokenIn != address(token1)) revert BadToken(tokenIn);
        (ToyErc20 tIn, ToyErc20 tOut) = zeroIn ? (token0, token1) : (token1, token0);
        (uint256 rIn, uint256 rOut) = zeroIn ? (reserve0, reserve1) : (reserve1, reserve0);

        tIn.transferFrom(msg.sender, address(this), amountIn);
        uint256 received = tIn.balanceOf(address(this)) - rIn;
        if (received == 0) revert ZeroAmount();
        out = getAmountOut(received, rIn, rOut);
        if (out < minOut) revert Slippage(out, minOut);
        tOut.transfer(msg.sender, out);

        uint256 kBefore = reserve0 * reserve1;
        _sync();
        uint256 kAfter = reserve0 * reserve1;
        if (kAfter < kBefore) revert KDecreased(kBefore, kAfter);
    }

    // token0一個がtoken1何個か(倍率10の18乗)。その瞬間の残高の比率、桁数の補正なし
    function spotPrice() external view returns (uint256) {
        return reserve1 * 1e18 / reserve0;
    }

    function _sync() internal {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }
}
