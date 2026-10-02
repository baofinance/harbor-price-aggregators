# Rate sources — Robinhood

Robinhood-specific rate providers when a market needs them.

| Source | Address | Notes |
| ------ | ------- | ----- |
| syrupUSDG token | `0x40858070814a57FdF33a613ae84fE0a8b4a874f7` | CCIP representation. `convertToAssets` reverts; not the rate source. |
| syrupUSDG/USDG | `0xDd194C66aDcb422F188a04434e4824D70c151cF0` | Chainlink 18-decimal exchange-rate feed. |
