#!/usr/bin/env python3
"""
KAIROS 统一入口脚本

使用方法：
  python kairos.py check queue    - 检查 action-queue 并执行待办
  python kairos.py check discord - 检查 Discord 新消息
  python kairos.py observe      - 写入今日 observation log
  python kairos.py status      - 显示 KAIROS 系统状态概览
"""
import sys
from pathlib import Path

# 将当前目录添加到 Python 路径，以便导入 cli 模块
sys.path.insert(0, str(Path(__file__).parent))

import cli


def main():
    """主入口"""
    cli.main()


if __name__ == "__main__":
    main()