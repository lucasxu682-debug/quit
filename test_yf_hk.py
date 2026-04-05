import urllib.request, json, re

def get_yahoo_hk_price(symbol):
    """Try to get price from Yahoo Finance Hong Kong page HTML"""
    try:
        url = f"https://hk.finance.yahoo.com/quote/{symbol}/"
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept-Language": "zh-HK,zh-TW,zh;q=0.9,en;q=0.8"
        })
        with urllib.request.urlopen(req, timeout=10) as r:
            html = r.read().decode("utf-8", errors="replace")

        # Try different price patterns
        # Pattern 1: data price
        p1 = re.findall(r'"price":\s*("([^"]+)"|' + r"'([^']+)')", html)
        p2 = re.findall(r'"regularMarketPrice":\s*([0-9.]+)",', html)
        p3 = re.findall(r'"previousClose":\s*([0-9.]+)",', html)
        p4 = re.findall(r'"regularMarketPreviousClose":\s*([0-9.]+)",', html)
        p5 = re.findall(r'class="price[^"]*"[^>]*>([0-9,]+\.[0-9]+)<', html)
        p6 = re.findall(r'"[0-9]+\.[0-9]+"', html[:50000])
        p7 = re.findall(r'lastPrice["\s:]+([0-9]+\.[0-9]+)', html)
        p8 = re.findall(r'qprice["\s:]+([0-9]+\.[0-9]+)', html)
        p9 = re.findall(r'marketPrice["\s:]+([0-9]+\.[0-9]+)', html)

        print(f"  price patterns found:")
        print(f"  p2 (regularMarketPrice): {p2[:5]}")
        print(f"  p3 (previousClose): {p3[:5]}")
        print(f"  p4 (regularMarketPreviousClose): {p4[:5]}")
        print(f"  p5 (class price): {p5[:5]}")
        print(f"  p7 (lastPrice): {p7[:5]}")
        print(f"  p8 (qprice): {p8[:5]}")
        print(f"  p9 (marketPrice): {p9[:5]}")
        return p2[0] if p2 else None
    except Exception as e:
        print(f"  ERROR: {e}")
        return None

def get_yahoo_quote(symbol):
    """Try Yahoo quote API"""
    try:
        url = f"https://query1.finance.yahoo.com/v6/finance/quote?symbols={symbol}"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode("utf-8"))
        print(f"  quote API: {str(data)[:500]}")
    except Exception as e:
        print(f"  quote API ERROR: {e}")

def get_yahoo_tdify(symbol):
    """Try Yahoo Finance TDIFY API"""
    try:
        url = f"https://tdify.io/api/quote?symbol={symbol}"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode("utf-8"))
        print(f"  tdify: {data}")
    except Exception as e:
        print(f"  tdify ERROR: {e}")

def get_moneyflow(symbol):
    """Try moneyflow API"""
    try:
        url = f"https://moneyflow.com/api/quote/{symbol}"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode("utf-8"))
        print(f"  moneyflow: {data}")
    except Exception as e:
        print(f"  moneyflow ERROR: {e}")

for sym in ["01347.HK", "03993.HK"]:
    print(f"\n=== {sym} ===")
    get_yahoo_hk_price(sym)
    get_yahoo_quote(sym)
    get_yahoo_tdify(sym)
    get_moneyflow(sym)
