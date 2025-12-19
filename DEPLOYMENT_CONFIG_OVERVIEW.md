# Harbor Oracle V2 Deployment Configuration Overview

## Implementation Contracts

### 1. HarborSingleFeedAndRateAggregator_v2

**Constructor Parameters (a, b, c, d):**
```solidity
constructor(
    address wsteth_,           // a: wstETH contract
    address fxsave_,           // b: fxSAVE contract  
    address susdeUsdeFeed_,    // c: sUSDE/USDE Chainlink feed (0x0 on mainnet)
    address wstethStethFeed_   // d: wstETH/stETH Chainlink feed (0x0 on mainnet)
)
```

**Constructor Values:**
- `a` (wstETH): `0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0`
- `b` (fxSAVE): `0x7743e50f534a7f9f1791dde7dcd89f7783eefc39`
- `c` (sUSDE/USDE Feed): `0x0000000000000000000000000000000000000000`
- `d` (wstETH/stETH Feed): `0x0000000000000000000000000000000000000000`

**Implementation Address:** `0x3860ae3Df9Fa0Bb56fbdD1c4A6e30bEAa497E0E1`

---

### 2. HarborDoubleFeedAndRateAggregator_v2

**Constructor Parameters (a, b, c, d):**
```solidity
constructor(
    address wsteth_,           // a: wstETH contract
    address fxsave_,           // b: fxSAVE contract
    address susdeUsdeFeed_,    // c: sUSDE/USDE Chainlink feed (0x0 on mainnet)
    address wstethStethFeed_   // d: wstETH/stETH Chainlink feed (0x0 on mainnet)
)
```

**Constructor Values:**
- `a` (wstETH): `0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0`
- `b` (fxSAVE): `0x7743e50f534a7f9f1791dde7dcd89f7783eefc39`
- `c` (sUSDE/USDE Feed): `0x0000000000000000000000000000000000000000`
- `d` (wstETH/stETH Feed): `0x0000000000000000000000000000000000000000`

**Implementation Address:** `0xaC669B64c85F89150f9C0a379dF731E79218C3C5`

---

## Parameters Overview

### Single Feed V2 Initialize Parameters

**Function Signature:**
```solidity
initialize(
    address owner_,           // d: Owner address
    string memory oracleName_, // e: Oracle name/description
    RateSource rateSource_,   // f: Rate source (0 = WSTETH, 1 = FXSAVE)
    address firstFeed_,       // g: First feed address (e.g., ETH/USD, BTC/USD)
    uint256 priceDivisor_,    // h: Divisor for price normalization (1 or 1e12 for MCAP)
    uint64 firstFeedMaxAge_,  // i: Max age for first feed (seconds, typically 604800)
    uint256 firstFeedMaxDev_, // j: Max deviation for first feed (1e18, typically 50000000000000000)
    bool invertPrice_         // k: Whether to invert the price (true for fxUSD, false for stETH)
)
```

**Parameter Descriptions:**
- `d` (owner): Contract owner address with upgrade permissions
- `e` (oracleName): Human-readable name for the oracle (e.g., "FxUSDToETH")
- `f` (rateSource): `0` = WSTETH, `1` = FXSAVE
- `g` (firstFeed): Chainlink feed address for the price source
- `h` (priceDivisor): Normalization divisor (`1` for most, `1000000000000` for MCAP)
- `i` (firstFeedMaxAge): Maximum age of feed data in seconds (default: `604800` = 7 days)
- `j` (firstFeedMaxDev): Maximum deviation allowed (default: `50000000000000000` = 5%)
- `k` (invertPrice): `true` to invert price (USD/pegged), `false` for direct price

---

### Double Feed V2 Initialize Parameters

