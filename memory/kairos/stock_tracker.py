#!/usr/bin/env python3
"""
港股每日追踪脚本
每天 16:30 发送港股日报到 Discord hk-stock 频道

数据源：
- 港股（01347.HK / 03993.HK）：东方财富 push2.eastmoney.com
- 恒生指数（^HSI）：Yahoo Finance query1.finance.yahoo.com
- 市场快讯：东方财富快讯（作为当日市场情绪参考）
"""

import urllib.request
import json
import re
import sys
from datetime import datetime

# ========== 配置 ==========
DISCORD_CHANNEL = "channel:1490272018850123917"

# ========== 持仓数据 ==========
POSITIONS = {
    "01347": {"name": "华虹半导体", "shares": 1000, "cost": 99.987},
    "03993": {"name": "洛阳钼业", "shares": 6000, "cost": 20.361},
}

# 股票行业信息
STOCK_INFO = {
    "01347": {
        "industry": "半导体",
        "industry_zh": "半导体行业",
        "desc": "华虹半导体是香港上市的晶圆代工企业，主要生产8英寸和12英寸晶圆",
    },
    "03993": {
        "industry": "矿业/有色金属",
        "industry_zh": "矿业（钴、锂、铜等关键矿产）",
        "desc": "洛阳钼业是全球领先的矿业公司，主要从事铜、钴、锂、铌等矿产的开采和贸易",
    },
}


# ========== 东方财富 API（港股）==========
def fetch_em_hk_stock(secid: str) -> dict | None:
    """
    获取港股数据，来自东方财富
    secid格式：'116.01347'（HK市场+代码）
    """
    url = f"https://push2.eastmoney.com/api/qt/stock/get?secid={secid}&fields=f43,f44,f45,f46,f47,f48,f57,f58,f60,f169,f170"
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://finance.eastmoney.com/"
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        d = data.get("data", {})
        if not d or d.get("f43") is None:
            return None

        current_price = d["f43"] / 1000.0
        prev_close = d["f44"] / 1000.0
        change = d["f169"] / 1000.0
        change_pct = d["f170"] / 100.0
        volume = int(d.get("f47", 0))
        name = d.get("f58", "")

        return {
            "symbol": d.get("f57", ""),
            "name": name,
            "current_price": current_price,
            "prev_close": prev_close,
            "change": change,
            "change_pct": change_pct,
            "volume": volume,
        }
    except Exception as e:
        print(f"[stock] EastMoney {secid} 失败: {e}", file=sys.stderr)
        return None


# ========== Yahoo Finance API（恒生指数）==========
def fetch_hsi() -> dict | None:
    """获取恒生指数数据"""
    url = "https://query1.finance.yahoo.com/v8/finance/chart/%5EHSI?interval=1d&range=5d"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        result = data["chart"]["result"][0]
        meta = result["meta"]
        closes = [c for c in result["indicators"]["quote"][0].get("close", []) if c]
        current = meta.get("regularMarketPrice") or (closes[-1] if closes else 0)
        prev = meta.get("regularMarketPreviousClose") or (closes[-2] if len(closes) >= 2 else current)
        chg = current - prev
        chg_pct = (chg / prev * 100) if prev else 0
        return {
            "current_price": current,
            "prev_close": prev,
            "change": chg,
            "change_pct": chg_pct,
        }
    except Exception as e:
        print(f"[stock] HSI 获取失败: {e}", file=sys.stderr)
        return None


# ========== 东方财富市场快讯（作为市场情绪参考）==========
def fetch_market_kuaixun(limit: int = 10) -> list[dict]:
    """
    获取东方财富市场快讯，作为当日市场情绪的参考
    注意：这是通用市场快讯，不是针对特定股票的
    """
    url = "https://push2.eastmoney.com/api/qt/clist/get?cb=jQuery&pn=1&pz=20&po=1&np=1&ut=&fltt=2&invt=2&fid=f2&fs=m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23&fields=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f13,f14,f15,f16,f17,f18,f20,f21,f23,f24,f25,f26,f22,f11,f62,f128,f136,f115,f152"
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://finance.eastmoney.com/"
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read().decode("utf-8")
            # Remove jQuery wrapper
            raw = re.sub(r'^jQuery\d+\(', '', raw.rstrip(');'))
            data = json.loads(raw)
        news_list = data.get("data", {}).get("diff", [])
        results = []
        for item in news_list[:limit]:
            title = item.get("f14", "") or item.get("f12", "")
            if title:
                results.append({"title": str(title)[:60]})
        return results
    except Exception as e:
        print(f"[stock] 市场快讯获取失败: {e}", file=sys.stderr)
        return []


