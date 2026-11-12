// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";

// ABIの項目ごとにドキュメント(NatSpec notice)があるか確認。読むのはforgeの成果物のrawMetadata(コンパイラが出した原文)
// 文がコードと合っているかは確認しない。ガス計測は止める(読むJSONの長さで.gas-snapshotの行が揺れる)
contract DocsTest is Test {
    function _artifact() internal view returns (string memory) {
        return vm.readFile(vm.getArtifactPathByCode(type(Market).creationCode));
    }

    function _count(string memory art, string memory kind) internal pure returns (uint256 n) {
        string[] memory types = abi.decode(vm.parseJson(art, ".abi[*].type"), (string[]));
        for (uint256 i = 0; i < types.length; i++) {
            if (keccak256(bytes(types[i])) == keccak256(bytes(kind))) n++;
        }
    }

    function test_everyFunctionHasNotice() public {
        vm.pauseGasMetering();
        string memory art = _artifact();
        string memory meta = vm.parseJsonString(art, ".rawMetadata");
        string[] memory sigs = vm.parseJsonKeys(art, ".methodIdentifiers");
        assertEq(sigs.length, 38);
        for (uint256 i = 0; i < sigs.length; i++) {
            assertTrue(
                vm.keyExistsJson(meta, string.concat(".output.userdoc.methods['", sigs[i], "'].notice")), sigs[i]
            );
        }
    }

    function test_everyEventAndErrorHasNotice() public {
        vm.pauseGasMetering();
        string memory art = _artifact();
        string memory meta = vm.parseJsonString(art, ".rawMetadata");
        assertEq(_count(art, "event"), 11);
        assertEq(_count(art, "error"), 23);
        assertEq(vm.parseJsonKeys(meta, ".output.userdoc.events").length, 11);
        // エラー23のうちSafeERC20FailedOperationは取り込んだコード(OpenZeppelin)に@devしかないのでuserdocにない
        assertEq(vm.parseJsonKeys(meta, ".output.userdoc.errors").length, 22);
        assertTrue(vm.keyExistsJson(meta, ".output.devdoc.errors['SafeERC20FailedOperation(address)']"));
    }
}
