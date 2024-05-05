// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig public helperConfig;
    address TEST_WETH_USD_PRICE_FEED =
        0x90193C961A926261B756D1E5bb255e67ff9498A1;
    address TEST_WBTC_USD_PRICE_FEED =
        0xBb2180ebd78ce97360503434eD37fcf4a1Df61c3;
    address TEST_WETH = 0xA8452Ec99ce0C64f20701dB7dD3abDb607c00496;
    address TEST_WBTC = 0xDB8cFf278adCCF9E9b5da745B44E754fC4EE3C76;

    function setUp() external {
        helperConfig = new HelperConfig();
    }

    function testActiveNetworkConfig() public {
        HelperConfig.NetworkConfig memory config = helperConfig
            .getOrCreateAnvilEthConfig();
        assertEq(config.wethUsdPriceFeed, TEST_WETH_USD_PRICE_FEED);
        assertEq(config.wbtcUsdPriceFeed, TEST_WBTC_USD_PRICE_FEED);
        assertEq(config.weth, TEST_WETH);
        assertEq(config.wbtc, TEST_WBTC);
    }
}
