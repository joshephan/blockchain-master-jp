// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ShadowInit} from "../src/Shadow.sol";
import {CtorBox, InitBox} from "../src/Init.sol";

contract InitTest is Test {
    function test_shadowedInitializeLeavesOwnerEmpty() public {
        ShadowInit impl = new ShadowInit();
        ShadowInit p = ShadowInit(address(new ERC1967Proxy(address(impl), "")));
        p.initialize(address(0xA11CE));
        assertEq(p.owner(), address(0));
        assertTrue(p.done());
        vm.expectRevert(bytes("done"));
        p.initialize(address(0xA11CE));
    }

    function test_ctorValuesNotInProxy() public {
        CtorBox impl = new CtorBox();
        CtorBox p = CtorBox(address(new ERC1967Proxy(address(impl), "")));
        assertEq(impl.value(), 42);
        assertEq(p.value(), 0);
        assertEq(p.owner(), address(0));
    }

    function test_initSlotIsErc7201() public pure {
        bytes32 s = keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1))
            & ~bytes32(uint256(0xff));
        assertEq(s, 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00);
    }
}