**Function Signature:**
```solidity
initialize(
    address owner_,           // d: Owner address
    string memory oracleName_, // e: Oracle name/description
    RateSource rateSource_,   // f: Rate source (0 = WSTETH, 1 = FXSAVE)
    address firstFeed_,       // g: First feed address (e.g., ETH/USD)
    address secondFeed_,      // h: Second feed address (e.g., BTC/USD, EUR/USD)
    uint256 priceDivisor_,    // i: Divisor for price normalization (1 or 1e12 for MCAP)
    uint64 firstFeedMaxAge_,  // j: Max age for first feed (seconds, typically 604800)
    uint256 firstFeedMaxDev_, // k: Max deviation for first feed (1e18, typically 50000000000000000)
    uint64 secondFeedMaxAge_, // l: Max age for second feed (seconds, typically 604800)
    uint256 secondFeedMaxDev_,// m: Max deviation for second feed (1e18, typically 50000000000000000)
    bool invertPrice_         // n: Whether to invert the price conversion (false for stETH)
)
```

**Parameter Descriptions:**
- `d` (owner): Contract owner address with upgrade permissions
- `e` (oracleName): Human-readable name for the oracle (e.g., "StETHToBTC")
- `f` (rateSource): `0` = WSTETH, `1` = FXSAVE
- `g` (firstFeed): First Chainlink feed address (e.g., ETH/USD)
- `h` (secondFeed): Second Chainlink feed address (e.g., BTC/USD, EUR/USD, XAU/USD, MCAP/USD)
- `i` (priceDivisor): Normalization divisor (`1` for most, `1000000000000` for MCAP)
- `j` (firstFeedMaxAge): Maximum age of first feed data in seconds (default: `604800` = 7 days)
- `k` (firstFeedMaxDev): Maximum deviation allowed for first feed (default: `50000000000000000` = 5%)
- `l` (secondFeedMaxAge): Maximum age of second feed data in seconds (default: `604800` = 7 days)
- `m` (secondFeedMaxDev): Maximum deviation allowed for second feed (default: `50000000000000000` = 5%)
- `n` (invertPrice): `true` to invert conversion, `false` for direct conversion (default: `false`)

---

## Oracle Configurations

### Common Configuration Values
- **OWNER**: `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e` (default, can be overridden)
- **MAX_AGE**: `604800` (7 days in seconds)
- **MAX_DEV**: `50000000000000000` (5% = 0.05 * 1e18)

### Chainlink Feed Addresses
- **ETH/USD**: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`
- **BTC/USD**: `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c`
- **EUR/USD**: `0xb49f677943BC038e9857d61E7d053CaA2C1734C1`
- **XAU/USD**: `0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6`
- **MCAP/USD**: `0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2`

---

## Single Feed Oracles (fxUSD → X)

All use: `HarborSingleFeedAndRateAggregator_v2`

### 1. fxUSD → ETH
**Proxy Address:** `0x71437C90F1E0785dd691FD02f7bE0B90cd14c097`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"FxUSDToETH"`
- `f` (rateSource): `1` (FXSAVE)
- `g` (firstFeed): `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (ETH/USD)
- `h` (priceDivisor): `1`
- `i` (firstFeedMaxAge): `604800`
- `j` (firstFeedMaxDev): `50000000000000000`
- `k` (invertPrice): `true`

---

### 2. fxUSD → BTC
**Proxy Address:** `0x8F76a260c5D21586aFfF18f880FFC808D0524A73`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"FxUSDToBTC"`
- `f` (rateSource): `1` (FXSAVE)
- `g` (firstFeed): `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c` (BTC/USD)
- `h` (priceDivisor): `1`
- `i` (firstFeedMaxAge): `604800`
- `j` (firstFeedMaxDev): `50000000000000000`
- `k` (invertPrice): `true`

---

### 3. fxUSD → EUR
**Proxy Address:** `0x6bEb1a1189Ac68a2a26b5210e5ccfB9e8a3E408E`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"FxUSDToEUR"`
- `f` (rateSource): `1` (FXSAVE)
- `g` (firstFeed): `0xb49f677943BC038e9857d61E7d053CaA2C1734C1` (EUR/USD)
- `h` (priceDivisor): `1`
- `i` (firstFeedMaxAge): `604800`
- `j` (firstFeedMaxDev): `50000000000000000`
- `k` (invertPrice): `true`

---

### 4. fxUSD → XAU
**Proxy Address:** `0x7DAe17B00DCd5C37D4992a17C3Cf8f5E15d2BbAf`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"FxUSDToXAU"`
- `f` (rateSource): `1` (FXSAVE)
- `g` (firstFeed): `0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6` (XAU/USD)
- `h` (priceDivisor): `1`
- `i` (firstFeedMaxAge): `604800`
- `j` (firstFeedMaxDev): `50000000000000000`
- `k` (invertPrice): `true`

