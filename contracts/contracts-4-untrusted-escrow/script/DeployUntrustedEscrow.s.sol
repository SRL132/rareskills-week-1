// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {Script} from "forge-std/Script.sol";

contract DeployUntrustedEscrow is Script {
    function run() public returns (UntrustedEscrow untrustedEscrow) {
        vm.startBroadcast();
        untrustedEscrow = new UntrustedEscrow();
        vm.stopBroadcast();
    }
}
