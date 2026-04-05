#!/usr/bin/env python3
"""
港股每日追踪脚本
每天 09:30 发送港股日报到 Discord hk-stock 频道

数据源：
- 港股（01347.HK / 03993.HK）：东方财富 push2.eastmoney.com
- 恒生指数（^HSI）：Yahoo Finance query1.finance.yahoo.com
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

# ========== 东方财富 API（港股）==========
def fetch_em_hk_stock(secid: str) -> dict | None:
    """
    获取港股数据，来自东方财富
    secid格式：'116.01347'（HK市场+代码）
    价格单位：HKD（直接就是小数，不需要额外转换）
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

        # f43=当前价，f44=昨收，f169=涨跌额（百元分之一HKD），f170=涨跌幅（万分之一）
        current_price = d["f43"] / 1000.0  # 转为HKD
        prev_close = d["f44"] / 1000.0
        change = d["f169"] / 1000.0
        change_pct = d["f170"] / 100.0  # 万分之一转为小数
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


# ========== 工具函数 ==========
def format_volume(v: int) -> str:
    if v >= 1_000_000_000:
        return f"{v/1_000_000_000:.2f}B"
    elif v >= 1_000_000:
        return f"{v/1_000_000:.2f}M"
    elif v >= 1_000:
        return f"{v/1_000:.1f}K"
    return str(v)


def volume_change_str(vol: int) -> str:
    """东方财富只提供当日成交量，不提供昨日对比，简化为绝对值"""
    return format_volume(vol)


# ========== 生成报告 ==========
def generate_report(stock_data: dict, hsi_data: dict | None) -> str:
    today = datetime.now().strftime("%Y年%m月%d日 %H:%M")
    lines = []

    lines.append(f"📊 港股每日追踪 — {today}")
    lines.append("")

    # ---- 持仓盈亏 ----
    total_cost = sum(p["shares"] * p["cost"] for p in POSITIONS.values())
    total_value = 0
    total_pnl = 0

    lines.append("**【持仓盈亏】（数据来源：东方财富实时行情）**")
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

        arrow = "↑" if pnl >= 0 else "↓"
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
    for sym, pos in POSITIONS.items():
        sd = stock_data.get(sym)
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

        lines.append(f"{color} **{pos['name']} ({sym}.HK)**")
        lines.append(f"   当前价：HKD {cur:.3f}（{arrow}{sign}{chg:.3f} / {arrow}{sign}{chg_pct:.2f}%）")
        lines.append(f"   昨收：HKD {prev:.3f}")
        lines.append(f"   成交量：{format_volume(vol)}")
        lines.append(f"   📖 术语解释：收盘价是当日最后一笔成交的价格；涨跌幅是与昨日收盘相比的百分比变化，正数上涨、负数下跌，🔴红色代表下跌")
        lines.append("")

    # ---- 恒生指数 ----
    if hsi_data:
        chg = hsi_data["change"]
        chg_pct = hsi_data["change_pct"]
        arrow = "↑" if chg >= 0 else "↓"
        sign = "+" if chg >= 0 else ""
        color = "🟢" if chg >= 0 else "🔴"
        lines.append(f"{color} **恒生指数**")
        lines.append(f"   收盘：{hsi_data['current_price']:.2f}（{arrow}{sign}{chg:.2f} / {arrow}{sign}{chg_pct:.2f}%）")
        if chg_pct < -1:
            lines.append(f"   市场情绪：偏空（大盘下跌超过1%，注意风险）")
        elif chg_pct > 1:
            lines.append(f"   市场情绪：偏多")
        else:
            lines.append(f"   市场情绪：中性")
        lines.append(f"   📖 术语解释：恒生指数是香港股市大盘指标，类似于上证指数，代表香港主要股票的总体走势")
        lines.append("")

    # ---- 今日关键词 ----
    lines.append("**【今日关键词解释】**")
    lines.append("📌 **涨跌幅**：与昨日收盘价相比的变化百分比，🔴红色代表下跌、🟢绿色代表上涨")
    lines.append("📌 **成交量**：当天成交的总股数，成交量高说明市场活跃，低说明冷清")
    lines.append("📌 **浮亏**：持仓成本价与当前市价的差值，账面上还没实现的损益（负数=亏钱）")
    lines.append("📌 **板块/行业**：同一类业务的股票分组，如「半导体板块」「新能源板块」，同板块往往同涨同跌")

    return "\n".join(lines)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("[stock] 开始获取股票数据...")

    # 获取港股数据（东方财富）
    stock_data = {}
    for secid, sym in [("116.01347", "01347"), ("116.03993", "03993")]:
        sd = fetch_em_hk_stock(secid)
        if sd:
            stock_data[sym] = sd
            print(f"[stock] {sym} OK: {sd['current_price']:.3f} HKD ({sd['change']:+.3f} / {sd['change_pct']:+.2f}%)")

    # 获取恒生指数（Yahoo Finance）
    hsi_data = fetch_hsi()
    if hsi_data:
        print(f"[stock] HSI OK: {hsi_data['current_price']:.2f}")

    if not stock_data:
        print("[stock] 所有股票数据获取失败，退出")
        return

    # 生成报告
    report = generate_report(stock_data, hsi_data)
    print()
    print("=" * 50)
    print(report)
    print("=" * 50)
    print(f"\n[stock] 请复制上方内容发送到 Discord hk-stock 频道")


if __name__ == "__main__":
    main()
