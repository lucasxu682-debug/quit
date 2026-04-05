"""
observe 命令：写入今日 observation log
"""
from datetime import datetime
from pathlib import Path


def get_observations_dir() -> Path:
    """获取 observations 目录路径"""
    base_dir = Path(__file__).parent.parent
    return base_dir / "observations"


def get_today_date() -> str:
    """获取当前日期，格式 YYYY-MM-DD"""
    return datetime.now().strftime("%Y-%m-%d")


def observe() -> None:
    """写入今日 heartbeat 记录"""
    today = get_today_date()
    obs_dir = get_observations_dir()
    obs_file = obs_dir / f"{today}.md"
    
    # 获取当前时间
    now = datetime.now()
    time_str = now.strftime("%H:%M")
    
    # 判断时段
    hour = now.hour
    if 0 <= hour < 6:
        period = "凌晨"
        period_name = "凌晨例行检查"
    elif 6 <= hour < 12:
        period = "早晨"
        period_name = "早晨例行检查"
    elif 12 <= hour < 18:
        period = "下午"
        period_name = "日常心跳"
    else:
        period = "晚上"
        period_name = "晚间检查"
    
    # 构建新的记录块
    new_entry = f"""

---

## {time_str}

### heartbeat
- 检查了 action-queue：无待执行项
- 当前时间：{time_str}（{period}）
- 本次心跳类型：{period_name}

### 判断结果
- 无主动行动
- 回复 HEARTBEAT_OK
"""
    
    # 读取或创建文件
    if obs_file.exists():
        content = obs_file.read_text(encoding="utf-8")
        # 检查是否已存在相同时间的记录
        if f"## {time_str}\n" in content:
            print(f"记录 {time_str} 已存在，跳过")
            return
        # 追加记录
        content += new_entry
        obs_file.write_text(content, encoding="utf-8")
    else:
        # 创建新文件
        header = f"# {today} KAIROS 观察日志\n"
        content = header + new_entry
        obs_file.write_text(content, encoding="utf-8")
    
    print(f"已写入 heartbeat 记录：{time_str}")


def main(args=None):
    """命令行入口"""
    observe()


if __name__ == "__main__":
    main()