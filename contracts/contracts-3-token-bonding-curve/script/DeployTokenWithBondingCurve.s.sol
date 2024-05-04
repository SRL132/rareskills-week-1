pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {TokenWithBondingCurve} from "../src/TokenWithBondingCurve.sol";
import {PayableToken} from "../test/mocks/ERC1363.sol";

contract DeployTokenWithBondingCurve is Script {
    function run() public returns (TokenWithBondingCurve, PayableToken) {
        address[] memory tokenAddresses = new address[](2);
        PayableToken erc1363 = new PayableToken();
        tokenAddresses[0] = address(erc1363);
        tokenAddresses[1] = address(0x2);
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1;
        prices[1] = 2;
        TokenWithBondingCurve tokenWithBondingCurve = new TokenWithBondingCurve(
            "TokenWithBondingCurve",
            "TBC",
            tokenAddresses,
            prices
        );

        return (tokenWithBondingCurve, erc1363);
    }
}
