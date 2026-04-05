# KAIROS Proactive Loop — Heartbeat Tick Prompt
# 每次收到消息时，OpenClaw 读取此文件执行判断
# 判断要快（<5秒），无事回复 HEARTBEAT_OK

## 判断逻辑

### 1. action-queue 检查
读取 `memory/kairos/action-queue.md`（如果存在）

- 有待执行项 → 执行 → 从队列中删除该条 → 记录到当日 observation log → **直接响应，不走 Step 4**
- 无 → 继续 Step 2

---

### 2. observation log 写入
检查 `memory/kairos/observations/YYYY-MM-DD.md` 是否存在

- 不存在 → 创建文件，写入 `## HH:MM` 时间戳
- 存在 → 追加本次心跳记录

格式：
```
## HH:MM Heartbeat

- action-queue：有无
- 本次心跳类型：首次/日常
- Discord 新消息：检查结果（未配置则写"未配置"）
- 判断结果：描述
- 备注：可选补充说明
```

---

### 3. Discord 新消息（如已配置 channel）
检查 dream-report 或指定频道是否有需要回复的消息

- 有（如被直接提及）→ 生成回复
- 无 → 继续 Step 4

---

### 4. 主动行动决策
仅在 Step 1 无任务时执行

- 综合 Step 2/3 结果
- 有值得做的事 → 写入 `memory/kairos/action-queue.md`
  - 格式：`## [HH:MM] 待执行 | 优先级:H | 描述：...`
- 无 → 继续 Step 5

---

### 5. 碎片存档处理（Fragments）
仅在 Step 1 无任务时执行

**5a. 碎片缓冲区 Flush**
- 检查 `memory/kairos/fragments-buffer.json` 是否存在且非空
- 存在 → 调用 `chat-memory.ps1 -Action flushfragments`，将 buffer 批量写入存档
- buffer 清空

**5b. 碎片通知判断**
- 检查 `memory/kairos/fragments-notify.json`
  - 读取 `lastFragmentTime` 和 `lastUserTime`
- 满足以下全部条件时，在回复末尾附加碎片通知：
  - 有新碎片（`lastFragmentTime` > `lastNotifyTime`，且 `lastNotifyTime` 非空）
  - 距用户上一条消息已超过 5 分钟（`now - lastUserTime` > 5min）
  - 当天碎片数量 ≤ 10 条（防止刷屏）
- 通知格式：`📬 近期碎片（X条）：[topic1] [topic2]...`
- 更新 `lastNotifyTime` = `now`

**5c. 最终回复**
- 综合以上所有步骤结果决定是否回复 HEARTBEAT_OK

---

## 定期任务（不在此文件）
所有定时任务（Cron Jobs）另见：
`memory/kairos/cron-schedule.md`

常见定期任务：
- autoDream 记忆整理 — 每天 06:00
- 服务器结果拉取 — 每10分钟
- 作业截止检查 — 每2小时
- AI 新闻存档 — 每天08:00
- GitHub Trending 收藏 — 每天09:00

---

## 注意
- 此文件是 OpenClaw Heartbeat 的判断逻辑，不是执行逻辑
- 执行逻辑（Cron Jobs）不放在 Heartbeat 里，避免拖慢心跳速度
