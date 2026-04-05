# 碎片存档系统 v2 — 完整性 & 冲突审查

## 方案完整性检查

### 核心功能清单

| 功能 | 状态 | 实现位置 |
|------|------|---------|
| 自动判断机制（置信度分级） | ✅ 规划中 | HEARTBEAT.md |
| 碎片缓冲区（内存，per-session） | ✅ 规划中 | HEARTBEAT.md |
| heartbeat 批量存档 | ✅ 规划中 | HEARTBEAT.md |
| 碎片存档结构（含 mainContext） | ✅ 规划中 | chat-memory.ps1 |
| 来源过滤（webchat + 两人 Discord guild） | ✅ 已确认 | HEARTBEAT.md |
| 日上限 10 条 | ⚠️ 待确认 | HEARTBEAT.md |
| removefragment | ✅ 规划中 | chat-memory.ps1 |
| keepfragment | ✅ 规划中 | chat-memory.ps1 |
| 晋升机制（查看→30天） | ⚠️ 待确认 | chat-memory.ps1 |
| loadrecent（session 启动时） | ⚠️ 待确认 | chat-memory.ps1 |
| 碎片搜索（AND 匹配） | ✅ 规划中 | chat-memory.ps1 |
| 每日报告整合（dream-report） | ✅ 规划中 | autoDream.py |
| 新增碎片通知 | ⚠️ 待确认 | HEARTBEAT.md |

---

## 潜在冲突 & 风险

### 冲突 1：per-session buffer → 跨 session 写入同一文件

**问题：**
- webchat 和每个 Discord 频道是独立 session
- 每个 session 有独立的内存 buffer
- 所有 session 的碎片写同一个文件
- 两个 session 的 heartbeat 同时触发时，可能同时写文件

**分析：**
→ 文件写入本身是原子的（单文件），不会损坏
→ 但 buffer 是独立的，如果 Session A 在 buffer 了一些碎片，还没触发 heartbeat，Session B 已经触发并写入了——Session A 的 buffer 还没清空，会在下次 heartbeat 才写入
→ 这不是 bug，是设计如此（心跳是独立的）

**结论：可接受，无需修改**

---

### 冲突 2：cleanup 和 buffer flush 的执行顺序

**问题：**
如果顺序是：1. cleanup（清 7 天前）→ 2. buffer flush（新碎片写入）
新写入的碎片可能只比 7 天前的碎片新几分钟，但 7 天前的那批已经被清了

**分析：**
→ 这种情况极少发生（需要恰好在 7 天 0 分钟这个临界点）
→ 而且被清的是"刚好 7 天前"的碎片，价值已经很低
→ cleanup 加 `lastCleanupDate` 检查，每天最多一次，所以不会频繁发生

**结论：可接受，无需修改（执行顺序：flush 先，cleanup 后）**

---

### 冲突 3：日上限 10 条可能导致有价值碎片被静默丢弃

**问题：**
- 高置信度碎片已经存了 10 条，低置信度的碎片就不存了
- 但用户可能觉得某条低置信度的其实很重要

**建议优化：**
- 可以在 heartbeat 通知时说："今天已达上限（10 条），以下碎片未保存：[...]"——让用户决定要不要晋升
- 或者用户主动说"这条很重要，存一下"，可以绕过日上限（单次晋升）

**建议：加一个绕过日上限的机制（用户主动触发）**

---

### 冲突 4：loadrecent 加载量不明确

**问题：**
3 天内的碎片可能有几十条，全部加载会占用大量 context

**建议：**
- 加载时只取最新的 **5 条摘要**（topics + 首句 + 时间），不加载完整 content
- 如果用户主动搜索，再加载完整内容
- 或者加参数控制：`loadrecent -Limit 5`

**建议：loadrecent 默认返回最新 5 条，并标注总数（"共 X 条，可搜索查看详情"）**

---

### 冲突 5：mainContext 的内容质量不稳定

**问题：**
"当时主要任务停在哪里"——我怎么判断？靠我自己的理解，可能不准确

**建议：**
- 存 "topic"（当前话题的关键词）就够了，不强求完整句子
- 或者简化为："当时在聊：毛囊炎补剂方案 → 突然问：新加坡服务器"
- 让上下文更结构化，不要自由文本

**建议：mainContext 改为结构化格式："话题A → 话题B（碎片触发点）"**

---

### 冲突 6：removefragment / keepfragment 的作用范围

**问题：**
- 在 Discord 说了"删掉这个碎片"，作用范围是整个共享文件，还是只当前 session？
- 如果碎片刚被 buffer 还没写入文件，removefragment 能删掉吗？

**建议：**
- removefragment / keepfragment 操作**整个共享文件**，不区分 session
- 如果碎片在 buffer 里还没写入，先 flush 再操作
- 或者提示："该碎片尚未保存到文件"

**建议：操作范围是全局，buffer 内的碎片先 flush 再操作**

---

### 冲突 7：碎片通知的时机

**问题：**
- heartbeat 时批量存档 + 通知，打断了对话节奏
- 但不通知的话，用户不知道存了什么

**建议：**
- 通知可以延迟到**下次用户主动发消息时**顺便说（"今天新增了 3 条碎片，摘要：[...]"）
- 这样不打断当前对话，但用户下次来还能看到
- 或者：如果 heartbeat 时检测到"最近一条用户消息距离现在 < 5 分钟"，说明用户还在聊，此时不通知，等消息间隔超过 5 分钟再通知

**建议：heartbeat 时不立即通知，改为"下次用户发消息时顺便展示"**

---

## 优化建议汇总

| # | 优化点 | 优先级 | 理由 |
|---|--------|--------|------|
| 1 | 碎片通知延迟到下次用户发消息时 | 高 | 不打断对话节奏 |
| 2 | 存碎片时告知用户（"已存档此碎片"） | 低 | 本来就是静默的 |
| 3 | 日上限 10 条，但用户可主动触发绕过 | 中 | 防止意外丢弃高价值内容 |
| 4 | loadrecent 默认返回最新 5 条 + 总数 | 高 | 避免 context 膨胀 |
| 5 | mainContext 改为结构化格式 | 中 | 质量更稳定，不依赖 AI 自由文本 |
| 6 | removefragment / keepfragment 作用于全局，buffer 内的先 flush | 中 | 行为更可预测 |
| 7 | 日志：记录"哪些碎片被保留/删除/晋升" | 低 | 方便排查问题 |

---

## 审查结论

**整体方案可行性：✅ 通过**

所有冲突都有明确的解决方案或属于可接受风险，没有根本性的架构矛盾。

**需要在上线前确认的 5 个问题：**
1. 碎片通知改成"下次发消息时顺便展示"——你同意吗？
2. mainContext 用结构化格式还是自由文本？
3. 日上限 10 条 + 主动触发绕过机制——要加吗？
4. loadrecent 默认 5 条——够用吗？
5. removefragment 时 buffer 内的碎片先 flush 再删——可以吗？

---

## 实现优先级（建议）

**Phase 1（核心必做）：**
1. chat-memory.ps1：碎片存取搜（savefragment / searchfragments / loadrecent / cleanupfragments）
2. HEARTBEAT.md：碎片自动判断 + 缓冲区 + 批量存档 + 清理逻辑
3. autoDream.py：碎片读入每日报告

**Phase 2（体验优化，上线后择机做）：**
1. 碎片通知改为延迟展示
2. 结构化 mainContext
3. 日上限绕过机制
