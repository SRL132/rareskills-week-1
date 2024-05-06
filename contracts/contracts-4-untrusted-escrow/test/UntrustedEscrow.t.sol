// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {MyERC20} from "../src/mocks/MyERC20.sol";
import {DeployUntrustedEscrow} from "../script/DeployUntrustedEscrow.s.sol";
import {MaliciousERC20} from "../src/mocks/MaliciousERC20.sol";

contract CounterTest is Test {
    DeployUntrustedEscrow public deployUntrustedEscrow;
    UntrustedEscrow public untrustedEscrow;
    MyERC20 public erc20;
    MaliciousERC20 public maliciousErc20;
    address public owner = makeAddr("OWNER");
    address public buyer = makeAddr("BUYER");
    address public seller = makeAddr("SELLER");
    address public hacker = makeAddr("HACKER");
    function setUp() public {
        deployUntrustedEscrow = new DeployUntrustedEscrow();
        untrustedEscrow = deployUntrustedEscrow.run();
        vm.prank(owner);
        erc20 = new MyERC20(owner, "test", "TST");
        vm.prank(hacker);
        maliciousErc20 = new MaliciousERC20(hacker, "malicious", "MAL");
    }
    modifier hasApproved() {
        vm.prank(owner);
        erc20.mint(buyer, 1);
        vm.prank(buyer);
        erc20.approve(address(untrustedEscrow), 1);
        _;
    }
    function testCanDeposit() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
    }

    function testCanWithdraw() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.warp(block.timestamp + 3 days);
        vm.deal(seller, 20);
        vm.prank(seller);
        untrustedEscrow.sellerWithdraw{value: 20}(buyer, address(erc20), 1);
        assertEq(erc20.balanceOf(address(untrustedEscrow)), 0);
        assertEq(erc20.balanceOf(seller), 1);
    }

    function testRevertsIfWithDrawWithTooLittleMoney() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.warp(block.timestamp + 3 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 2);
    }

    function testRevertsIfWithDrawTooSoon() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 1);
    }

    function testRevertsIfBalanceExceeded() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.warp(block.timestamp + 3 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 2);
    }

    function testRevertsIfTransferFails() public {
        vm.prank(buyer);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
    }

    function testRevertsIfDepositInvalidAddress() public hasApproved {
        vm.prank(buyer);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(0), 1, 20);
    }

    function testRevertsIfDepositZeroAmount() public hasApproved {
        vm.prank(buyer);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(erc20), 0, 20);
    }

    function testRevertsIfUpdateDepositTooSoon() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.prank(buyer);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
    }

    function testReverWithdrawZeroAmount() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.warp(block.timestamp + 4 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 0);
    }

    function testRevertsIfWithDrawWithNotEnoughMoney() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.warp(block.timestamp + 3 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(erc20), 1);
    }

    function testMaliciousERC20() public hasApproved {
        vm.startPrank(hacker);
        maliciousErc20.mint(hacker, 1);
        maliciousErc20.approve(address(untrustedEscrow), 1);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(maliciousErc20), 1, 20);
        vm.stopPrank();
    }
}
