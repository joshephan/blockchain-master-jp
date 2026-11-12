// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ToyAmm} from "./ToyAmm.sol";
import {ToyErc20} from "./ToyErc20.sol";

// 講義用のユーザー側の交換の入口。受け取る最小量と締め切り時刻を一緒に受け取る
// 締め切り時刻が過ぎていればプールを呼ぶ前にリバート。受け取る最小量はプールが確認する
contract GuardedSwap {
    error Expired(uint256 deadline, uint256 nowTs);

    function swap(ToyAmm pool, ToyErc20 tokenIn, ToyErc20 tokenOut, uint256 amountIn, uint256 minOut, uint256 deadline)
        external
        returns (uint256 out)
    {
        if (block.timestamp > deadline) revert Expired(deadline, block.timestamp);
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenIn.approve(address(pool), amountIn);
        out = pool.swap(address(tokenIn), amountIn, minOut);
        tokenOut.transfer(msg.sender, out);
    }
}
