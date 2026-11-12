// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Vault, Peeker} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault v;
    Peeker pk;

    function setUp() public {
        v = new Vault();
        pk = new Peeker{value: 1 ether}(v);
        pk.put();
    }

    function test_sendFirst() public {
        pk.takeSendFirst();
        console.log("seenEntry   ", pk.seenEntry());
        console.log("seenVaultEth", pk.seenVaultEth());
        console.log("entry after ", v.balances(address(pk)));
    }

    function test_stateFirst() public {
        pk.takeStateFirst();
        console.log("seenEntry   ", pk.seenEntry());
        console.log("seenVaultEth", pk.seenVaultEth());
        console.log("entry after ", v.balances(address(pk)));
    }
}
