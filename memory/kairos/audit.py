#!/usr/bin/env python3
"""
KAIROS Weekly Audit — 每周全面检查脚本
运行后生成检查报告，保存到 audits/ 并发送到 Discord to-do-list
"""

import subprocess
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timedelta

WORKSPACE = Path("C:/Users/xumou/.openclaw/workspace")
AUDITS_DIR = WORKSPACE / "memory/kairos/audits"
MEMORY_FILE = WORKSPACE / "MEMORY.md"
KAIROS_DIR = WORKSPACE / "memory/kairos"


def run(cmd: str) -> tuple[str, int]:
    """执行 shell 命令，返回 (stdout, returncode)"""
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True,
        encoding="utf-8", errors="replace", cwd=WORKSPACE
    )
    return (result.stdout or "").strip(), result.returncode


def heading(text: str) -> str:
    return f"\n{'='*40}\n{text}\n{'='*40}"


def section(text: str) -> str:
    return f"\n## {text}"


def check_git() -> str:
    """检查 Git 状态"""
    lines = []
    _, rc1 = run("git status --porcelain")
    unpushed, _ = run("git log origin/master..HEAD --oneline")
    uncommitted = unpushed.count("\n") + 1 if unpushed else 0

    # 最近7天 commits
    week_commits, _ = run('git log --since="7 days ago" --oneline')
    week_count = week_commits.count("\n") + 1 if week_commits else 0

    status = "✅ 正常" if rc1 == 0 and uncommitted == 0 else f"⚠️ 有{uncommitted}个未提交改动"

    lines.append(f"- Git 状态: {status}")
    lines.append(f"- 未推送 commits: {uncommitted} 个")
    lines.append(f"- 最近7天 commits: {week_count} 条")

    return "\n".join(lines)


def check_files() -> str:
    """检查文件问题"""
    lines = []
    issues = []

    # temp 文件
    for pattern in ["temp_", "tmp_", "*.tmp", "test_*.py"]:
        out, _ = run(f'Get-ChildItem -Path "{WORKSPACE}" -Recurse -Filter "{pattern}" -File -ErrorAction SilentlyContinue | Select-Object -First 3 FullName')
        if out:
            files = [f for f in out.split("\n") if f.strip()]
            for f in files:
                if "_pycache_" not in f and ".pyc" not in f:
                    issues.append(f"  ⚠️ 临时文件: {Path(f).name}")

    # 大文件 (>10MB)
    out, _ = run(f'Get-ChildItem -Path "{WORKSPACE}" -Recurse -File -ErrorAction SilentlyContinue | Where-Object {{ $_.Length -gt 10MB }} | Select-Object -First 5 FullName, Length')
    if out:
        for f in out.split("\n"):
            if f.strip():
                issues.append(f"  ⚠️ 大文件: {f.strip()}")

    # 过时 fragments-plan 文件
    old_files = [
        KAIROS_DIR / "fragments-plan.md",
    ]
    for f in old_files:
        if f.exists():
            issues.append(f"  ⚠️ 过时文档: {f.name} (已废弃，应删除)")

    if issues:
        lines.append(f"- 发现 {len(issues)} 个问题:")
        lines.extend(issues)
    else:
        lines.append("- ✅ 无异常文件")

    return "\n".join(lines)


def check_kairos() -> str:
    """检查 KAIROS 状态"""
    lines = []
    issues = []

    # progress.json 状态
    progress_file = KAIROS_DIR / "progress.json"
    if progress_file.exists():
        data = json.loads(progress_file.read_text(encoding="utf-8", errors="replace"))
        if data.get("status") == "running":
            updated = data.get("lastUpdated", "")
            issues.append(f"  🔴 progress.json 状态为 running（{updated}，可能是任务卡住）")
        elif data.get("alertSent") == True:
            issues.append(f"  🟡 上次告警已发送，alertSent 未重置")

    # action-queue 积压（忽略注释行）
    aq_file = KAIROS_DIR / "action-queue.md"
    if aq_file.exists():
        content = aq_file.read_text(encoding="utf-8", errors="replace")
        lines = [l for l in content.split("\n") if l.strip() and not l.strip().startswith("#") and not l.strip().startswith("<!--")]
        if lines:
            issues.append(f"  🟡 action-queue 有 {len(lines)} 条待处理内容")

    # fragments 更新（刚建系统时目录可能为空，不是问题）
    frag_dir = KAIROS_DIR / "fragments"
    if frag_dir.exists():
        files = list(frag_dir.glob("*.json"))
        if files:
            newest = max(f.stat().st_mtime for f in files)
            days_ago = (datetime.now() - datetime.fromtimestamp(newest)).days
            if days_ago > 30:
                issues.append(f"  🟡 碎片存档 {days_ago} 天未更新")

    if issues:
        lines.append(f"- 发现 {len(issues)} 个问题:")
        lines.extend(issues)
    else:
        lines.append("- ✅ KAIROS 状态正常")

    return "\n".join(lines)


