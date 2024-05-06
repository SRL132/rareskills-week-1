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

    // This is a fake balance of the malicious ERC20 token to try to trick receiving contract into believing they have more than they actually do
    uint256 public constant FAKE_BALANCE_OF = 5;

    function setUp() public {
        deployUntrustedEscrow = new DeployUntrustedEscrow();
        untrustedEscrow = deployUntrustedEscrow.run(owner);
        vm.startPrank(owner);
        erc20 = new MyERC20(owner, "test", "TST");
        untrustedEscrow.approveToken(address(erc20));
        vm.stopPrank();
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

    function testMaliciousERC20CannotHackArbitrarely() public hasApproved {
        vm.startPrank(hacker);
        maliciousErc20.mint(hacker, 1);
        maliciousErc20.approve(address(untrustedEscrow), 1);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(address(maliciousErc20), 1, 20);
        vm.stopPrank();
    }

    function onlyOwnerCanApproveRevokeTokens() public {
        vm.startPrank(owner);
        untrustedEscrow.approveToken(address(erc20));
        untrustedEscrow.revokeToken(address(erc20));
        untrustedEscrow.approveToken(address(erc20));
        vm.stopPrank();
        assert(untrustedEscrow.s_approvedTokens(address(erc20)));
        untrustedEscrow.revokeToken(address(erc20));
        assert(!untrustedEscrow.s_approvedTokens(address(erc20)));
        vm.startPrank(hacker);
        vm.expectRevert();
        untrustedEscrow.revokeToken(address(erc20));
        vm.expectRevert();
        untrustedEscrow.approveToken(address(maliciousErc20));
    }

    function testRevertsIfDepositUnapprovedToken() public hasApproved {
        vm.prank(hacker);
        vm.expectRevert();
        untrustedEscrow.buyerDeposit(
            address(maliciousErc20),
            1,
            FAKE_BALANCE_OF
        );
    }

    function testRevertsIfWithdrawUnapprovedToken() public hasApproved {
        vm.prank(buyer);
        untrustedEscrow.buyerDeposit(address(erc20), 1, 20);
        vm.prank(owner);
        untrustedEscrow.revokeToken(address(erc20));
        vm.warp(block.timestamp + 4 days);
        vm.prank(seller);
        vm.expectRevert();
        untrustedEscrow.sellerWithdraw(buyer, address(maliciousErc20), 1);
    }
}
