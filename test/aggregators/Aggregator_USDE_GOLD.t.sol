// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedUSDEAggregatorTestBase} from "@harbor-price-test/aggregators/DoubleFeedUSDEAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_USDE_XAU} from "@harbor-price/aggregators/mainnet/Aggregator_USDE_XAU.sol";

/// @notice Tests for USDE/GOLD (uses Aggregator_USDE_XAU formula, quote label GOLD in mainnet).
contract Aggregator_USDE_GOLD_Test is DoubleFeedUSDEAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return "Aggregator_USDE_GOLD";
    }

    /// @dev Formula contract returns quoteName "XAU"; override so assertion passes.
    function _expectedQuoteName() internal pure override returns (string memory) {
        return "XAU";
    }

    function _createAggregator(
        address susde,
        address firstFeed,
        uint256 firstHeartbeat,
        address secondFeed,
        uint256 secondHeartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return
            IHarborPriceAggregatorV3(
                address(
                    new Aggregator_USDE_XAU(
                        susde,
                        firstFeed,
                        firstHeartbeat,
                        secondFeed,
                        secondHeartbeat,
                        divisor,
                        invert
                    )
                )
            );
    }

    function _createWithZeroSusde() internal override {
        new Aggregator_USDE_XAU(
            address(0),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroFirstFeed() internal override {
        new Aggregator_USDE_XAU(
            address(mockSUSDe),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_USDE_XAU(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_USDE_XAU(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
