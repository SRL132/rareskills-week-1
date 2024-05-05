// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";

contract MockV3AggregatorTest is Test {
    MockV3Aggregator public aggregator;
    function setUp() external {
        aggregator = new MockV3Aggregator(8, 1000);
    }

    function testUpdateAnswer() public {
        aggregator.updateAnswer(2000);
        assertEq(aggregator.latestAnswer(), 2000);
    }

    function testUpdateRoundData() public {
        aggregator.updateRoundData(1, 3000, 100, 100);
        assertEq(aggregator.latestRound(), 1);
        assertEq(aggregator.latestAnswer(), 3000);
        assertEq(aggregator.latestTimestamp(), 100);
    }

    function testGetRoundData() public {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = aggregator.getRoundData(1);
        assertEq(roundId, 1);
        assertEq(answer, 1000);
        assertEq(startedAt, 1);
        assertEq(updatedAt, 1);
        assertEq(answeredInRound, 1);
    }

    function testDecimals() public {
        assertEq(aggregator.decimals(), 8);
    }

    function testGetAnswer() public {
        assertEq(aggregator.getAnswer(1), 1000);
    }

    function testGetTimestamp() public {
        assertEq(aggregator.getTimestamp(1), 1);
    }

    function testDescription() public {
        assertEq(aggregator.description(), "v0.6/tests/MockV3Aggregator.sol");
    }
}
