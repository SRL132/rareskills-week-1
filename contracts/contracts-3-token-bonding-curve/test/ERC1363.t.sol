// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";
import {DeployTokenWithBondingCurve} from "../script/DeployTokenWithBondingCurve.s.sol";
import {PayableToken} from "./mocks/ERC1363.sol";

contract ERC1363 is Test {
    PayableToken public erc1363;
    address owner = makeAddr("OWNER");
    function setUp() public {
        vm.prank(owner);
        erc1363 = new PayableToken();
    }

    function testCanMint() public {
        vm.prank(owner);
        erc1363.freeMint();
        assertEq(erc1363.balanceOf(owner), 2 ether);
    }
}
