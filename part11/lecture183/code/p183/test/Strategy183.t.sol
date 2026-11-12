// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";

/// @notice 同じ規則、入力だけを番号の範囲(0~3)に狭める
contract ValueBoundProbeTest is Test {
    Airdrop drop;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new Airdrop(alice, bob);
    }

    function testFuzz_aliceNeverOverpaid(uint8[] calldata raw) public {
        uint256[] memory ids = new uint256[](raw.length);
        for (uint256 i = 0; i < raw.length; i++) {
            ids[i] = raw[i] % 4;
        }
        vm.prank(alice);
        try drop.claim(ids) {} catch {}
        assertLe(drop.paid(alice), 200);
    }
}

/// @notice 同じ規則、番号の範囲(0~3)と配列の長さ(0~4)を一緒に狭める
contract ShapeBoundProbeTest is Test {
    Airdrop drop;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new Airdrop(alice, bob);
    }

    function testFuzz_aliceNeverOverpaid(uint8[] calldata raw) public {
        uint256 n = raw.length % 5;
        uint256[] memory ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = raw[i] % 4;
        }
        vm.prank(alice);
        try drop.claim(ids) {} catch {}
        assertLe(drop.paid(alice), 200);
    }
}

/// @notice 状態を変えながら呼ぶ側(ハンドラー): 番号は0~3、呼ぶ人はalice・bob
contract AirdropHandler is Test {
    Airdrop public drop;
    address[2] users;

    constructor(Airdrop d, address a, address b) {
        drop = d;
        users[0] = a;
        users[1] = b;
    }

    function claim(uint256 who, uint8[] calldata raw) external {
        uint256 n = raw.length % 5;
        uint256[] memory ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = raw[i] % 4;
        }
        vm.prank(users[who % 2]);
        try drop.claim(ids) {} catch {}
    }
}

/// @notice 不変条件: 何回どんな順番で呼んでも常に成り立たなければならないもの
contract AirdropInvariantTest is Test {
    Airdrop drop;
    AirdropHandler handler;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new Airdrop(alice, bob);
        handler = new AirdropHandler(drop, alice, bob);
        targetContract(address(handler));
    }

    function invariant_paidPlusRemainingIs400() public view {
        assertEq(drop.paid(alice) + drop.paid(bob) + drop.remaining(), 400);
    }

    function invariant_nobodyOverpaid() public view {
        assertLe(drop.paid(alice), 200);
        assertLe(drop.paid(bob), 200);
    }
}
