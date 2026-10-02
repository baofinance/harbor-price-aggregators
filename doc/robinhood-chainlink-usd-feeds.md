# Robinhood tokenized equity — Chainlink USD feeds

Standard (non-SVR) AggregatorV3 proxies. Quote is USD in every case. Market hours: `us_equities_24/5`.

| Asset | Counter | Standard proxy |
| ----- | ------- | -------------- |
| AAPL | USD | `0x6B22A786bAa607d76728168703a39Ea9C99f2cD0` |
| AMD | USD | `0x943A29E7ae51A4798823ca9eEd2ed533B2A22C72` |
| AMZN | USD | `0xD5a1508ceD74c084eBf3cBe853e2C968fB2a651C` |
| ASML | USD | `0xB4106147E8cce40b7d46124090d373A71b70f87D` |
| BABA | USD | `0x62Cc8F9b5f56a33c9C8A60c8B92779f523c4E984` |
| CLSK | USD | `0x810c12D3a554Bc47fd39597Fe3b3AAC4941F50eF` |
| COIN | USD | `0xA3a468A452940B7D6b69991207B508c609a98Ef2` |
| CRCL | USD | `0x6652eDf64bA3731C4F2D3ce821A0Fb1f1f6b482a` |
| CRWV | USD | `0xe1b3aABCAFAd1c94708dc1367dcfF8Aa4407487C` |
| DELL | USD | `0x1C6c8cADBe02E19129c39dDB92281cE4c0bf206b` |
| EWY | USD | `0xEFdf54610B62A7753Ec30bDc380847c12D32e1D1` |
| GME | USD | `0x27C71df6A64fB476468EdF256CF72c038baB5B67` |
| GOOGL | USD | `0xF6f373a037c30F0e5010d854385cA89185AE638b` |
| INTC | USD | `0x3f390C5C24628Ac7C489515402235FeAD71D1913` |
| IONQ | USD | `0x22EfeC4919baf55F360E0EDee4AbEB26DE4971eb` |
| META | USD | `0x7C38C00C30BEe9378381E7B6135d7283356D71b1` |
| MSFT | USD | `0x45C3C877C15E6BA2EBB19eA114Ea508d14C1Af2E` |
| MSTR | USD | `0x396118bdFB181e6240E74D243F266B061c0edc3D` |
| MU | USD | `0x425EEFdCf05ed6526C3cE61Af99429A228a6d596` |
| NBIS | USD | `0xE1D87B116Ba0fe898998f1D140339D1fA1E09705` |
| NVDA | USD | `0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15` |
| ORCL | USD | `0x0e6a64a2B58A6693a531E6c555f3A5d042eEA844` |
| PLTR | USD | `0x820ABedFF239034956B7A9d2F0a331f9F075eB4c` |
| QQQ | USD | `0x80901d846d5D7B030F26B480776EE3b29374C2ae` |
| RGTI | USD | `0x2A045cF1C49c61c166C036d2f06FA2D2d984f765` |
| RKLB | USD | `0x045477BF65Aef6f4F2386ad0164579e48381CC74` |
| SLV | USD | `0x209b73908e92Ae021826eD79609845451Ecba2ce` |
| SNDK | USD | `0xfb133Fa4B7b385802B693a293606682Df47109A3` |
| SPCX | USD | `0xB265810950ba6c5C0Ff821c9963014a56fD8Bffb` |
| SPY | USD | `0x319724394D3A0e3669269846abE664Cd621f9f6A` |
| TSLA | USD | `0x4A1166a659A55625345e9515b32adECea5547C38` |
| TSM | USD | `0x874cF94aa8eC88Fd9560094dD065f2fB3E41Fc2F` |
| USO | USD | `0x75a9c76Ef439e2C7c2E5a34Ab105EcFe3766431c` |

33 equity feeds. SVR proxies omitted. Use the standard proxy as `AggregatorV3Interface` unless a market is explicitly SVR-only.

## Crypto / stablecoin USD feeds

Not `us_equities_24/5`. Same 86400 heartbeat convention as the equity libraries until a tighter Chainlink heartbeat is confirmed on-chain.

| Asset | Counter | Standard proxy |
| ----- | ------- | -------------- |
| USDG | USD | `0x61B7e5650328764B076A108EFF5fa7282a1B9aD2` |

## Crypto exchange-rate feeds

Not a USD price. Harbor Yield uses this as `rate` and `USDG/USD` as `price` (`price × rate / 1e18`).

On-chain `description()` is `syrupUSDG / USDG Exchange Rate` (18 decimals). Chainlink's UI may label the asset `SYRUPUSDG / USD Exchange Rate`; the proxy quotes USDG per share, not USD.

| Asset | Counter | Standard proxy |
| ----- | ------- | -------------- |
| syrupUSDG | USDG | `0xDd194C66aDcb422F188a04434e4824D70c151cF0` |
