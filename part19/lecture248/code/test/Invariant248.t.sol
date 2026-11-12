// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Bank248, BankNoDebit248} from "../src/Bank248.sol";

// ランダムにmoveを呼ぶ側。送る人は二人のうち一人、金額は持っている分まで
contract Handler248 is Test {
    Bank248 public bank;
    address[2] public users = [address(0xA11CE), address(0xB0B)];
    uint256 public calls;

    constructor(Bank248 b) {
        bank = b;
        bank.mint(users[0], 1000);
        bank.mint(users[1], 1000);
    }

    function move(uint256 fromIndex, uint256 amount) external {
        address from = users[fromIndex % 2];
        address to = users[(fromIndex % 2 + 1) % 2];
        amount = bound(amount, 0, bank.balanceOf(from));
        vm.prank(from);
        bank.move(to, amount);
        calls++;
    }
}

contract InvariantOk248 is Test {
    Handler248 h;

    function setUp() public {
        h = new Handler248(new Bank248());
        targetContract(address(h));
    }

    function invariant_sumEqualsSupply() public view {
        Bank248 b = h.bank();
        assertEq(b.balanceOf(h.users(0)) + b.balanceOf(h.users(1)), b.totalSupply());
    }
}

contract InvariantNoDebit248 is Test {
    Handler248 h;

    function setUp() public {
        h = new Handler248(new BankNoDebit248());
        targetContract(address(h));
    }

    function invariant_sumEqualsSupply() public view {
        Bank248 b = h.bank();
        assertEq(b.balanceOf(h.users(0)) + b.balanceOf(h.users(1)), b.totalSupply());
    }
}
