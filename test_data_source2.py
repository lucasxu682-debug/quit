import urllib.request, json

def fetch(url, label):
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9"
        })
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode("utf-8"))
        print(f"OK {label}: {data}")
        return data
    except Exception as e:
        print(f"FAIL {label}: {e}")
        return None

# Yahoo Finance different approach - quotes summary
print("=== Yahoo Finance quotes ===")
fetch("https://query1.finance.yahoo.com/v7/finance/quote?symbols=01347.HK,03993.HK,^HSI", "quote v7")

# Try Yahoo Finance market summary
print("\n=== Yahoo Finance market ===")
fetch("https://query1.finance.yahoo.com/v6 Finance/quote?symbols=01347.HK", "quote v6")

# Stooq - famous for providing Yahoo data back
print("\n=== Stooq ===")
fetch("https://stooq.com/q/d/l/?s=01347.hk&i=d", "stooq 01347.hk")
fetch("https://stooq.com/q/d/l/?s=^hsi&i=d", "stooq HSI")

# Financial Modeling Prep
print("\n=== Financial Modeling Prep ===")
fetch("https://financialmodelingprep.com/api/v3/quote-short/01347.HK?apikey=demo", "FMP demo")

# Web searching for HK stock APIs
print("\n=== Testing direct HKEX ===")
fetch("https://www.hkex.com.hk/eng/investing/securities/eqhist/01347.HK?MandDL=DC&Scheme=1", "HKEX historical")
