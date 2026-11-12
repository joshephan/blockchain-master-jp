// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";

// 設計文書2節のストレージスロットの地図どおりに置かれたかをvm.loadで確認
// 0 assets、1 assetConfig(二スロット)、2 reserves(五スロット)、3 positions(三スロット)、4 guardian
contract LayoutTest is Base {
    function setUp() public {
        _deploy(0);
        _openPosition();
    }

    function test_slotMap() public view {
        assertEq(uint256(vm.load(address(market), bytes32(uint256(0)))), 2); // assetsの長さ
        bytes32 a0 = keccak256(abi.encode(uint256(0)));
        assertEq(address(uint160(uint256(vm.load(address(market), a0)))), address(col));
        bytes32 cfg = keccak256(abi.encode(address(usd), uint256(1)));
        uint256 w = uint256(vm.load(address(market), cfg));
        assertEq(address(uint160(w)), address(usdFeed)); // feedのオフセット0
        assertEq(uint8(w >> 160), 6); // decimalsのオフセット20
        assertEq(uint8(w >> 168), 80); // collateralRatioのオフセット21
        assertEq(uint8(w >> 176), 0); // pausedBitsのオフセット22
        assertEq(uint8(w >> 184), 1); // listedのオフセット23
        assertEq(uint256(vm.load(address(market), bytes32(uint256(cfg) + 1))), type(uint256).max); // supplyCap
        bytes32 res = keccak256(abi.encode(address(usd), uint256(2)));
        assertEq(uint256(vm.load(address(market), res)), 1000e6); // scaledDeposits
        assertEq(uint256(vm.load(address(market), bytes32(uint256(res) + 1))), 700e6); // scaledBorrows
        bytes32 pos = keccak256(abi.encode(alice, keccak256(abi.encode(address(usd), uint256(3)))));
        assertEq(uint256(vm.load(address(market), bytes32(uint256(pos) + 1))), 700e6); // alice scaledDebt
        bytes32 posCol = keccak256(abi.encode(alice, keccak256(abi.encode(address(col), uint256(3)))));
        assertEq(uint256(vm.load(address(market), posCol)), 1000e18); // alice scaledDeposit
        assertEq(uint256(vm.load(address(market), bytes32(uint256(posCol) + 2))), 1); // useAsCollateral
        assertEq(address(uint160(uint256(vm.load(address(market), bytes32(uint256(4)))))), address(this)); // guardian
    }
}
