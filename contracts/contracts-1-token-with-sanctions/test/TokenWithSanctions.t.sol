// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithSanctions} from "../src/TokenWithSanctions.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public tokenWithSanctions;
    address public owner = makeAddr("OWNER");
    address public bannedAddress = makeAddr("BANNED_ADDRESS");
    address public recipient = makeAddr("RECIPIENT");
    string public name = "TokenWithSanctions";
    string public symbol = "TWS";
    function setUp() public {
        vm.prank(owner);
        tokenWithSanctions = new TokenWithSanctions(owner, name, symbol);
    }

    function testOnlyOwnerCanBanAddress() public {
        address bannedAddress = makeAddr("BANNED_ADDRESS");
        vm.prank(owner);
        tokenWithSanctions.banAddress(bannedAddress);
        assertTrue(tokenWithSanctions.s_bannedAddresses(bannedAddress));
        vm.expectRevert();
        tokenWithSanctions.banAddress(bannedAddress);
    }

    function testOnlyOwnerCanUnbanAddress() public {
        vm.prank(owner);
        tokenWithSanctions.banAddress(bannedAddress);
        vm.expectRevert();
        tokenWithSanctions.unbanAddress(bannedAddress);
        vm.prank(owner);
        tokenWithSanctions.unbanAddress(bannedAddress);
        assertFalse(tokenWithSanctions.s_bannedAddresses(bannedAddress));
    }

    function testBannedSenderCannotSendTokens() public {
        vm.prank(owner);
        tokenWithSanctions.banAddress(bannedAddress);
        vm.expectRevert();
        tokenWithSanctions.transfer(bannedAddress, 1);
    }

    function testBannedRecipientCannotBeTransferedTokens() public {
        vm.prank(owner);
        tokenWithSanctions.banAddress(bannedAddress);
        vm.expectRevert();
        tokenWithSanctions.transferFrom(owner, bannedAddress, 1);
    }

    function testCannotTransferMoreThan500Tokens() public {
        vm.expectRevert();
        vm.prank(owner);
        tokenWithSanctions.transfer(recipient, 501);
    }
}