def check_crons() -> str:
    """检查 Cron Jobs 状态（读取 OpenClaw cron state 文件）"""
    # cron 状态从 gateway config 或 job runs 读取
    # 这里只做基础检查
    lines = []
    lines.append("- 请在 OpenClaw 控制台查看 cron jobs 详细状态")
    lines.append("- 关注: consecutiveErrors > 0 的 jobs")
    lines.append("- 关注: 从未运行过的 jobs（可能是 payload 语法问题）")
    return "\n".join(lines)


def check_academic() -> str:
    """检查学业截止"""
    lines = []
    # 读取 weekly_schedule
    sched_file = WORKSPACE / "memory/weekly_schedule.md"
    issues = []

    if sched_file.exists():
        content = sched_file.read_text(encoding="utf-8", errors="replace")
        today = datetime.now()
        week_end = today + timedelta(days=7)

        # 简单正则找日期
        import re
        date_pattern = re.findall(r'\d{4}-\d{2}-\d{2}', content)
        for dp in date_pattern:
            try:
                d = datetime.strptime(dp, "%Y-%m-%d")
                days_to = (d - today).days
                if 0 < days_to <= 7:
                    issues.append(f"  🟡 {dp} 有截止任务（{days_to}天后）")
            except:
                pass

    if issues:
        lines.append(f"- 最近7天有 {len(issues)} 个截止:")
        lines.extend(issues)
    else:
        lines.append("- ✅ 最近7天无作业截止")
    return "\n".join(lines)


def check_memory() -> str:
    """检查 MEMORY.md 状态"""
    lines = []
    issues = []

    if MEMORY_FILE.exists():
        content = MEMORY_FILE.read_text(encoding="utf-8", errors="replace")

        # 检查过时日期引用（如 2025 年）
        import re
        old_dates = re.findall(r'202[0-4]-\d{2}-\d{2}', content)
        if old_dates:
            issues.append(f"  🟡 MEMORY.md 存在 2020-2024 年日期（可能是过时内容）")

        # 检查 TODO/FIXME
        if "TODO" in content or "FIXME" in content:
            issues.append(f"  🟡 MEMORY.md 存在 TODO/FIXME 标记")

    if issues:
        lines.append(f"- 发现 {len(issues)} 个问题:")
        lines.extend(issues)
    else:
        lines.append("- ✅ MEMORY.md 状态正常")
    return "\n".join(lines)


def determine_level(issues: list[str]) -> tuple[str, str]:
    """根据问题数量和类型判断严重程度"""
    critical = any("🔴" in i for i in issues)
    attention = any("🟡" in i for i in issues)

    if critical:
        return "🔴 Critical", "需要立即处理！"
    elif attention:
        return "🟡 Attention", "应该尽快处理"
    else:
        return "🟢 Normal", "一切正常"


def main():
    sys.stdout.reconfigure(encoding='utf-8')

    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    report_date = now.strftime("%Y年%m月%d日 %H:%M")

    report = []
    report.append(f"# KAIROS Weekly Audit — {report_date}")
    report.append("")

    all_issues = []

    # 1. Git
    report.append(section("Git 状态"))
    git_info = check_git()
    report.append(git_info)
    if "⚠️" in git_info:
        all_issues.extend([l for l in git_info.split("\n") if "⚠️" in l])

    # 2. 文件
    report.append(section("文件检查"))
    file_info = check_files()
    report.append(file_info)
    if "⚠️" in file_info or "🟡" in file_info:
        all_issues.extend([l for l in file_info.split("\n") if "⚠️" in l or "🟡" in l])

    # 3. KAIROS
    report.append(section("KAIROS 状态"))
    kairos_info = check_kairos()
    report.append(kairos_info)
    if "🔴" in kairos_info or "🟡" in kairos_info:
        all_issues.extend([l for l in kairos_info.split("\n") if "🔴" in l or "🟡" in l])

    # 4. Cron
    report.append(section("Cron Jobs"))
    cron_info = check_crons()
    report.append(cron_info)

    # 5. 学业
    report.append(section("学业截止"))
    acad_info = check_academic()
    report.append(acad_info)
    if "🟡" in acad_info:
        all_issues.extend([l for l in acad_info.split("\n") if "🟡" in l])

    # 6. MEMORY
    report.append(section("MEMORY.md"))
    mem_info = check_memory()
    report.append(mem_info)
    if "🟡" in mem_info:
        all_issues.extend([l for l in mem_info.split("\n") if "🟡" in l])

    # 总结
    report.append("")
    level, level_desc = determine_level(all_issues)
    report.append(f"**严重程度: {level}** — {level_desc}")

    report_text = "\n".join(report)

    # 保存到 audits/
    audit_file = AUDITS_DIR / f"{date_str}.md"
    audit_file.write_text(report_text, encoding="utf-8")

    print(report_text)
    print(f"\n[audit] 报告已保存到 {audit_file}")

    # 构建 Discord 摘要
    issue_count = len(all_issues)
    summary = f"📊 **KAIROS Weekly Audit — {date_str}**\n"
    summary += f"严重程度: {level}\n"

    if issue_count > 0:
        summary += f"发现 {issue_count} 个问题，详见 audits/{date_str}.md"
    else:
        summary += "一切正常，无问题发现"

    print(f"\n[audit] Discord 摘要:\n{summary}")


if __name__ == "__main__":
    main()
