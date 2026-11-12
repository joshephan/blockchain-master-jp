// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BoxUUPS, BoxUUPSV2} from "../src/Boxes.sol";

// 第162講のデモのトレース: コードのないアドレスにアップグレードするとどこで止まるか
contract Uups162Test is Test {
    function test_upgradeToCodeless() public {
        BoxUUPS v1 = new BoxUUPS();
        ERC1967Proxy px = new ERC1967Proxy(address(v1), abi.encodeCall(BoxUUPS.initialize, (address(this))));
        (bool ok, bytes memory data) =
            address(px).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0xBEEF), ""));
        assertFalse(ok);
        assertEq(data.length, 0);
    }
}
