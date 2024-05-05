// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";
import {PayableToken} from "../test/mocks/ERC1363.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployTokenWithBondingCurve is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    function run() public returns (TokenWithBondingCurve, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startBroadcast();
        TokenWithBondingCurve tokenWithBondingCurve = new TokenWithBondingCurve(
            "TokenWithBondingCurve",
            "TBC",
            tokenAddresses,
            priceFeedAddresses
        );
        vm.stopBroadcast();
        return (tokenWithBondingCurve, helperConfig);
    }
}
