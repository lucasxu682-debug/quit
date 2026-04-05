# KAIROS Cron Job 清单

## 活跃任务

| ID | 任务 | 频率 | 状态 |
|----|------|------|------|
| `c3d71f9d` | Weekly Report 发送 | 每周一 08:00 | ✅ 已建 |
| `cb567c71` | autoDream 记忆整理 | 每天 06:00 | ✅ 已建 |
| `68208a8d` | 作业截止检查 | 每2小时 | ✅ 已建 |
| `fb5f9197` | AI 新闻存档 | 每天 08:00 | ✅ 已建 |
| `c8f6f1ad` | GitHub Trending 收藏 | 每天 09:00 | ✅ 已建 |
| `399c0bc0` | 任务进度监控 | 每3分钟 | ✅ 已建 |
| `2e71b2e9` | Weekly Audit | 每周六 09:00 | ✅ 已建 |
| （待建） | 服务器结果拉取 | 每10分钟 | 🟡 依赖腾讯云配置 |

## 已完成设置

| 任务 | 说明 |
|------|------|
| 04-08 HDDS1103 提醒 | Cron Job 已建 |
| 04-13 HDGS0306 提醒 | Cron Job 已建 |
| 04-14 HDGS0306 提醒 | Cron Job 已建 |
| 每周邮件摘要 | 每72小时执行一次 |

## Cron Job 创建命令参考

```
# autoDream — 每天 06:00 ✅
# payload.kind = agentTurn, sessionTarget = isolated

# 服务器结果拉取 — 每10分钟 🟡
# sessionTarget = isolated
# action: scp -P 22022 root@43.160.218.220:/tmp/kairos/results/*.json .
# 依赖：需先配置 SSH key 和服务器目录

# 作业截止检查 — 每2小时 ✅
# sessionTarget = isolated

# AI 新闻存档 — 每天08:00 ✅
# sessionTarget = isolated

# GitHub Trending — 每天09:00 ✅
# sessionTarget = isolated
```

---

## 执行记录

| 日期 | 任务 | 结果 | 备注 |
|------|------|------|------|
| 2026-04-03 | Phase 1 初始化 | ✅ 完成 | HEARTBEAT.md + 目录建立 |
| 2026-04-05 | 新建4个 cron jobs | ✅ 完成 | autoDream/作业检查/AI新闻/GitHub Trending |
