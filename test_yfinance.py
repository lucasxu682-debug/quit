import yfinance as yf
import json

for sym in ["01347.HK", "03993.HK", "0700.HK"]:
    try:
        ticker = yf.Ticker(sym)
        info = ticker.info
        print(f"\n{sym}:")
        print(f"  regularMarketPrice: {info.get('regularMarketPrice')}")
        print(f"  currentPrice: {info.get('currentPrice')}")
        print(f"  previousClose: {info.get('previousClose')}")
        print(f"  marketCap: {info.get('marketCap')}")
        print(f"  currency: {info.get('currency')}")
        print(f"  shortName: {info.get('shortName')}")
        print(f"  longName: {info.get('longName')}")
        print(f"  exchange: {info.get('exchange')}")
    except Exception as e:
        print(f"{sym}: ERROR {e}")
