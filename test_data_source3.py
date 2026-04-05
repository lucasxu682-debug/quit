import urllib.request, json

def fetch(url, label):
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "*/*",
        })
        with urllib.request.urlopen(req, timeout=10) as r:
            raw = r.read()
            print(f"RAW {label} ({len(raw)} bytes): {raw[:200]}")
            try:
                data = json.loads(raw.decode("utf-8"))
                print(f"JSON OK {label}: {str(data)[:300]}")
            except:
                text = raw.decode("utf-8", errors="replace")
                print(f"TEXT {label}: {text[:200]}")
        return True
    except Exception as e:
        print(f"FAIL {label}: {e}")
        return False

# Yahoo historical download (CSV endpoint)
print("=== Yahoo CSV download ===")
url = "https://query1.finance.yahoo.com/v7/finance/download/01347.HK?period1=0&period2=9999999999&interval=1d&events=history"
fetch(url, "yahoo csv 01347")

# Try Google Finance
print("\n=== Google Finance ===")
fetch("https://www.google.com/finance/quote/01347:HKG", "google finance 01347")

# MoneyLine
print("\n=== MoneyLine ===")
fetch("https://www.moneyline.com/quote/01347.HK", "moneyline 01347")

# Investing.com HK stocks
print("\n=== Investing.com ===")
fetch("https://www.investing.com/indices/hk-stock-market", "investing.com HK market")
