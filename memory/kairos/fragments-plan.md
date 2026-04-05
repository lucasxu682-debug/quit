# 规则：方案完成标准

**核心原则：在完成所有方案的设立、优化和整合之前，不能开始方案的进行。**

适用于所有任务和项目。

---

## 碎片存档系统 — 方案状态：规划中（未开始）

### 已解决：Session 架构分析

**Session key 规则：**
- `agent:main:main` → webchat
- `agent:main:discord:channel:xxxxx` → 每个 Discord 频道独立 session
- 同一个 AI 的所有 session **共享** `memory/conversations/fragments/` 存档文件

**关键发现：碎片存档是文件级的，不是 session 级的。**
无论哪个 session 调用 `savefragment`，都写进同一个文件夹。webchat 和 Discord 的碎片天然互通。

**Heartbeat 是 per-session 的：** 每个 session（包括 Discord 各频道）各自触发自己的 heartbeat。所以碎片缓冲区的保存和清理是各自独立的，但因为都写同一个文件，所以碎片内容是共享的。

---

### 来源过滤逻辑（重新设计）

| session key | 类型 | 存碎片？ |
|-------------|------|---------|
| `agent:main:main` | webchat | ✅ |
| `agent:main:discord:channel:xxxxx` | Discord 频道 | ⚠️ 按 guild 成员数判断 |
| `agent:main:discord:dmid:xxxxx` | Discord 私聊 | ✅ |

Discord 频道是否存碎片：
1. 从 session key 提取 `channel:xxxxx`
2. 查 sessions.json 中该 channel 的 `space`（guild ID = `1407234849445642270`）
3. **Lucas 确认：该 guild 只有他和 AI 两人，且未来也不会有其他人**
4. **结论：该 guild 下所有频道均视为 main session → 存碎片**

**已知 Discord 频道（guild `1407234849445642270`，仅 2 人）：**
- #常规 (1407234849445642273) ✅ 存碎片
- #project (1489162462149349426) ✅ 存碎片
- #email (1489233513554247831) ✅ 存碎片
- #grp-prj (1489253444626813049) ✅ 存碎片

---

### 待解决问题

~~1. 确认 guild `1407234849445642270` 的成员数~~ ✅ 已确认：仅 2 人
2. **碎片系统 v2 完整方案待 Lucas 最终确认**
3. embedding 修复（QMD 后端切换）待执行（Lucas 延后）

### 碎片系统方案 v2（整合版）

待完整方案确认后才能开始实现。

---

## 其他待解决问题

（此文件记录所有尚未完成的方案规划）