# ========== 东方财富 A股大盘（作为参考）==========
def fetch_ashare_index() -> dict | None:
    """获取沪深300指数，作为A股情绪参考（对港股有联动影响）"""
    url = "https://push2.eastmoney.com/api/qt/stock/get?secid=1.000300&fields=f43,f44,f45,f46,f57,f58,f169,f170"
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://finance.eastmoney.com/"
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        d = data.get("data", {})
        if not d:
            return None
        return {
            "name": "沪深300",
            "current_price": d["f43"] / 1000.0,
            "change_pct": d["f170"] / 100.0,
        }
    except Exception as e:
        print(f"[stock] 沪深300获取失败: {e}", file=sys.stderr)
        return None


# ========== 工具函数 ==========
def format_volume(v: int) -> str:
    if v >= 1_000_000_000:
        return f"{v/1_000_000_000:.2f}B"
    elif v >= 1_000_000:
        return f"{v/1_000_000:.2f}M"
    elif v >= 1_000:
        return f"{v/1_000:.1f}K"
    return str(v)


def analyze_stock_signal(sd: dict, info: dict) -> tuple[str, str]:
    """
    分析个股走势信号
    返回 (signal_emoji, description)
    signal: 超卖/超买/放量/缩量/破位/支撑 等
    """
    signals = []
    chg_pct = sd["change_pct"]
    chg = sd["change"]
    vol = sd["volume"]

    # 涨跌幅信号
    if chg_pct <= -5:
        signals.append("大幅下跌（跌幅≥5%）")
    elif chg_pct <= -3:
        signals.append("明显下跌（跌幅3-5%）")
    elif chg_pct <= -1:
        signals.append("小幅下跌")
    elif chg_pct >= 5:
        signals.append("大幅上涨（涨幅≥5%）")
    elif chg_pct >= 3:
        signals.append("明显上涨（涨幅3-5%）")
    elif chg_pct >= 1:
        signals.append("小幅上涨")
    else:
        signals.append("基本持平")

    # 成交量信号（粗略估算，假设日常成交约10M为正常）
    if vol >= 50_000_000:
        signals.append("成交量大幅放大")
    elif vol >= 30_000_000:
        signals.append("成交量有所放大")
    elif vol <= 5_000_000:
        signals.append("成交量萎缩")

    emoji = "🔴" if chg < 0 else ("🟢" if chg > 0 else "⚪")
    desc = "，".join(signals) if signals else "走势平稳"
    return emoji, desc


