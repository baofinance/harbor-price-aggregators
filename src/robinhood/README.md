# CREATE3 wirings — Robinhood

Hard-coded feed/rate wiring. Filename must match deploy:

`src/robinhood/Aggregator_<base>_<quote>_robinhood.sol`

Salt: `<prefix>::<base>::<quote>::wrappedPriceAggregator`

| Pair | Wiring |
| ---- | ------ |
| syrupUSDG/USD | `Aggregator_syrupUSDG_USD_robinhood` |
