// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterSetScript is Script {
    Counter public counter;

    function run() public {
        vm.startBroadcast();
        counter = new Counter();
        counter.setNumber(10);
        vm.stopBroadcast();

        console.log("number:", counter.number());
    }
}
