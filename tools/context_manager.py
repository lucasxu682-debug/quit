#!/usr/bin/env python3
"""
Project context manager for OpenClaw
Creates and maintains project documentation
"""

import argparse
import os
import json
from pathlib import Path
from datetime import datetime

PROJECT_TEMPLATE = """# {project_name}

## 项目概述
- **创建时间**: {created_at}
- **最后更新**: {updated_at}
- **状态**: {status}

## 技术栈
{tech_stack}

## 项目结构
```
{structure}
```

## 当前任务
{current_tasks}

## 待办事项
{todo_list}

## 关键决策
See [DECISIONS.md](DECISIONS.md)

## 进度跟踪
See [PROGRESS.md](PROGRESS.md)
"""

PROGRESS_TEMPLATE = """# 项目进度

## 总体进度: {progress}%

## 已完成 ✅
{completed}

## 进行中 🚧
{in_progress}

## 待开始 ⏳
{pending}

## 最近更新
{recent_updates}

---
*最后更新: {updated_at}*
"""

DECISIONS_TEMPLATE = """# 项目决策记录 (ADR)

## 决策列表

{decisions}

---
*记录格式: [日期] 决策标题 - 状态*
"""

def init_project(path=".", name=None):
    """Initialize project context files"""
    project_path = Path(path).resolve()
    project_name = name or project_path.name
    
    # Create .claude directory
    claude_dir = project_path / ".claude"
    claude_dir.mkdir(exist_ok=True)
    
    now = datetime.now().isoformat()
    
    # Create PROJECT.md
    project_file = claude_dir / "PROJECT.md"
    if not project_file.exists():
        project_file.write_text(PROJECT_TEMPLATE.format(
            project_name=project_name,
            created_at=now,
            updated_at=now,
            status="初始化中",
            tech_stack="- 待填写",
            structure="待生成",
            current_tasks="- 项目初始化",
            todo_list="- [ ] 完善项目文档\n- [ ] 设置开发环境"
        ), encoding='utf-8')
        print(f"Created: {project_file}")
    
    # Create PROGRESS.md
    progress_file = claude_dir / "PROGRESS.md"
    if not progress_file.exists():
        progress_file.write_text(PROGRESS_TEMPLATE.format(
            progress="0",
            completed="- 项目初始化",
            in_progress="- 设置开发环境",
            pending="- 核心功能开发",
            recent_updates=f"- [{now}] 项目初始化",
            updated_at=now
        ), encoding='utf-8')
        print(f"Created: {progress_file}")
    
    # Create DECISIONS.md
    decisions_file = claude_dir / "DECISIONS.md"
    if not decisions_file.exists():
        decisions_file.write_text(DECISIONS_TEMPLATE.format(
            decisions=f"### [{now[:10]}] 项目初始化 - ✅ 已采纳\n\n决定创建项目文档系统。\n\n**原因**: 提高 AI 助手效率，减少上下文重复加载。\n\n**影响**: 需要维护文档更新。"
        ), encoding='utf-8')
        print(f"Created: {decisions_file}")
    
    # Create CONTEXT directory
    context_dir = claude_dir / "CONTEXT"
    context_dir.mkdir(exist_ok=True)
    
    print(f"\n✅ Project '{project_name}' initialized!")
    print(f"📁 Location: {claude_dir}")
    print("\nNext steps:")
    print("1. Edit .claude/PROJECT.md to add tech stack")
    print("2. Run 'python context_manager.py update' after making progress")
    print("3. Use 'python context_manager.py status' to check current state")

def update_progress(path=".", task=None, status=None):
    """Update project progress"""
    progress_file = Path(path) / ".claude" / "PROGRESS.md"
    
    if not progress_file.exists():
        print("Error: Project not initialized. Run 'init' first.")
        return
    
    now = datetime.now().isoformat()
    
    # Read current content
    content = progress_file.read_text(encoding='utf-8')
    
    # Add update
    update_line = f"- [{now}] {task or '进度更新'}: {status or '进行中'}"
    
    # Insert after "最近更新"
    if "## 最近更新" in content:
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith("## 最近更新"):
                lines.insert(i + 1, update_line)
                break
        content = '\n'.join(lines)
    
    progress_file.write_text(content, encoding='utf-8')
    print(f"Updated progress: {task}")

def record_decision(path=".", title=None, decision=None, reason=None):
    """Record a project decision"""
    decisions_file = Path(path) / ".claude" / "DECISIONS.md"
    
    if not decisions_file.exists():
        print("Error: Project not initialized. Run 'init' first.")
        return
    
    now = datetime.now().isoformat()[:10]
    
    new_decision = f"\n\n### [{now}] {title or '新决策'} - ✅ 已采纳\n\n{decision or '决策内容'}\n\n**原因**: {reason or '待补充'}\n\n**影响**: 待评估"
    
    content = decisions_file.read_text(encoding='utf-8')
    content = content.replace("## 决策列表", f"## 决策列表{new_decision}")
    
    decisions_file.write_text(content, encoding='utf-8')
    print(f"Recorded decision: {title}")

def get_status(path="."):
    """Get quick project status"""
    claude_dir = Path(path) / ".claude"
    
    if not claude_dir.exists():
        print("❌ Project not initialized")
        return
    
    project_file = claude_dir / "PROJECT.md"
    progress_file = claude_dir / "PROGRESS.md"
    
    print("📊 Project Status")
    print("=" * 50)
    
    if project_file.exists():
        content = project_file.read_text(encoding='utf-8')
        # Extract basic info
        for line in content.split('\n')[:20]:
            if line.startswith('# ') or line.startswith('- **'):
                print(line)
    
    print("\n📈 Progress:")
    if progress_file.exists():
        content = progress_file.read_text(encoding='utf-8')
        for line in content.split('\n')[:30]:
            if line.startswith('## ') or line.startswith('- ') or line.startswith('总体进度'):
                print(line)

def main():
    parser = argparse.ArgumentParser(description='Project Context Manager')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Init command
    init_parser = subparsers.add_parser('init', help='Initialize project')
    init_parser.add_argument('--name', help='Project name')
    init_parser.add_argument('--path', default='.', help='Project path')
    
    # Update command
    update_parser = subparsers.add_parser('update', help='Update progress')
    update_parser.add_argument('--task', help='Task description')
    update_parser.add_argument('--status', help='Task status')
    update_parser.add_argument('--path', default='.', help='Project path')
    
    # Decision command
    decision_parser = subparsers.add_parser('decision', help='Record decision')
    decision_parser.add_argument('--title', required=True, help='Decision title')
    decision_parser.add_argument('--decision', help='Decision details')
    decision_parser.add_argument('--reason', help='Decision reason')
    decision_parser.add_argument('--path', default='.', help='Project path')
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Get project status')
    status_parser.add_argument('--path', default='.', help='Project path')
    
    args = parser.parse_args()
    
    if args.command == 'init':
        init_project(args.path, args.name)
    elif args.command == 'update':
        update_progress(args.path, args.task, args.status)
    elif args.command == 'decision':
        record_decision(args.path, args.title, args.decision, args.reason)
    elif args.command == 'status':
        get_status(args.path)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