# ========== 生成报告 ==========
def generate_report(stock_data: dict, hsi_data: dict | None, ashare: dict | None) -> str:
    today = datetime.now().strftime("%Y年%m月%d日")
    lines = []

    lines.append(f"📊 港股每日追踪 — {today}（收盘后）")
    lines.append("")

    # ---- 持仓盈亏 ----
    total_cost = sum(p["shares"] * p["cost"] for p in POSITIONS.values())
    total_value = 0
    total_pnl = 0

    lines.append("**【持仓盈亏】**")
    for sym, pos in POSITIONS.items():
        sd = stock_data.get(sym)
        if not sd:
            lines.append(f"⚠️ {sym}.HK 数据获取失败")
            continue

        cur = sd["current_price"]
        cost_total = pos["shares"] * pos["cost"]
        value = pos["shares"] * cur
        pnl = value - cost_total
        pnl_pct = pnl / cost_total * 100
        total_value += value
        total_pnl += pnl

        emoji = "🟢" if pnl >= 0 else "📉"
        lines.append(f"{emoji} {pos['name']} ({sym}.HK)")
        lines.append(f"   持仓成本：HKD {cost_total:,.2f}（{pos['cost']} × {pos['shares']}股）")
        lines.append(f"   当前价值：HKD {value:,.2f}（{cur:.3f} × {pos['shares']}股）")
        lines.append(f"   浮亏：HKD {pnl:,.2f}（{pnl_pct:.2f}%）")
        chg = sd["change"]
        chg_pct = sd["change_pct"]
        arr = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        lines.append(f"   今日涨跌：{arr}{chg:+.3f} HKD（{arr}{sign}{chg_pct:.2f}%）")
        lines.append("")

    total_pnl_pct = total_pnl / total_cost * 100
    lines.append(f"📌 合计成本：HKD {total_cost:,.2f}")
    lines.append(f"📌 合计当前价值：HKD {total_value:,.2f}")
    lines.append(f"📌 合计浮亏：HKD {total_pnl:,.2f}（{total_pnl_pct:.2f}%）")
    lines.append("")

    # ---- 个股详情 ----
    lines.append("**【个股分析】**")
    for sym, pos in POSITIONS.items():
        sd = stock_data.get(sym)
        info = STOCK_INFO.get(sym, {})
        if not sd:
            lines.append(f"⚠️ {sym}.HK 数据获取失败")
            continue

        cur = sd["current_price"]
        prev = sd["prev_close"]
        chg = sd["change"]
        chg_pct = sd["change_pct"]
        vol = sd.get("volume", 0)

        arrow = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        color = "🟢" if chg >= 0 else "🔴"
        sig_emoji, sig_desc = analyze_stock_signal(sd, info)

        lines.append(f"{color} **{pos['name']} ({sym}.HK)** — {info.get('industry_zh', '')}")
        lines.append(f"   收盘价：HKD {cur:.3f}（{arrow}{sign}{chg:+.3f} / {arrow}{sign}{chg_pct:.2f}%）")
        lines.append(f"   昨收：HKD {prev:.3f}")
        lines.append(f"   成交量：{format_volume(vol)}")
        lines.append(f"   今日信号：{sig_emoji} {sig_desc}")
        lines.append(f"   📖 {info.get('desc', '')}")
        lines.append("")

    # ---- 大盘与市场情绪 ----
    lines.append("**【大盘与市场情绪】**")
    if hsi_data:
        chg = hsi_data["change"]
        chg_pct = hsi_data["change_pct"]
        arrow = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        color = "🟢" if chg >= 0 else "🔴"
        if chg_pct < -1:
            sentiment = "偏空（大盘下跌超1%，注意风险）"
        elif chg_pct > 1:
            sentiment = "偏多"
        else:
            sentiment = "中性"
        lines.append(f"{color} 恒生指数：{hsi_data['current_price']:.2f}（{arrow}{sign}{chg:.2f} / {arrow}{sign}{chg_pct:.2f}%）— {sentiment}")

    if ashare:
        chg_pct = ashare["change_pct"]
        arrow = "↑" if chg_pct >= 0 else "↓"
        sign = "+" if chg_pct >= 0 else ""
        color = "🟢" if chg_pct >= 0 else "🔴"
        lines.append(f"{color} 沪深300（A股参考）：{ashare['current_price']:.2f}（{arrow}{sign}{chg_pct:.2f}%）")

    lines.append("")
    lines.append("📋 **定期公告**")
    lines.append("   公司公告/新闻请前往 HKEX 披露易或百度搜索查看")
    lines.append("")

    # ---- 今日关键词 ----
    lines.append("**【术语解释】**")
    lines.append("📌 **涨跌幅**：与昨日收盘价相比的变化百分比，🔴红色=下跌、🟢绿色=上涨")
    lines.append("📌 **成交量**：当天成交的总股数，量放大说明资金活跃，量萎缩说明市场冷清")
    lines.append("📌 **浮亏**：持仓成本与当前市价的差值，负数代表亏损")
    lines.append("📌 **超卖/超买**：技术指标，数值极端时可能出现反弹或回调（仅供参考）")
    lines.append("📌 **放量/缩量**：成交量较平日明显增加或减少，往往配合价格变动出现")

    return "\n".join(lines)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("[stock] 开始获取股票数据...")

    # 港股数据
    stock_data = {}
    for secid, sym in [("116.01347", "01347"), ("116.03993", "03993")]:
        sd = fetch_em_hk_stock(secid)
        if sd:
            stock_data[sym] = sd
            print(f"[stock] {sym} OK: {sd['current_price']:.3f} HKD ({sd['change_pct']:+.2f}%)")

    # 恒生指数
    hsi_data = fetch_hsi()
    if hsi_data:
        print(f"[stock] HSI OK: {hsi_data['current_price']:.2f}")

    # 沪深300
    ashare = fetch_ashare_index()
    if ashare:
        print(f"[stock] 沪深300 OK: {ashare['current_price']:.2f} ({ashare['change_pct']:+.2f}%)")

    if not stock_data:
        print("[stock] 所有股票数据获取失败，退出")
        return

    report = generate_report(stock_data, hsi_data, ashare)
    print()
    print("=" * 55)
    print(report)
    print("=" * 55)
    print(f"\n[stock] 请复制上方内容发送到 Discord hk-stock 频道")


if __name__ == "__main__":
    main()
