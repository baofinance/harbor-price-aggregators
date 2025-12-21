// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "src/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses, MainnetAddresses} from "../DeployedAddresses.sol";
import {OracleComparisonBase} from "./OracleComparisonBase.sol";

/// @title FXUSD/ETH Oracle Comparison
contract FXUSD_ETH_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_ETH";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_ETH);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToETH", MainnetAddresses.ETH_USD_FEED, 1, true);
    }
}

/// @title FXUSD/ETH Oracle Comparison
contract FXUSD_ETH_Comparison_v3_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_ETH";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_ETH);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToETH", MainnetAddresses.ETH_USD_FEED, 1, true);
    }
}

/// @title FXUSD/BTC Oracle Comparison
contract FXUSD_BTC_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_BTC";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_BTC);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToBTC", MainnetAddresses.BTC_USD_FEED, 1, true);
    }
}

/// @title FXUSD/EUR Oracle Comparison
contract FXUSD_EUR_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_EUR";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_EUR);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToEUR", MainnetAddresses.EUR_USD_FEED, 1, true);
    }
}

/// @title FXUSD/XAU Oracle Comparison
contract FXUSD_XAU_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_XAU";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_XAU);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToXAU", MainnetAddresses.XAU_USD_FEED, 1, true);
    }
}

/// @title FXUSD/MCAP Oracle Comparison
contract FXUSD_MCAP_Comparison_ is OracleComparisonBase {
    function _oracleName() internal pure override returns (string memory) {
        return "FXUSD_MCAP";
    }

    function _deployBase() internal virtual override returns (IWrappedPriceOracle) {
        return IWrappedPriceOracle(DeployedAddresses.FXUSD_MCAP);
    }

    function _deployCandidate() internal virtual override returns (IWrappedPriceOracle) {
        return _deploySingleFeed("FxUSDToMCAP", MainnetAddresses.MCAP_USD_FEED, 1e12, true);
    }
}
