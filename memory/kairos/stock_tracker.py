#!/usr/bin/env python3
"""
港股每日追踪脚本
每天 09:30 发送港股日报到 Discord hk-stock 频道
"""

import urllib.request
import json
import sys
from datetime import datetime

# ========== 配置 ==========
STOCKS = {
    "01347": "华虹半导体",
    "03993": "洛阳钼业",
}
INDEX = "^HSI"  # 恒生指数
DISCORD_CHANNEL = "channel:1500327713228550276"

# ========== 持仓数据（来自 USER.md）==========
POSITIONS = {
    "01347": {"name": "华虹半导体", "shares": 1000, "cost": 99.987},
    "03993": {"name": "洛阳钼业", "shares": 6000, "cost": 20.361},
}

# ========== Yahoo Finance API ==========
def fetch_stock_data(symbol: str) -> dict | None:
    """获取股票数据，返回 dict 或 None"""
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1d&range=5d"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        result = data["chart"]["result"][0]
        meta = result["meta"]
        quotes = result["indicators"]["quote"][0]
        closes = [c for c in (quotes.get("close") or []) if c is not None]
        volumes = quotes.get("volume", [])

        current_price = meta.get("regularMarketPrice") or (closes[-1] if closes else 0)
        prev_close = meta.get("regularMarketPreviousClose") or (closes[-2] if len(closes) >= 2 else current_price)
        market_cap = meta.get("marketCap")

        # 成交量（今日 vs 昨日）
        volume_today = volumes[-1] if volumes else 0
        volume_yesterday = volumes[-2] if len(volumes) >= 2 else 0

        change = current_price - prev_close
        change_pct = (change / prev_close * 100) if prev_close else 0

        return {
            "symbol": symbol,
            "current_price": current_price,
            "prev_close": prev_close,
            "change": change,
            "change_pct": change_pct,
            "volume_today": volume_today,
            "volume_yesterday": volume_yesterday,
            "currency": meta.get("currency", "HKD"),
            "market_cap": market_cap,
            "exchange": meta.get("exchangeName", ""),
        }
    except Exception as e:
        print(f"[stock] 获取 {symbol} 失败: {e}", file=sys.stderr)
        return None


def format_volume(v: int) -> str:
    """格式化成交量"""
    if v >= 1_000_000_000:
        return f"{v/1_000_000_000:.2f}B"
    elif v >= 1_000_000:
        return f"{v/1_000_000:.2f}M"
    elif v >= 1_000:
        return f"{v/1_000:.1f}K"
    return str(v)


def volume_change_pct(vol_today: int, vol_yesterday: int) -> str:
    """成交量变化百分比"""
    if not vol_yesterday or vol_yesterday == 0:
        return "N/A"
    chg = (vol_today - vol_yesterday) / vol_yesterday * 100
    arrow = "↑" if chg > 0 else "↓"
    return f"{arrow}{abs(chg):.0f}%"


def fetch_news(symbol: str, label: str) -> list[dict]:
    """获取近期新闻标题"""
    url = f"https://query2.finance.yahoo.com/v1/finance/search?q={symbol}&newsCount=2&enableFuzzyProps=false"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        news = data.get("news", [])
        results = []
        for n in news[:3]:
            title = n.get("title", "")
            if not title:
                continue
            # 在空格或标点处截断，避免切断单词
            if len(title) > 55:
                title = title[:55].rsplit(None, 1)[0] + "…"
            results.append({"title": title})
        return results
    except Exception as e:
        print(f"[stock] 获取 {label} 新闻失败: {e}", file=sys.stderr)
        return []