---

### 5. fxUSD → MCAP
**Proxy Address:** `0xdF21f32c522B2A871D5a6AD303638051b51C378F`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"FxUSDToMCAP"`
- `f` (rateSource): `1` (FXSAVE)
- `g` (firstFeed): `0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2` (MCAP/USD)
- `h` (priceDivisor): `1000000000000` (1e12)
- `i` (firstFeedMaxAge): `604800`
- `j` (firstFeedMaxDev): `50000000000000000`
- `k` (invertPrice): `true`

**Note:** MCAP feed has 8 decimals and is normalized to 18 decimals by PriceOracle. The divisor (1e12) is applied before inversion to get the correct USD/MCAP price.

---

## Double Feed Oracles (stETH → X)

All use: `HarborDoubleFeedAndRateAggregator_v2`

### 1. stETH → BTC
**Proxy Address:** `0xd8789EB86Dd57f9Fe10D0D8dFa803286b389b1BC`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"StETHToBTC"`
- `f` (rateSource): `0` (WSTETH)
- `g` (firstFeed): `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (ETH/USD)
- `h` (secondFeed): `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c` (BTC/USD)
- `i` (priceDivisor): `1`
- `j` (firstFeedMaxAge): `604800`
- `k` (firstFeedMaxDev): `50000000000000000`
- `l` (secondFeedMaxAge): `604800`
- `m` (secondFeedMaxDev): `50000000000000000`
- `n` (invertPrice): `false`

---

### 2. stETH → EUR
**Proxy Address:** `0x76453e0eaF1a54c0e939b2E66D9825808cBd411b`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"StETHToEUR"`
- `f` (rateSource): `0` (WSTETH)
- `g` (firstFeed): `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (ETH/USD)
- `h` (secondFeed): `0xb49f677943BC038e9857d61E7d053CaA2C1734C1` (EUR/USD)
- `i` (priceDivisor): `1`
- `j` (firstFeedMaxAge): `604800`
- `k` (firstFeedMaxDev): `50000000000000000`
- `l` (secondFeedMaxAge): `604800`
- `m` (secondFeedMaxDev): `50000000000000000`
- `n` (invertPrice): `false`

---

### 3. stETH → XAU
**Proxy Address:** `0x8919713b1620BCA8bE6e774fFFA735b0051ff6cB`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"StETHToXAU"`
- `f` (rateSource): `0` (WSTETH)
- `g` (firstFeed): `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (ETH/USD)
- `h` (secondFeed): `0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6` (XAU/USD)
- `i` (priceDivisor): `1`
- `j` (firstFeedMaxAge): `604800`
- `k` (firstFeedMaxDev): `50000000000000000`
- `l` (secondFeedMaxAge): `604800`
- `m` (secondFeedMaxDev): `50000000000000000`
- `n` (invertPrice): `false`

---

### 4. stETH → MCAP
**Proxy Address:** `0x06CD5701d9FfD9F7AaDFE28C57B481e99D2ba3ad`

**Initialize Parameters:**
- `d` (owner): `0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e`
- `e` (oracleName): `"StETHToMCAP"`
- `f` (rateSource): `0` (WSTETH)
- `g` (firstFeed): `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (ETH/USD)
- `h` (secondFeed): `0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2` (MCAP/USD)
- `i` (priceDivisor): `1000000000000` (1e12)
- `j` (firstFeedMaxAge): `604800`
- `k` (firstFeedMaxDev): `50000000000000000`
- `l` (secondFeedMaxAge): `604800`
- `m` (secondFeedMaxDev): `50000000000000000`
- `n` (invertPrice): `false`

---

## Summary Table

