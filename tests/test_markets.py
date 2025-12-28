from offchain_feeds.markets import Market


def test_market_parse_roundtrip() -> None:
    m = Market.parse("eth-usd")
    assert m.base == "ETH"
    assert m.quote == "USD"
    assert m.code == "ETH-USD"
