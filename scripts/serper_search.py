#!/usr/bin/env python3
"""
Serper.dev 搜索脚本
用法: python serper_search.py "搜索关键词"
"""

import sys
import json
import requests

API_KEY = "5351bf144e4251aa3234ca378e99c65be054413d"
URL = "https://google.serper.dev/search"

def search(query, num_results=10):
    """执行搜索并返回结果"""
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    payload = {"q": query, "num": num_results}
    
    response = requests.post(URL, headers=headers, json=payload, timeout=10)
    response.raise_for_status()
    data = response.json()
    
    results = []
    for item in data.get("organic", []):
        results.append({
            "title": item.get("title", ""),
            "link": item.get("link", ""),
            "snippet": item.get("snippet", ""),
            "date": item.get("date", "")
        })
    
    return results

def format_results(results):
    """格式化输出搜索结果"""
    output = []
    for i, r in enumerate(results, 1):
        date_info = f" [{r['date']}]" if r['date'] else ""
        output.append(f"{i}. {r['title']}{date_info}")
        output.append(f"   {r['link']}")
        output.append(f"   {r['snippet']}")
        output.append("")
    return "\n".join(output)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python serper_search.py \"搜索关键词\" [结果数量]")
        sys.exit(1)
    
    query = sys.argv[1]
    num = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    
    try:
        results = search(query, num)
        print(f"[SEARCH] {query}")
        print(f"[RESULTS] {len(results)} results found\n")
        print(format_results(results))
    except Exception as e:
        print(f"[ERROR] Search failed: {e}")
        sys.exit(1)
