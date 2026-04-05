import urllib.request, json, re

def fetch(url, label, parse_json=True):
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)",
            "Accept": "application/json" if parse_json else "*/*",
        })
        with urllib.request.urlopen(req, timeout=10) as r:
            raw = r.read()
            if parse_json:
                data = json.loads(raw.decode("utf-8"))
                print(f"OK {label}: {str(data)[:400]}")
            else:
                text = raw.decode("utf-8", errors="replace")
                # Try to find price using regex
                prices = re.findall(r'"regularMarketPrice":\s*([0-9.]+)', text)
                prevs = re.findall(r'"regularMarketPreviousClose":\s*([0-9.]+)', text)
                print(f"RAW {label} ({len(raw)} bytes)")
                if prices:
                    print(f"  Found prices: {prices[:5]}")
                if prevs:
                    print(f"  Found prevs: {prevs[:5]}")
                print(f"  First 300 chars: {text[:300]}")
            return True
    except Exception as e:
        print(f"FAIL {label}: {e}")
        return None

# Yahoo mobile API
print("=== Yahoo Mobile ===")
fetch("https://query1.finance.yahoo.com/v7/finance/chart/01347.HK?interval=1d&range=1d", "mobile chart")

# Yahoo bcf
print("\n=== Yahoo BCF ===")
fetch("https://query2.bcf.yahoo.com/v7/finance/chart/01347.HK?interval=1d&range=1d", "bcf chart")

# Try Yahoo Finance screener API
print("\n=== Yahoo screener ===")
fetch("https://query1.finance.yahoo.com/v1/finance/search?q=01347.HK&quotesCount=1&newsCount=0", "yahoo search")

# Google Finance quote API (the old one)
print("\n=== Google Finance old API ===")
fetch("https://finance.google.com/finance/info?client=ig&q=01347.HK", "google finance old", parse_json=False)

# Try to extract from Google Finance HTML
print("\n=== Google Finance HTML parse ===")
url = "https://www.google.com/finance/quote/01347:HKG"
try:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=10) as r:
        html = r.read().decode("utf-8", errors="replace")
    # Look for price patterns
    price_patterns = re.findall(r'([0-9,]+\.[0-9]{2})\s*(?:HKD|HK\$|\$)', html)
    print(f"Found prices in HTML: {price_patterns[:10]}")
    # Look for the price in meta tags or structured data
    og_price = re.findall(r'"price":\s*"([0-9.]+)"', html)
    print(f"OG price: {og_price}")
    og_title = re.findall(r'"title":\s*"([^"]+)"', html)
    print(f"OG title: {og_title[:5]}")
except Exception as e:
    print(f"FAIL: {e}")