# ========== 生成报告 ==========
def generate_report(stock_data: dict, news: list[dict], index_data: dict | None) -> str:
    today_str = datetime.now().strftime("%Y年%m月%d日 %H:%M")
    lines = []

    # ---- 港股日报标题 ----
    lines.append(f"📊 港股每日追踪 — {today_str}")
    lines.append("")

    # ---- 持仓盈亏总览 ----
    total_cost = sum(p["shares"] * p["cost"] for p in POSITIONS.values())
    total_value = 0
    total_unrealized_pnl = 0

    lines.append("**【持仓盈亏】**")
    for sym, pos in POSITIONS.items():
        sd = stock_data.get(sym)
        if not sd:
            continue
        cur = sd["current_price"]
        cost_total = pos["shares"] * pos["cost"]
        value = pos["shares"] * cur
        pnl = value - cost_total
        pnl_pct = pnl / cost_total * 100
        total_value += value
        total_unrealized_pnl += pnl
        emoji = "📈" if pnl >= 0 else "📉"
        lines.append(f"{emoji} {pos['name']} ({sym}.HK)")
        lines.append(f"   持仓成本：HKD {cost_total:,.2f}（{pos['cost']} × {pos['shares']}股）")
        lines.append(f"   当前价值：HKD {value:,.2f}（{cur:.2f} × {pos['shares']}股）")
        lines.append(f"   浮亏：HKD {pnl:,.2f}（{pnl_pct:.1f}%）")
        lines.append(f"   买入价 vs 现价：{pos['cost']} → {cur:.2f}，{'+' if cur >= pos['cost'] else ''}{(cur-pos['cost'])/pos['cost']*100:.1f}%")
        lines.append("")

    total_pnl_pct = total_unrealized_pnl / total_cost * 100
    lines.append(f"📌 合计成本：HKD {total_cost:,.2f}")
    lines.append(f"📌 合计当前价值：HKD {total_value:,.2f}")
    lines.append(f"📌 合计浮亏：HKD {total_unrealized_pnl:,.2f}（{total_pnl_pct:.1f}%）")
    lines.append("")

    # ---- 个股详情 ----
    for sym, pos in POSITIONS.items():
        sd = stock_data.get(sym)
        if not sd:
            lines.append(f"⚠️ {sym}.HK 数据获取失败")
            continue

        cur = sd["current_price"]
        prev = sd["prev_close"]
        chg = sd["change"]
        chg_pct = sd["change_pct"]
        vol_today = sd["volume_today"]
        vol_yesterday = sd["volume_yesterday"]

        arrow = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        emoji = "🟢" if chg >= 0 else "🔴"

        lines.append(f"{emoji} **{pos['name']} ({sym}.HK)**")
        lines.append(f"   收盘价：HKD {cur:.2f}（{arrow}{sign}{chg:.2f} / {arrow}{sign}{chg_pct:.2f}%）")
        lines.append(f"   昨收价：HKD {prev:.2f}")
        lines.append(f"   成交量：{format_volume(vol_today)}（今日 vs 昨日 {volume_change_pct(vol_today, vol_yesterday)}）")
        lines.append("   📖 **术语解释**：收盘价是当日最后一笔成交的价格；涨跌幅是与昨日收盘相比的百分比变化，正数上涨、负数下跌")

        # 成交量说明
        if vol_today > vol_yesterday * 1.5:
            lines.append(f"   📈 成交量放大，可能有资金异动")
        elif vol_today < vol_yesterday * 0.5:
            lines.append(f"   📉 成交量萎缩，市场关注度下降")

        # 新闻
        stock_news = news.get(sym, [])
        if stock_news:
            lines.append("   📰 **可能的影响因素**：")
            for n in stock_news[:2]:
                if n["title"]:
                    lines.append(f"   · {n['title']}")
        else:
            lines.append("   📰 可能的影响因素：暂无近期公开新闻")

        lines.append("")

    # ---- 恒生指数 ----
    if index_data:
        sd = index_data
        chg = sd["change"]
        chg_pct = sd["change_pct"]
        arrow = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        lines.append(f"{'🟢' if chg >= 0 else '🔴'} **恒生指数**")
        lines.append(f"   收盘：{sd['current_price']:.2f}（{arrow}{sign}{chg:.2f} / {arrow}{sign}{chg_pct:.2f}%）")
        if chg_pct < -1:
            lines.append("   市场情绪：偏空（大盘下跌超过1%，注意风险")
        elif chg_pct > 1:
            lines.append("   市场情绪：偏多")
        else:
            lines.append("   市场情绪：中性")
        lines.append("   📖 **术语解释**：恒生指数是香港股市大盘指标，类似于A股的上证指数，代表香港主要股票的总体走势")
        lines.append("")

    # ---- 今日关键词 ----
    lines.append("**【今日关键词解释】**")
    lines.append("📌 **涨跌幅**：与昨日收盘价相比的变化百分比。（-4.03%）表示下跌了4.03%，颜色通常用🔴红色表示下跌、🟢绿色表示上涨")
    lines.append("📌 **成交量**：当天成交的总股数，成交量低说明市场冷清，成交量放大说明有资金在活跃买卖")
    lines.append("📌 **浮亏**：持仓成本价与当前市价的差值，代表账面上还没实现的损益")
    lines.append("📌 **板块/行业**：同一类业务的股票分组，如「半导体板块」「新能源板块」。同一板块的股票往往同涨同跌")

    return "\n".join(lines)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("[stock] 开始获取股票数据...")

    # 获取数据
    stock_data = {}
    news = {}

    for sym in STOCKS:
        sd = fetch_stock_data(sym)
        if sd:
            stock_data[sym] = sd
            print(f"[stock] {sym} OK: {sd['current_price']:.2f}")
        news[sym] = fetch_news(sym, STOCKS[sym])

    index_data = fetch_stock_data(INDEX)
    if index_data:
        print(f"[stock] ^HSI OK: {index_data['current_price']:.2f}")

    if not stock_data:
        print("[stock] 所有股票数据获取失败，退出")
        return

    # 生成报告
    report = generate_report(stock_data, news, index_data)
    print("\n" + "="*50)
    print(report)
    print("="*50)
    print(f"\n[stock] 报告生成完成，请复制上方内容发送到 Discord hk-stock 频道")
    print(f"[stock] 频道 ID: {DISCORD_CHANNEL.replace('channel:', '')}")


if __name__ == "__main__":
    main()
