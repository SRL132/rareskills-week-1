// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract CounterTest is Test {
    UntrustedEscrow public untrustedEscrow;
    ERC20Mock public erc20;
    address public owner = makeAddr("OWNER");
    address public buyer = makeAddr("BUYER");
    address public seller = makeAddr("SELLER");
    function setUp() public {
        untrustedEscrow = new UntrustedEscrow();
        vm.prank(owner);
        erc20 = new ERC20Mock();
    }

    function testCanDeposit() public {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1);
    }

    function testCanWithdraw() public {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1);
        vm.warp(block.timestamp + 3 days);
        vm.prank(seller);
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 1);
    }

    function testRevertsIfWithDrawTooSoon() public {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 1);
    }

    function testRevertsIfBalanceExceeded() public {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1);
        vm.warp(block.timestamp + 3 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 2);
    }
}
