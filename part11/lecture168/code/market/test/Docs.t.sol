// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";

// 第147講: MarketのABIの項目ごとにuserdocのnoticeがあるかを確認。読む場所はforgeの成果物のrawMetadata(コンパイラが出した一行そのまま)
// 同じファイルのmetadataの欄はforgeが書き直した整理版なので、userdocのevents・errorsが抜ける
// 内容がコードと合っているかは確認しない。ドキュメントの文章は人が読んで直す
// ガスの計測を止める(vm.pauseGasMetering)。読むJSONの長さがドキュメントの文字数と成果物のパスによって変わり、.gas-snapshotの行が揺れる
contract DocsTest is Test {
    // プロファイルごとに違うoutフォルダ(out、out-debug、out-legacy)を生成コードで探す
    function _artifact() internal view returns (string memory) {
        return vm.readFile(vm.getArtifactPathByCode(type(Market).creationCode));
    }

    function _rawMetadata(string memory art) internal pure returns (string memory) {
        return vm.parseJsonString(art, ".rawMetadata");
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
        string memory meta = _rawMetadata(art);
        string[] memory sigs = vm.parseJsonKeys(art, ".methodIdentifiers");
        assertEq(sigs.length, 19);
        assertTrue(vm.keyExistsJson(meta, ".output.userdoc.methods.constructor.notice"), "constructor");
        for (uint256 i = 0; i < sigs.length; i++) {
            assertTrue(
                vm.keyExistsJson(meta, string.concat(".output.userdoc.methods['", sigs[i], "'].notice")), sigs[i]
            );
        }
    }

    function test_everyEventAndErrorHasNotice() public {
        vm.pauseGasMetering();
        string memory art = _artifact();
        string memory meta = _rawMetadata(art);
        assertEq(vm.parseJsonKeys(meta, ".output.userdoc.events").length, _count(art, "event"));
        assertEq(vm.parseJsonKeys(meta, ".output.userdoc.errors").length, _count(art, "error"));
        assertEq(_count(art, "event"), 4);
        assertEq(_count(art, "error"), 12);
    }
}
