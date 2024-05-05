// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";
import {DeployTokenWithBondingCurve} from "../script/DeployTokenWithBondingCurve.s.sol";
import {PayableToken} from "./mocks/ERC1363.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract TokenWithBondingCurveTest is Test {
    TokenWithBondingCurve public token;
    DeployTokenWithBondingCurve public deployer;
    PayableToken public wethErc1363;
    PayableToken public wbtcErc1363;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    string public constant NAME = "TokenWithBondingCurve";
    string public constant SYMBOL = "TBC";
    address public owner = makeAddr("OWNER");
    uint256 public constant ERC_1363_INITIAL_SUPPLY = 1 ether;
    uint256 public constant TEST_MAX_PRICE = 1000;
    uint256 public constant TEST_MOCK_WBTC_VALUE = 1000;
    uint256 public constant TEST_MOCK_WETH_VALUE = 2000;
    uint256 public constant TEST_MOCK_USD_VALUE = 1_000_000_000;
    uint256 public constant TEST_MOCK_EXPECTED_TBC_BUY = 18;
    uint256 public constant TEST_MOCK_EXPECTED_MINIMUM_RETURN = 3;

    function setUp() external {
        deployer = new DeployTokenWithBondingCurve();
        (, HelperConfig helperConfig) = deployer.run();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            ,
            ,

        ) = helperConfig.activeNetworkConfig();

        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startPrank(owner);
        wethErc1363 = new PayableToken();
        wbtcErc1363 = new PayableToken();
        tokenAddresses = [address(wethErc1363), address(wbtcErc1363)];
        token = new TokenWithBondingCurve(
            NAME,
            SYMBOL,
            tokenAddresses,
            priceFeedAddresses
        );

        vm.stopPrank();
    }

    function testCanBuyWithERC1363() public {
        vm.prank(owner);
        wethErc1363.transferAndCall(
            address(token),
            3,
            abi.encode(TEST_MAX_PRICE)
        );
        assertEq(
            token.balanceOf(owner),
            TEST_MOCK_EXPECTED_TBC_BUY * TEST_MOCK_WETH_VALUE
        );
    }

    function testCanSellForERC1363() public {
        vm.startPrank(owner);
        wethErc1363.transferAndCall(
            address(token),
            3,
            abi.encode(TEST_MAX_PRICE)
        );
        token.sellFor(
            token.balanceOf(owner),
            address(wethErc1363),
            TEST_MOCK_EXPECTED_MINIMUM_RETURN
        );
        assertEq(wethErc1363.balanceOf(owner), ERC_1363_INITIAL_SUPPLY);
    }

    function testRevertsIfMaxPriceExceedsMaxPrice() public {
        vm.prank(owner);
        vm.expectRevert();
        wethErc1363.transferAndCall(address(token), 1, abi.encode(0));
    }

    function testRevertsIfTokenNotSupported() public {
        vm.prank(owner);
        vm.expectRevert();
        wethErc1363.transferAndCall(address(0), 1, abi.encode(TEST_MAX_PRICE));
    }

    function testRevertsIfAmountIsZero() public {
        vm.prank(owner);
        vm.expectRevert();
        wethErc1363.transferAndCall(
            address(token),
            0,
            abi.encode(TEST_MAX_PRICE)
        );
    }

    function testRevertsIfMinimumPriceTooHigh() public {
        vm.startPrank(owner);
        wethErc1363.transferAndCall(
            address(token),
            1,
            abi.encode(TEST_MAX_PRICE)
        );
        vm.expectRevert();
        token.sellFor(1, address(wethErc1363), 10);
    }

    function testRevertsIfDirectUserCallToOnTransferReceived() public {
        vm.prank(owner);
        vm.expectRevert();
        token.onTransferReceived(owner, owner, 1, abi.encode(TEST_MAX_PRICE));
    }

    function testRevertsIfDirectUserCallToTokensReceived() public {
        vm.prank(owner);
        vm.expectRevert();
        token.tokensReceived(owner, owner, owner, 1, "", "");
    }

    function testGetTokenPriceFeed() public view {
        assertEq(
            token.getTokenPriceFeed(address(wethErc1363)),
            priceFeedAddresses[0]
        );
        assertEq(
            token.getTokenPriceFeed(address(wbtcErc1363)),
            priceFeedAddresses[1]
        );
    }

    function testGetUsdValue() public view {
        assertEq(
            token.getUsdValue(address(wethErc1363), 1),
            TEST_MOCK_WETH_VALUE
        );
        assertEq(
            token.getUsdValue(address(wbtcErc1363), 1),
            TEST_MOCK_WBTC_VALUE
        );
    }

    function testGetTokenAddresse() public view {
        assertEq(token.getTokenAddresses(), tokenAddresses);
    }

    function testGetTokenAmountFromUsd() public view {
        assertEq(
            token.getTokenAmountFromUsd(
                address(wethErc1363),
                TEST_MOCK_USD_VALUE
            ),
            TEST_MOCK_USD_VALUE / TEST_MOCK_WETH_VALUE
        );
        assertEq(
            token.getTokenAmountFromUsd(
                address(wbtcErc1363),
                TEST_MOCK_USD_VALUE
            ),
            TEST_MOCK_USD_VALUE / TEST_MOCK_WBTC_VALUE
        );
    }
}
