// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Market, Rate, Ratio} from "../src/Market.sol";

contract DeployMarket is Script {
    function run() external {
        address deployer = msg.sender;
        uint64 n = vm.getNonce(deployer);
        address predicted = vm.computeCreateAddress(deployer, n);
        console.log("deployer nonce", n);
        console.log("predicted", predicted);

        vm.startBroadcast(deployer);
        Market m = new Market(deployer, Rate.wrap(5e16), Ratio.wrap(80));
        vm.stopBroadcast();

        console.log("actual   ", address(m));
        require(address(m) == predicted, "address mismatch");
    }
}
