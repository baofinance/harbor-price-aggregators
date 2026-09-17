// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

/// @notice Interface for Minter contracts that manage leveraged tokens
/// @dev Minter contracts track leveraged token prices relative to underlying assets. The declaration this repo
///      needs is a single getter, so this is the minimal form of harbor's `IMinter_v3` rather than a copy of it;
///      harbor's is the definitional home, and the contract documented below is kept word for word in step with it.
// solhint-disable-next-line contract-name-capwords
interface IMinter_v3 {
    /// @notice Return the price of a leveraged token in terms of the pegged token's underlying (18 decimals).
    /// The leveraged token holds the residual: the collateral value left once every pegged token is covered.
    /// (e.g. hsfxUSD-EUR / fxSAVE)
    ///
    /// Zero is a real answer, and a common one. The pegged claim is capped at the collateral value, so the residual
    /// is exactly zero at any collateral ratio at or below 1 - an ordinary depeg, not an extreme one - and stays
    /// zero just above 1 while the residual per leveraged token is under a wei. A consumer valuing a holding from
    /// this getter values it at nothing there, which is what the holding is worth.
    ///
    /// Unavailability arrives out of band, as a revert, and that guarantee belongs to the price oracle rather than
    /// to the Minter: `latestAnswer()` hands over four numbers and no metadata, so the Minter cannot tell a stale
    /// reading from a fresh one, and a conforming oracle reverts rather than answer when it cannot price. What the
    /// Minter adds is a backstop for the one in-band value that would be a lie - a zero price or rate on a reading
    /// it consumes reverts with ZeroOraclePrice or ZeroOracleRate.
    ///
    /// So a zero here means "worth nothing", never "cannot tell", and the two must not be conflated by anything
    /// reading it.
    ///
    /// With no leveraged tokens outstanding the price is 1 ether by definition.
    /// @return nav The price of the leveraged token in terms of the underlying (18 decimals)
    function leveragedTokenPrice() external view returns (uint256 nav);
}
