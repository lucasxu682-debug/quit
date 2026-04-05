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
| **hk-stock** | 港股每日追踪（持仓盈亏+大盘） | `1500327713228550276` |
| **常规** | 综合杂谈 | `1407234849445642273` |

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

## 频道详情备忘

### email 频道
- `calendar@hkbu.edu.hk` 的每日 today 邮件会被**自动屏蔽**
- 重要邮件会附上简短分析和建议
- 由 cron job（每72小时）触发，bot 用户名：`OpenClaw Email Summary`

### grp-prj 频道
**当前活跃项目：HDDS1502 统计小组项目**
- 截止：2026-04-09（占比 35%）
- 任务：MTR (0066.HK) vs Tracker Fund (2800.HK) — 描述性统计 + 相关系数 + 线性回归
- 组员：Ho Yu Ting / Au Hasting / Chan Pak Hei / Lucas

## 注意

- 心跳/告警在 Discord 没有可靠的主动推送机制（待解决）
- 频道 ID 从 channel-list 获取，或从 MEMORY.md 查询
- 所有任务完成/取消/新增都应更新 to-do-list

## deliveryStatus 状态说明

cron job 的 `deliveryStatus: unknown` **不代表 Discord 消息发送失败**。这是 OpenClaw 内部报告字段，表示"向 cron 系统本身报告的状态未知"。实际消息是否送达应以 Discord 频道里是否出现为准。

**判断消息是否真正发出的方法：去对应频道查看，不要依赖 deliveryStatus 字段。**
