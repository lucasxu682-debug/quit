"""
check queue 命令：检查 action-queue 并执行待办
"""
import re
from pathlib import Path


def get_queue_path() -> Path:
    """获取 action-queue.md 文件路径"""
    base_dir = Path(__file__).parent.parent
    return base_dir / "action-queue.md"


def check_queue() -> None:
    """检查 action-queue 并打印待办事项"""
    queue_path = get_queue_path()
    
    # 读取 action-queue.md
    try:
        content = queue_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        print("队列文件不存在")
        return
    
    # 解析待办项：## [HH:MM] 待执行 | 优先级:H/M/L | 描述：...
    pattern = r"## \[(\d{2}:\d{2})\] 待执行 \| 优先级:([HML]) \| 描述：(.+)"
    matches = re.findall(pattern, content)
    
    if not matches:
        print("队列为空，无待执行项")
        return
    
    # 打印待办列表
    print("待执行项：")
    print("-" * 40)
    for time, priority, desc in matches:
        print(f"  [{time}] {desc}")
        print(f"       优先级: {priority}")
        print()
    
    print("需要手动执行")


def main(args=None):
    """命令行入口"""
    check_queue()


if __name__ == "__main__":
    main()