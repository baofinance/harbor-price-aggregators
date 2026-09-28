// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "@bao/interfaces/IWrappedPriceOracle.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";

library LatestAnswerErrorClassifier {
    function _revertSelector(bytes memory revertData) private pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(revertData, 32))
        }
    }

    /// @notice Label for the reason a `latestAnswer()` call reverted.
    /// @dev One list covering every selector, so the label and the decision to use it cannot drift apart. The named
    ///      cases come from `IPriceOracleErrors`, which the rate, price, and feed libraries revert with, so adding an
    ///      error there is the only edit needed for it to be classified here.
    /// @param selector The first four bytes of the revert data
    /// @return label The reason, or "UNKNOWN_ERROR" for a selector this library does not recognise
    function _errorLabel(bytes4 selector) private pure returns (string memory label) {
        // reverts an oracle is written to throw while pricing
        if (selector == IPriceOracleErrors.StaleFeedData.selector) return "STALE_FEED_DATA";
        if (selector == IPriceOracleErrors.FeedNeverUpdated.selector) return "FEED_NEVER_UPDATED";
        if (selector == IPriceOracleErrors.NegativePrice.selector) return "NEGATIVE_PRICE";
        if (selector == IPriceOracleErrors.ZeroPrice.selector) return "ZERO_PRICE";
        if (selector == IPriceOracleErrors.InvalidRate.selector) return "INVALID_RATE";
        if (selector == IPriceOracleErrors.StaleRateSource.selector) return "STALE_RATE_SOURCE";
        if (selector == IPriceOracleErrors.EmptyFeeds.selector) return "EMPTY_FEEDS";
        if (selector == IPriceOracleErrors.InvalidFeedCount.selector) return "INVALID_FEED_COUNT";
        // the two the language itself produces
        if (selector == bytes4(0x08c379a0)) return "ERROR_STRING";
        if (selector == bytes4(0x4e487b71)) return "PANIC";
        return "UNKNOWN_ERROR";
    }

    /// @notice Attempts latestAnswer() via staticcall and classifies the outcome for CSV output.
    /// @dev Every outcome gets its own label, so a failure is never reported as something it is not:
    ///      - decoded values                    => (stop=false, hasData=true,  error="OK")
    ///      - success with no returndata        => (stop=true,  hasData=false, error="NO_CODE")
    ///      - revert carrying no selector       => (stop=true,  hasData=false, error="REVERT_NO_DATA")
    ///      - revert with a selector            => (stop=true,  hasData=false, error=<label from `_errorLabel`>)
    ///      An unrecognised selector reads "UNKNOWN_ERROR" rather than "NO_CODE": the call reached code and that
    ///      code rejected the read, which is a different fact about the oracle than there being nothing deployed.
    /// @param oracle The oracle to read
    function tryLatestAnswer(
        address oracle
    )
        internal
        view
        returns (
            bool stop,
            bool hasData,
            uint256 minPrice,
            uint256 maxPrice,
            uint256 minRate,
            uint256 maxRate,
            string memory error
        )
    {
        bytes memory callData = abi.encodeWithSelector(IWrappedPriceOracle.latestAnswer.selector);
        (bool ok, bytes memory ret) = oracle.staticcall(callData);

        if (!ok) {
            if (ret.length < 4) {
                return (true, false, 0, 0, 0, 0, "REVERT_NO_DATA");
            }
            return (true, false, 0, 0, 0, 0, _errorLabel(_revertSelector(ret)));
        }

        // a staticcall to an address holding no code succeeds and returns nothing
        if (ret.length == 0) {
            return (true, false, 0, 0, 0, 0, "NO_CODE");
        }

        (minPrice, maxPrice, minRate, maxRate) = abi.decode(ret, (uint256, uint256, uint256, uint256));
        return (false, true, minPrice, maxPrice, minRate, maxRate, "OK");
    }
}
