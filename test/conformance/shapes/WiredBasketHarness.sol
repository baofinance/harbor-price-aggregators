// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";

/// @title An aggregator that prices its base in units of a basket
/// @notice The first price feed quotes the base asset in a common unit - USD - and each feed after it quotes
///         one member of the basket in the same unit. The shapes built on this differ only in how the
///         members' prices combine into one; the base is divided by that.
/// @dev Every member is installed at a different price, so a combination that reads the members is pinned by
///      what it reports: the mean, the sum, the largest member and the first member are all different numbers
///      here, where members installed at one shared price would make them all agree.
abstract contract WiredBasketHarness is WiredAggregatorHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _answerToInstallAt(uint256 index) internal pure override returns (uint256) {
        // The base keeps the default; the members take increasing multiples of the second default, which
        // keeps each one far from the base and distinct from every other member.
        return index == 0 ? PRICE_ANSWER : SECOND_PRICE_ANSWER * index;
    }

    /// @notice How many members the basket has: every price feed after the first.
    function _memberCount() internal pure returns (uint256) {
        return _priceFeeds().length - 1;
    }

    /// @notice The members' prices added together, at 18 decimals.
    function _memberSum() internal view returns (uint256 sum) {
        for (uint256 member = 1; member <= _memberCount(); member++) {
            sum += _priceAnswer(member);
        }
    }
}
