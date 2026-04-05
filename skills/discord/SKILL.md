---
name: discord
description: >
  Manage Discord channels and messages via OpenClaw message tool.
  Use when: (1) sending task reminders to to-do-list, (2) posting weekly reports to dream-report,
  (3) replying in project channels, (4) any Discord channel operations.
  NOT for: receiving real-time messages (use Heartbeat/Cron for that).
---

# Discord Skill

## 服务器与频道速查

| 频道名 | 用途 | Channel ID |
|--------|------|------------|
| **to-do-list** | 任务记录与状态追踪 | `1490258439220236349` |
| **dream-report** | KAIROS 自动报告/碎片通知 | `1489502600926593247` |
| **weekly-report** | 每周综合报告（周一发送） | `1489125606569541824` |
| **project** | 项目讨论 | `1489162462149349426` |
| **email** | 邮件通知汇总 | `1489233513554247831` |
| **grp-prj** | 小组项目 | `1489253444626813049` |

> Server Guild ID: `1407234849445642270`

## 消息格式规范

**Discord 不支持 markdown 表格**，使用 bullet list 替代：

```
✅ **已完成任务**
- [日期] 任务描述

⏳ **进行中**
- [日期] 任务描述 | 进度说明

🆕 **新任务**
- [日期] 任务描述 | 来源：xxx
```

状态 emoji：
- 🆕 = 新任务
- ⏳ = 进行中
- ✅ = 已完成
- ❌ = 已取消

## 常用操作

### 发送消息
```
message(action=send, channel=discord, target="ChannelID", message="内容")
```

### 编辑消息
```
message(action=edit, channel=discord, target="ChannelID", messageId="MessageID", message="新内容")
```

### 回复（Thread）
```
message(action=thread-reply, channel=discord, target="ChannelID", threadId="ThreadID", message="内容")
```

### _pin / _unpin
```
message(action=pin, channel=discord, target="ChannelID", messageId="MessageID")
```

## 频道任务分配原则

- **to-do-list** — 所有任务的增删改状态记录
- **dream-report** — 碎片存档报告、系统自动通知
- **weekly-report** — 每周一 AI 综合报告（GitHub/论文/实习/政治）
- **project** — 具体项目讨论
- **grp-prj** — 小组作业相关

## 注意

- 心跳/告警在 Discord 没有可靠的主动推送机制（待解决）
- 频道 ID 从 channel-list 获取，或从 MEMORY.md 查询
- 所有任务完成/取消/新增都应更新 to-do-list