| Oracle | Contract Type | Rate Source | First Feed | Second Feed | Price Divisor | Invert Price | Proxy Address |
|--------|--------------|-------------|------------|-------------|---------------|--------------|---------------|
| fxUSD→ETH | Single | FXSAVE (1) | ETH/USD | - | 1 | true | `0x71437C90F1E0785dd691FD02f7bE0B90cd14c097` |
| fxUSD→BTC | Single | FXSAVE (1) | BTC/USD | - | 1 | true | `0x8F76a260c5D21586aFfF18f880FFC808D0524A73` |
| fxUSD→EUR | Single | FXSAVE (1) | EUR/USD | - | 1 | true | `0x6bEb1a1189Ac68a2a26b5210e5ccfB9e8a3E408E` |
| fxUSD→XAU | Single | FXSAVE (1) | XAU/USD | - | 1 | true | `0x7DAe17B00DCd5C37D4992a17C3Cf8f5E15d2BbAf` |
| fxUSD→MCAP | Single | FXSAVE (1) | MCAP/USD | - | 1e12 | true | `0xdF21f32c522B2A871D5a6AD303638051b51C378F` |
| stETH→BTC | Double | WSTETH (0) | ETH/USD | BTC/USD | 1 | false | `0xd8789EB86Dd57f9Fe10D0D8dFa803286b389b1BC` |
| stETH→EUR | Double | WSTETH (0) | ETH/USD | EUR/USD | 1 | false | `0x76453e0eaF1a54c0e939b2E66D9825808cBd411b` |
| stETH→XAU | Double | WSTETH (0) | ETH/USD | XAU/USD | 1 | false | `0x8919713b1620BCA8bE6e774fFFA735b0051ff6cB` |
| stETH→MCAP | Double | WSTETH (0) | ETH/USD | MCAP/USD | 1e12 | false | `0x06CD5701d9FfD9F7AaDFE28C57B481e99D2ba3ad` |

---

## Price Calculation Logic

### Single Feed V2 (fxUSD oracles)

**When `invertPrice=false`:**
```
price = firstFeedPrice / priceDivisor
```

**When `invertPrice=true`:**
```
price = (1e18 * priceDivisor * 1e18) / firstFeedPrice
```
This inverts the price and applies the divisor before inversion (important for MCAP feeds).

**Example (fxUSD→MCAP):**
- MCAP feed (8 decimals): `3031373598836.47400000`
- Normalized to 18 decimals: `3031373598836474000000000000000`
- With divisor 1e12 and inversion: `(1e18 * 1e12 * 1e18) / 3031373598836474000000000000000 = 0.3298`
- Result: `1 fxUSD = 0.3298 MCAP`

### Double Feed V2 (stETH oracles)

**When `invertPrice=false`:**
```
price = (firstFeedPrice * priceDivisor) / secondFeedPrice
```

**When `invertPrice=true`:**
```
price = (secondFeedPrice * 1e18) / (firstFeedPrice * priceDivisor)
```

---

## Notes

1. **Rate Sources:**
   - `0` = WSTETH (used for stETH oracles)
   - `1` = FXSAVE (used for fxUSD oracles)

2. **Price Divisor:**
   - Most oracles use `1`
   - MCAP oracles use `1000000000000` (1e12) to normalize the large market cap value

3. **Invert Price:**
   - **fxUSD oracles**: `invertPrice=true` to return USD-to-pegged prices (e.g., USD/ETH instead of ETH/USD)
   - **stETH oracles**: `invertPrice=false` (direct conversion from first feed to second feed)

4. **Constraints:**
   - All feeds use the same constraints: 7 days max age, 5% max deviation

5. **Price Normalization:**
   - All feed prices are normalized to 18 decimals by the `PriceOracle_v1` library
   - Feeds with 8 decimals are multiplied by 1e10 to reach 18 decimals
   - The `priceDivisor` is then applied for further normalization (e.g., MCAP uses 1e12)

6. **MCAP Price Fix:**
   - The Single Feed V2 implementation includes a fix where the `priceDivisor` is applied before inversion when `invertPrice=true`
   - This ensures correct pricing for MCAP feeds: `(1e18 * priceDivisor * 1e18) / firstFeedPrice`

---

## Deployment State

**Last Updated:** 2025-12-19T13:52:43Z  
**State File:** `deployment-state-v2.json`

All 9 proxy contracts have been deployed and initialized.
