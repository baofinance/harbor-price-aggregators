// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Interface for Harbor Triple Feed and Rate Aggregator V2
/// @notice Oracle for triple feed conversions (e.g., stETH to meme coins via stETH→ETH→USD/meme)
interface IHarborTripleFeedAndRateAggregator {
    enum RateSource {
        WSTETH,
        FXSAVE,
        SUSDE_CHAINLINK,
        WSTETH_CHAINLINK
    }

    function oracleName() external view returns (string memory);
    function rateSource() external view returns (RateSource);
    function firstFeed() external view returns (address);
    function secondFeed() external view returns (address);
    function thirdFeed() external view returns (address);
    function priceDivisor() external view returns (uint256);
    function invertPrice() external view returns (bool);
    function getPrice() external view returns (uint256);
    function latestAnswer() external view returns (uint256, uint256, uint256, uint256);
}
