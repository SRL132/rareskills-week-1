// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";
import {PayableToken} from "./mocks/ERC1363.sol";

contract TokenWithBondingCurveTest is Test {
    TokenWithBondingCurve public token;
    PayableToken public erc1363;
    string public constant NAME = "TokenWithBondingCurve";
    string public constant SYMBOL = "TBC";
    address[] public tokenAddresses;
    uint256[] public prices;
    address public owner = makeAddr("OWNER");
    uint256 public constant ERC_1363_INITIAL_SUPPLY = 1 ether;
    uint256 public constant TEST_MAX_PRICE = 1000;

    function setUp() public {
        tokenAddresses = new address[](2);
        tokenAddresses[0] = address(0x1);
        tokenAddresses[1] = address(0x2);
        prices = new uint256[](2);
        prices[0] = 1;
        prices[1] = 2;
        vm.prank(owner);
        erc1363 = new PayableToken();
        tokenAddresses[0] = address(erc1363);
        token = new TokenWithBondingCurve(NAME, SYMBOL, tokenAddresses, prices);
    }

    function testCanBuyWithERC1363() public {
        vm.prank(owner);
        erc1363.transferAndCall(address(token), 3, abi.encode(TEST_MAX_PRICE));
        assertEq(token.balanceOf(owner), 18);
    }
    //TODO: FIX SALE LOGIC
    function testCanSellForERC1363() public {
        vm.startPrank(owner);
        erc1363.transferAndCall(address(token), 3, abi.encode(TEST_MAX_PRICE));
        token.sellFor(token.balanceOf(owner), address(erc1363), 3);
        assertEq(erc1363.balanceOf(owner), ERC_1363_INITIAL_SUPPLY);
    }

    function testRevertsIfMaxPriceExceedsMaxPrice() public {
        vm.prank(owner);
        vm.expectRevert();
        erc1363.transferAndCall(address(token), 1, abi.encode(0));
    }

    function testRevertsIfTokenNotSupported() public {
        vm.prank(owner);
        vm.expectRevert();
        erc1363.transferAndCall(address(0), 1, abi.encode(TEST_MAX_PRICE));
    }

    function testRevertsIfAmountIsZero() public {
        vm.prank(owner);
        vm.expectRevert();
        erc1363.transferAndCall(address(token), 0, abi.encode(TEST_MAX_PRICE));
    }

    function testRevertsIfMinimumPriceTooHigh() public {
        vm.startPrank(owner);
        erc1363.transferAndCall(address(token), 1, abi.encode(TEST_MAX_PRICE));
        vm.expectRevert();
        token.sellFor(1, address(erc1363), 10);
    }

    function testGetTokenAddresses() public {
        assertEq(token.getTokenAddresses(), tokenAddresses);
    }
}
