// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";

contract DeployUntrustedEscrow {
    function run() public returns (UntrustedEscrow untrustedEscrow) {
        untrustedEscrow = new UntrustedEscrow();
    }
}
