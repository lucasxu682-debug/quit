import urllib.request, json, sys

def test_url(url, label):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            d = json.loads(r.read().decode("utf-8"))
        print(f"OK {label}: {str(d)[:300]}")
        return d
    except Exception as e:
        print(f"FAIL {label}: {e}")
        return None

# Test different Yahoo endpoints
print("=== Yahoo Finance tests ===")
test_url("https://query1.finance.yahoo.com/v8/finance/chart/01347.HK?interval=1d&range=1d", "v8 chart 01347.HK")
test_url("https://query2.finance.yahoo.com/v8/finance/chart/01347.HK?interval=1d&range=1d", "v8 chart 01347.HK (query2)")
test_url("https://query1.finance.yahoo.com/v7/finance/chart/01347.HK?interval=1d&range=1d", "v7 chart 01347.HK")

# Try without .HK
print("\n=== Without .HK suffix ===")
for sym in ["01347", "H01347", "HK01347"]:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}?interval=1d&range=1d"
    test_url(url, sym)

# Try different exchanges
print("\n=== Different exchange prefixes ===")
for sym in ["HKE:01347", "HK:01347", "0P0000LH9F.HK"]:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}?interval=1d&range=1d"
    test_url(url, sym)

# Alpha Vantage (free tier - needs API key, test with demo)
print("\n=== Alpha Vantage (demo) ===")
test_url("https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=01347.HK&apikey=demo", "Alpha Vantage demo")

# Finnhub (free tier)
print("\n=== Finnhub ===")
test_url("https://finnhub.io/api/v1/quote?symbol=01347.HK&token=demo", "Finnhub demo")

# Twelve Data
print("\n=== Twelve Data ===")
test_url("https://api.twelvedata.com/price?symbol=01347.HK&apikey=demo", "Twelve Data demo")
