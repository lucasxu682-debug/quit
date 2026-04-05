"""
KAIROS CLI 入口 - 使用 argparse 解析子命令
"""
import argparse
import sys
from pathlib import Path

# Windows 终端 UTF-8 配置
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# 将 commands 目录添加到路径
sys.path.insert(0, str(Path(__file__).parent))

from commands import queue, discord, observe, status as status_cmd


def main():
    """主入口函数"""
    parser = argparse.ArgumentParser(
        description="KAIROS - 统一 CLI 入口脚本",
        prog="kairos.py"
    )
    
    # 添加子命令
    subparsers = parser.add_subparsers(dest="command", help="可用子命令")
    
    # check 子命令
    check_parser = subparsers.add_parser("check", help="检查各类服务")
    check_subparsers = check_parser.add_subparsers(dest="check_target", help="检查目标")
    
    # check queue
    check_subparsers.add_parser("queue", help="检查 action-queue 并执行待办")
    
    # check discord
    check_subparsers.add_parser("discord", help="检查 Discord 新消息")
    
    # observe 子命令
    subparsers.add_parser("observe", help="写入今日 observation log")
    
    # status 子命令
    subparsers.add_parser("status", help="显示 KAIROS 系统状态概览")
    
    # 解析参数
    args = parser.parse_args()
    
    # 执行对应的子命令
    if args.command == "check":
        if args.check_target == "queue":
            queue.main()
        elif args.check_target == "discord":
            discord.main()
        else:
            check_parser.print_help()
    elif args.command == "observe":
        observe.main()
    elif args.command == "status":
        status_cmd.main()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()