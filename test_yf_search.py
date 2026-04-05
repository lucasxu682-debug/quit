import urllib.request, json

# Test if these specific stocks exist on Yahoo Finance at all
for sym in ["01347.HK", "03993.HK", "0700.HK", "0005.HK", "9988.HK"]:
    try:
        url = f"https://query1.finance.yahoo.com/v1/finance/search?q={sym}&quotesCount=1&newsCount=0"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            d = json.loads(r.read().decode("utf-8"))
        quotes = d.get("quotes", [])
        count = d.get("count", 0)
        if quotes:
            q = quotes[0]
            print(f"{sym}: count={count}, symbol={q.get('symbol')}, shortName={q.get('shortName')}, exch={q.get('exchange')}")
        else:
            print(f"{sym}: count={count} - NOT FOUND")
    except Exception as e:
        print(f"{sym}: ERROR {e}")
