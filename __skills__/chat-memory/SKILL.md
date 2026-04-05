# chat-memory
# triggers: 自动触发 / session start / 对话记录 / memory / 记忆 / 保存对话

自动保存和加载聊天记录，作为长期记忆的补充。

## 功能

1. **保存时自动清理** — save 会先清理超过 30 天的旧文件，再写入
2. **新对话开始时** — 读取近 30 天所有对话摘要
3. **详细模式** — 可选显示 topics 和 decisions

## 文件结构

```
memory/
  conversations/
    YYYY-MM-DD.json     # 每日对话记录
```

## 对话记录格式

```json
{
  "lastUpdated": "2026-04-01 13:00",
  "entries": [
    {
      "timestamp": "2026-04-01 10:31",
      "summary": "一句话总结今天做了什么",
      "topics": ["主题1", "主题2"],
      "decisions": ["结论1", "结论2"],
      "filesModified": ["file1.md"],
      "model": "mini-max/M2"
    }
  ]
}
```

## 触发时机

- **对话结束时**：超过 10 轮或用户明确结束 → 保存
- **新对话开始时**：自动读取近 30 天所有对话
- **清理**：save 时自动触发，删除超期文件

## 命令行用法

```powershell
# 读取（默认：只显示摘要）
powershell -File chat-memory.ps1 -Action load

# 读取（详细：显示 topics 和 decisions）
powershell -File chat-memory.ps1 -Action load -Verbose true

# 保存（自动触发清理）
powershell -File chat-memory.ps1 -Action save `
  -Summary "..." `
  -Topics "topic1,topic2" `
  -Decisions "decision1" `
  -FilesModified "file1.md"

# 手动清理
powershell -File chat-memory.ps1 -Action cleanup
```

## AGENTS.md 集成

Session Startup 第 4 步改为：

```
powershell -File memory/conversations/chat-memory.ps1 -Action load
```

## 可配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `MaxAgeDays` | 30 | 保留天数 |
| `ConvDir` | `$PWD/memory/conversations` | 存档目录 |

## 碎片存档系统（Fragment System）

对话过程中自动存档有价值想法，不依赖用户主动触发。

### 碎片存档流程

```
Save-Fragment → fragments-buffer.json（内存缓冲）
                        ↓
         heartbeat 时 flushfragments
                        ↓
         批量写入 fragments/YYYY-MM-DD.json（正式存档）
```

### 置信度分级

| 置信度 | 信号 | 示例 |
|--------|------|------|
| high | 问基础关键问题 / 表达自我理解 / 连续追问2次以上 | "什么叫 context window？" |
| low | 正常延伸对话 / 顺嘴提新方向 | "对了能不能用在xxx上？" |

### 碎片函数命令

```powershell
# 保存碎片（写入 buffer）
powershell -File chat-memory.ps1 -Action savefragment `
  -Content "碎片内容" `
  -Topics "topic1,topic2" `
  -Confidence "high" `
  -MainContext "当前讨论话题"

# 搜索碎片
powershell -File chat-memory.ps1 -Action searchfragments -Query "关键词"

# 加载近期碎片
powershell -File chat-memory.ps1 -Action loadrecent -Limit 10

# 清理过期碎片（超过30天）
powershell -File chat-memory.ps1 -Action cleanupfragments

# 强制将 buffer flush 到存档（通常由 heartbeat 自动触发）
powershell -File chat-memory.ps1 -Action flushfragments

# 保留某个碎片（promote = true）
powershell -File chat-memory.ps1 -Action keepfragment -Query "关键词"

# 删除某个碎片
powershell -File chat-memory.ps1 -Action removefragment -Query "关键词"
```

### 碎片通知规则（HEARTBEAT.md Step 5）

- 有新碎片（lastFragmentTime 更新）+ 距用户上一条消息 > 5 分钟 → 展示通知
- 当天碎片数量 ≤ 10 条（防止刷屏）
- 高置信度优先通知

### 文件位置

| 文件 | 路径 |
|------|------|
| Buffer | `memory/kairos/fragments-buffer.json` |
| 存档 | `memory/kairos/fragments/YYYY-MM-DD.json` |
| 进度文件 | `memory/kairos/progress.json` |
