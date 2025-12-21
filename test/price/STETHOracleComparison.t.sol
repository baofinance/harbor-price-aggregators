// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "src/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses, MainnetAddresses} from "../DeployedAddresses.sol";
import {OracleComparisonBase} from "./OracleComparisonBase.sol";

/// @title STETH/BTC Oracle Comparison
contract STETH_BTC_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "STETH_BTC";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.STETH_BTC);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deployDoubleFeed("StETHToBTC", MainnetAddresses.ETH_USD_FEED, MainnetAddresses.BTC_USD_FEED, 1, false);
    }
}

/// @title STETH/EUR Oracle Comparison
contract STETH_EUR_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "STETH_EUR";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.STETH_EUR);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deployDoubleFeed("StETHToEUR", MainnetAddresses.ETH_USD_FEED, MainnetAddresses.EUR_USD_FEED, 1, false);
    }
}

/// @title STETH/XAU Oracle Comparison
contract STETH_XAU_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "STETH_XAU";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.STETH_XAU);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deployDoubleFeed("StETHToXAU", MainnetAddresses.ETH_USD_FEED, MainnetAddresses.XAU_USD_FEED, 1, false);
    }
}

/// @title STETH/MCAP Oracle Comparison
contract STETH_MCAP_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "STETH_MCAP";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.STETH_MCAP);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return
            _deployDoubleFeed(
                "StETHToMCAP",
                MainnetAddresses.ETH_USD_FEED,
                MainnetAddresses.MCAP_USD_FEED,
                1e12,
                false
            );
    }
}
