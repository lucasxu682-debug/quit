# KAIROS Cron Job 清单
# 所有定时任务在此记录，由 OpenClaw Gateway 管理

## 活跃任务

| ID | 任务 | 频率 | 下次执行 | 状态 |
|----|------|------|---------|------|
| （待创建） | autoDream 记忆整理 | 每天 06:00 | — | 待创建 |
| （待创建） | 服务器结果拉取 | 每10分钟 | — | 待创建 |
| （待创建） | 作业截止检查 | 每2小时 | — | 待创建 |
| （待创建） | AI 新闻存档 | 每天08:00 | — | 待创建 |
| （待创建） | GitHub Trending 收藏 | 每天09:00 | — | 待创建 |

## 已完成设置

| 任务 | 说明 |
|------|------|
| 04-08 HDDS1103 提醒 | Cron Job 已建 |
| 04-13 HDGS0306 提醒 | Cron Job 已建 |
| 04-14 HDGS0306 提醒 | Cron Job 已建 |
| 每周邮件摘要 | 每72小时执行一次 |

## Cron Job 创建命令参考

```
# autoDream — 每天 06:00
# payload.kind = agentTurn, sessionTarget = isolated

# 服务器结果拉取 — 每10分钟
# sessionTarget = isolated
# action: scp -P 22022 root@43.160.218.220:/tmp/kairos/results/*.json .

# 作业截止检查 — 每2小时
# sessionTarget = isolated

# AI 新闻存档 — 每天08:00
# sessionTarget = isolated

# GitHub Trending — 每天09:00
# sessionTarget = isolated
```

---

## 执行记录

| 日期 | 任务 | 结果 | 备注 |
|------|------|------|------|
| 2026-04-03 | Phase 1 初始化 | ✅ 完成 | HEARTBEAT.md + 目录建立 |
