# KAIROS autoDream.py — 凌晨记忆整理脚本

## 任务目标

创建 `autoDream.py` 脚本，每天凌晨 06:00 自动运行，读取过去 24 小时的 observation log，生成摘要并更新 MEMORY.md。

## 文件位置

```
C:/Users/xumou/.openclaw/workspace/memory/kairos/
  autoDream.py    ← 待创建
```

## 功能要求

### 1. 读取 observation log
- 读取 `observations/YYYY-MM-DD.md`（昨天日期）
- 解析所有 heartbeat 记录块

### 2. 生成摘要
- 统计：当日 heartbeat 总次数、action-queue 处理次数
- 提取：主要活动（根据 heartbeat 类型判断）
- 识别：是否有异常或值得记录的事项

### 3. 更新 MEMORY.md
- 如果昨天有值得记录的事件，在 MEMORY.md 追加到"KAIROS 项目进度"或相关章节
- 使用以下格式：
  ```
  ### YYYY-MM-DD
  - 主要事件简述
  - 异常情况（如有）
  ```

### 4. 输出报告
- 打印简洁的摘要到终端
- 示例输出：
  ```
  ===== KAIROS autoDream — 2026-04-04 =====
  心跳次数：12
  待办处理：0
  主要活动：Phase 2 kairos.py 完成，Phase 3 Roo Code 协作框架完成
  备注：无异常
  ```

## 技术要求

- 使用 Python 标准库（argparse, pathlib, datetime, re）
- 不要安装第三方库
- 编码：文件读写使用 utf-8
- 路径使用 pathlib.Path

## 验证方式

1. 在终端执行：
   ```bash
   cd C:/Users/xumou/.openclaw/workspace/memory/kairos
   python autoDream.py
   ```
2. 检查输出是否正常
3. 检查 MEMORY.md 是否有更新

## 注意事项

- 如果昨天的 observation log 不存在，输出"昨日无记录"
- 不要修改 observation log 文件内容
- MEMORY.md 更新使用追加模式，不要重写整个文件
