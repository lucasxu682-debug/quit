#!/usr/bin/env python3
"""
KAIROS autoDream.py — 凌晨记忆整理脚本
每天凌晨 06:00 自动运行，读取过去 24 小时的 observation log，生成摘要并更新 MEMORY.md
"""

import argparse
from pathlib import Path
from datetime import datetime, timedelta
import re
import json


def get_yesterday_date():
    """获取昨天的日期字符串"""
    yesterday = datetime.now() - timedelta(days=1)
    return yesterday.strftime("%Y-%m-%d")


def read_observation_log(obs_dir: Path, date_str: str) -> str | None:
    """读取指定日期的 observation log"""
    obs_file = obs_dir / f"{date_str}.md"
    if not obs_file.exists():
        return None
    return obs_file.read_text(encoding="utf-8")


def parse_heartbeats(content: str) -> dict:
    """解析 observation log 内容，提取 heartbeat 信息"""
    # 统计 heartbeat 出现次数（兼容 ## HH:MM Heartbeat 格式）
    heartbeat_count = len(re.findall(r"## \d{2}:\d{2} Heartbeat", content))
    
    # 统计 action-queue 处理次数
    action_queue_count = content.count("检查了 action-queue")
    
    # 提取主要活动（从 "本次心跳类型" 行）
    activity_types = re.findall(r"本次心跳类型：(.+)", content)
    
    # 提取值得记录的事项
    notable_items = []
    
    # 从 "备注" 行中提取有价值信息
    notes = re.findall(r"- 备注：(.+)", content)
    for note in notes:
        if note and note not in ["无", "无异常"]:
            notable_items.append(note)
    
    # 从 "判断结果" 中提取主动行动
    actions = re.findall(r"- 无主动行动|- 执行了[^:]+|- 回复 HEARTBEAT_OK", content)
    
    return {
        "heartbeat_count": heartbeat_count,
        "action_queue_count": action_queue_count,
        "activity_types": activity_types,
        "notable_items": notable_items,
        "actions": actions
    }


def read_recent_fragments(fragments_dir: Path, days: int = 3) -> list:
    """读取最近N天的碎片存档"""
    if not fragments_dir.exists():
        return []
    
    fragments = []
    now = datetime.now()
    for i in range(days):
        date = now - timedelta(days=i)
        frag_file = fragments_dir / f"{date.strftime('%Y-%m-%d')}.json"
        if frag_file.exists():
            try:
                # 尝试 utf-8-sig（处理 BOM），失败则用 binary 跳过 BOM 后再试
                try:
                    raw = frag_file.read_bytes()
                    # 去掉 BOM
                    if raw.startswith(b'\xef\xbb\xbf'):
                        raw = raw[3:]
                    data = json.loads(raw.decode("utf-8"))
                except UnicodeError:
                    data = json.loads(frag_file.read_text("utf-8", errors="replace"))
                for frag in data.get("fragments", []):
                    frag["_date"] = date.strftime("%m-%d")
                    fragments.append(frag)
            except (json.JSONDecodeError, KeyError):
                continue
    return fragments


def generate_summary(date_str: str, data: dict, fragments: list) -> str:
    """生成摘要报告"""
    heartbeat_count = data["heartbeat_count"]
    action_queue_count = data["action_queue_count"]
    
    # 确定主要活动
    activity_types = data["activity_types"]
    main_activity = activity_types[0] if activity_types else "日常检查"
    
    # 确定备注
    notable = data["notable_items"]
    notes = "无异常"
    if notable:
        # 取第一行简要描述
        first_note = notable[0].split("\n")[0][:50]
        if len(notable[0]) > 50:
            first_note += "..."
        notes = first_note
    
    summary_lines = [
        f"===== KAIROS autoDream — {date_str} =====",
        f"心跳次数：{heartbeat_count}",
        f"待办处理：{action_queue_count}",
        f"主要活动：{main_activity}",
        f"备注：{notes}",
    ]
    
    # 碎片部分
    if fragments:
        summary_lines.append("")
        summary_lines.append(f"📌 近期碎片灵感（{len(fragments)}条）")
        for frag in fragments[:5]:  # 最多显示5条
            date_label = frag.get("_date", "?")
            topics = " #".join(frag.get("topics", [])[:3])
            content_preview = frag.get("content", "")[:40]
            confidence = frag.get("confidence", "low")
            confidence_icon = "🔥" if confidence == "high" else "💤"
            summary_lines.append(f"[{date_label}] #{topics}")
            summary_lines.append(f"  {confidence_icon} {content_preview}...")
    
    return "\n".join(summary_lines)


def update_memory(memory_path: Path, date_str: str, data: dict, fragments: list):
    """更新 MEMORY.md 文件"""
    # 准备要追加的内容
    content_lines = [f"### {date_str}"]
    
    # 添加主要活动
    if data["activity_types"]:
        content_lines.append(f"- 主要活动：{data['activity_types'][0]}")
    
    # 添加值得记录的事项
    if data["notable_items"]:
        for item in data["notable_items"]:
            # 取前两行作为摘要
            lines = item.strip().split("\n")[:2]
            for line in lines:
                if line.strip():
                    content_lines.append(f"- {line.strip()}")
    
    # 如果没有特别的事项，添加默认记录
    if len(content_lines) == 1:
        content_lines.append(f"- 心跳次数：{data['heartbeat_count']}，待办处理：{data['action_queue_count']}")
    
    # 碎片存档部分
    if fragments:
        content_lines.append(f"- 碎片存档：{len(fragments)}条")
        # 高置信度碎片单独列出
        high_frag = [f for f in fragments if f.get("confidence") == "high"]
        if high_frag:
            topics_set = set()
            for f in high_frag:
                topics_set.update(f.get("topics", []))
            content_lines.append(f"  🔥 高置信度（{len(high_frag)}条）：#{' #'.join(list(topics_set)[:5])}")
    
    content_lines.append("")  # 空行
    
    new_content = "\n".join(content_lines)
    
    # 检查文件是否存在
    if memory_path.exists():
        existing_content = memory_path.read_text(encoding="utf-8")
        # 检查是否已经存在今天的记录
        if f"### {date_str}" in existing_content:
            return  # 已存在，跳过
        # 追加新内容
        updated_content = existing_content.rstrip() + "\n\n" + new_content
    else:
        # 创建新文件
        updated_content = f"""# KAIROS 记忆库

## KAIROS 项目进度

{new_content}
"""
    
    memory_path.write_text(updated_content, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="KAIROS 凌晨记忆整理脚本")
    parser.add_argument("--date", help="指定日期 (YYYY-MM-DD)，默认为昨天")
    args = parser.parse_args()
    
    # 确定要处理的日期
    if args.date:
        date_str = args.date
    else:
        date_str = get_yesterday_date()
    
    # 获取脚本所在目录
    script_dir = Path(__file__).parent
    obs_dir = script_dir / "observations"
    memory_path = script_dir / "MEMORY.md"
    
    # 读取 observation log
    content = read_observation_log(obs_dir, date_str)
    
    if content is None:
        print(f"昨日无记录 (observations/{date_str}.md 不存在)")
        return
    
    # 解析内容
    data = parse_heartbeats(content)
    
    # 读取近期碎片
    fragments_dir = script_dir / "fragments"
    fragments = read_recent_fragments(fragments_dir, days=3)
    
    # 生成并打印摘要
    summary = generate_summary(date_str, data, fragments)
    print(summary)
    
    # 更新 MEMORY.md
    update_memory(memory_path, date_str, data, fragments)
    
    print(f"MEMORY.md 已更新")


if __name__ == "__main__":
    main()