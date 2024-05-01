// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithGodMode} from "../src/TokenWithGodMode.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode public tokenWithGodMode;
    address public owner = makeAddr("OWNER");
    address public recipient = makeAddr("RECIPIENT");
    address public user = makeAddr("USER");
    string public name = "TokenWithGodMode";
    string public symbol = "TGM";
    uint256 public constant FIXED_TOKEN_SUPPLY = 500;

    function setUp() public {
        vm.prank(owner);
        tokenWithGodMode = new TokenWithGodMode(owner, name, symbol);
    }

    function testCannotTransferMoreThan500Tokens() public {
        vm.expectRevert();
        vm.prank(owner);
        tokenWithGodMode.transfer(recipient, FIXED_TOKEN_SUPPLY + 1);
    }

    function testCanGodTransferFrom() public {
        vm.prank(owner);
        tokenWithGodMode.godTransferFrom(owner, user, FIXED_TOKEN_SUPPLY);
        assertEq(tokenWithGodMode.balanceOf(user), FIXED_TOKEN_SUPPLY);
    }

    function testCannotGodTransferFromIfNotOwner() public {
        vm.expectRevert();
        vm.prank(user);
        tokenWithGodMode.godTransferFrom(owner, user, FIXED_TOKEN_SUPPLY);
    }
}
