"""
status 命令：显示 KAIROS 系统状态概览
"""
import re
from datetime import datetime
from pathlib import Path


def get_base_dir() -> Path:
    """获取 KAIROS 根目录"""
    return Path(__file__).parent.parent


def get_queue_path() -> Path:
    """获取 action-queue.md 文件路径"""
    return get_base_dir() / "action-queue.md"


def get_observations_dir() -> Path:
    """获取 observations 目录路径"""
    return get_base_dir() / "observations"


def count_pending_items() -> int:
    """计算 action-queue 中待办数量"""
    queue_path = get_queue_path()
    
    try:
        content = queue_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return 0
    
    # 解析待办项
    pattern = r"## \[(\d{2}:\d{2})\] 待执行 \| 优先级:([HML]) \| 描述：(.+)"
    matches = re.findall(pattern, content)
    return len(matches)


def get_latest_observation_time() -> str | None:
    """获取最新 observation 文件的更新时间"""
    obs_dir = get_observations_dir()
    
    if not obs_dir.exists():
        return None
    
    # 查找最新的 observation 文件
    md_files = list(obs_dir.glob("*.md"))
    if not md_files:
        return None
    
    # 按修改时间排序
    latest_file = max(md_files, key=lambda f: f.stat().st_mtime)
    
    # 读取文件内容，获取最后的时间戳
    try:
        content = latest_file.read_text(encoding="utf-8")
        # 查找最后一个 ## HH:MM 时间戳
        timestamps = re.findall(r"## (\d{2}:\d{2})", content)
        if timestamps:
            return timestamps[-1]
    except Exception:
        pass
    
    return None


def status() -> None:
    """显示系统状态"""
    now = datetime.now()
    today = now.strftime("%Y-%m-%d")
    current_time = now.strftime("%H:%M:%S")
    
    # 待办数量
    pending_count = count_pending_items()
    
    # 最新 observation 时间
    latest_obs_time = get_latest_observation_time()
    
    # 打印状态
    print("=" * 40)
    print("KAIROS 系统状态")
    print("=" * 40)
    print(f"当前日期：{today}")
    print(f"当前时间：{current_time}")
    print("-" * 40)
    print(f"待执行项：{pending_count} 项")
    if latest_obs_time:
        print(f"最新心跳：{latest_obs_time}")
    else:
        print("最新心跳：无记录")
    print("=" * 40)


def main(args=None):
    """命令行入口"""
    status()


if __name__ == "__main__":
    main()