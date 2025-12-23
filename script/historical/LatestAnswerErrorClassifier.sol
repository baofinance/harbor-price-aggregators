// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {IPriceOracleErrors} from "@harbor-price/interfaces/IPriceOracleErrors.sol";

library LatestAnswerErrorClassifier {
    bytes4 internal constant SELECTOR_INVALID_RATE = bytes4(keccak256("InvalidRate(uint256)"));

    function _revertSelector(bytes memory revertData) private pure returns (bytes4 selector) {
        if (revertData.length < 4) return bytes4(0);
        assembly {
            selector := mload(add(revertData, 32))
        }
    }

    function _selectorToString(bytes4 selector) private pure returns (string memory) {
        if (selector == IPriceOracleErrors.InvalidUnderlyingPrice.selector) return "INVALID_UNDERLYING_PRICE";
        if (selector == IPriceOracleErrors.StaleUnderlyingPrice.selector) return "STALE_UNDERLYING_PRICE";
        if (selector == IPriceOracleErrors.UnderlyingPriceDeviation.selector) return "UNDERLYING_PRICE_DEVIATION";
        if (selector == SELECTOR_INVALID_RATE) return "INVALID_RATE";
        if (selector == bytes4(0x08c379a0)) return "ERROR_STRING";
        if (selector == bytes4(0x4e487b71)) return "PANIC";
        return "UNKNOWN";
    }

    function _isKnownConstraint(bytes4 selector) private pure returns (bool) {
        return
            (selector == IPriceOracleErrors.InvalidUnderlyingPrice.selector) ||
            (selector == IPriceOracleErrors.StaleUnderlyingPrice.selector) ||
            (selector == IPriceOracleErrors.UnderlyingPriceDeviation.selector) ||
            (selector == SELECTOR_INVALID_RATE);
    }

    /// @notice Attempts latestAnswer() via staticcall and classifies failures for CSV output.
    /// @dev Semantics preserved from the historical dump harnesses:
    ///      - OK + decoded values => (stop=false, hasData=true, error="OK")
    ///      - Empty returndata => (stop=true, hasData=false, error="NO_CODE")
    ///      - Revert with known-constraint selector => (stop=true, hasData=false, error=<label>)
    ///      - Any other revert => (stop=true, hasData=false, error="NO_CODE")
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
            bytes4 selector = _revertSelector(ret);
            if (_isKnownConstraint(selector)) {
                return (true, false, 0, 0, 0, 0, _selectorToString(selector));
            }
            return (true, false, 0, 0, 0, 0, "NO_CODE");
        }

        if (ret.length == 0) {
            return (true, false, 0, 0, 0, 0, "NO_CODE");
        }

        (minPrice, maxPrice, minRate, maxRate) = abi.decode(ret, (uint256, uint256, uint256, uint256));
        return (false, true, minPrice, maxPrice, minRate, maxRate, "OK");
    }
}
