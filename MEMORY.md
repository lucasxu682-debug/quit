# MEMORY.md — 长期记忆

## Lucas 基本信息
- 18岁，男生，香港浸会大学持续教育学院数据科学高级文凭在读
- 雅思 6 分，代码零基础
- 执行力自评较差，记忆力短期为主
- 实习偏好：广东/香港，技术类，不挑规模

## 核心项目：KAIROS

### 项目目标
为 Lucas 打造主动式 AI 助手框架，减少手动触发任务

### 当前进度（2026-04-05 Phase 1 全部完成）

**Phase 1.1 ✅ HEARTBEAT.md 命令式改造**
- 从顺序清单改为模块化独立判断
- Step 1 有任务 → 直接响应，不走 Step 4
- 定期任务与 heartbeat 分离

**Phase 1.2 ✅ 碎片存档系统 v2（Fragment System）**
- HEARTBEAT.md：碎片缓冲区 + 批量存档 + 通知延迟逻辑（Step 5）
- chat-memory.ps1：Save-Fragment 改写 buffer，flushfragments 批量落盘
- autoDream.py：每日摘要自动读取最近3天碎片并写入 MEMORY.md

**Phase 2 ✅ kairos.py CLI 入口**
- 路径：`C:/Users/xumou/.openclaw/workspace/memory/kairos/`
- 子命令：`status`, `check queue`, `check discord`, `observe`
- cli.py 已加 `sys.stdout.reconfigure(encoding='utf-8')` 解决中文乱码

**Phase 3 ✅ Roo Code 协作框架**
- "kr" 指令已配置给 Roo Code
- 触发：Lucas 对 Roo Code 说"kr"
- Roo Code 读取 task.md → 执行 → 结果写入 results/YYYY-MM-DD-task-name.md

### 目录结构
```
kairos/
  kairos.py          ← CLI 入口
  cli.py             ← argparse 解析
  commands/          ← 子命令模块
    queue.py
    discord.py
    observe.py
    status.py
  task.md            ← 当前任务
  results/           ← Roo Code 执行结果
  observations/      ← 每日心跳日志
  action-queue.md    ← 待执行队列
  cron-schedule.md   ← 定时任务清单
```

## 健康档案

### 既往病史
- 过敏性鼻炎（曾服开瑞坦，已停药一年以上）
- 细菌性毛囊炎（五年，从局部蔓延至全身：手臂、背部、臀部、大腿）
- 18岁脱发焦虑

### 身体数据
- 178cm / 62kg，BMI ≈ 19.6
- 偏瘦，肌肉量不足，吸收可能有问题

### 补剂现状
- VORSE 姜黄素 300mg ✅
- FoYes 复合维B族 ⚠️（成分普通，无活性叶酸）
- Now D3 2000IU + Jamieson D3 1000IU → 重复，需停一个
- 哈药金盖（钙镁D+K）✅
- 葡萄糖酸镁 100mg ✅
- **完全缺失：Omega-3（鱼油）、膳食纤维**

### 营养缺口优先级
1. 🥇 Omega-3（鱼油）— 抗炎，Top 1
2. 🥈 膳食纤维 — 肠-皮轴修复
3. 🥉 槲皮素 — 天然抗组胺

### 生活方式
- 久坐电脑前
- 几乎不吃蔬菜
- 每天 1500ml 白开水，不喝含糖饮料
- 不规律熬夜
- 竞技 FPS 玩家

## 技术偏好
- 跨渠道比价（拼多多/京东/屈臣氏/iHerb）
- 代码零基础，需要逐段解释
- 喜欢简短、多角度、多层次回答
- 概念词需附中文释义

## Discord 推送计划
每周一综合报告，框架：
1. GitHub AI Top 10
2. arXiv 热门 AI 论文 3-5篇
3. Hugging Face 热门模型
4. AI 行业融资与产品动态
5. Kaggle 竞赛动态
6. AI 开源工具更新
7. 政治格局分析
8. 实习信息（广州/深圳/香港）

感兴趣项目记录在：`memory/interested-ai-projects.md`

## 碎片存档系统 v2（Fragment System）

### 核心设计
- 对话中自动存档有价值想法，不依赖用户主动触发
- 通过置信度分级决定是否存档

### 置信度分级
| 置信度 | 信号 | 示例 |
|--------|------|------|
| high | 问基础关键问题 / 表达自我理解 / 连续追问2次以上 | "什么叫 context window？" |
| low | 正常延伸对话 / 顺嘴提新方向 | "对了能不能用在xxx上？" |

### 存档流程
1. `Save-Fragment` → 写入 buffer（`memory/kairos/fragments-buffer.json`）
2. Heartbeat 时 `flushfragments` → 批量写入 archive（`memory/kairos/fragments/YYYY-MM-DD.json`）
3. 下次用户发消息时展示碎片通知

### 关键文件
- Buffer：`memory/kairos/fragments-buffer.json`
- 存档：`memory/kairos/fragments/YYYY-MM-DD.json`
- 脚本：`memory/conversations/chat-memory.ps1`

### 已实现函数
savefragment / searchfragments / loadrecent / cleanupfragments / removefragment / keepfragment / flushfragments

### 通知规则
- 有新碎片 + 距用户上一条消息 > 5分钟 → 展示通知
- 日上限：10条，高置信度优先

### 待完成
- autoDream.py 整合碎片到每日报告 ✅（2026-04-05）

### autoDream.py 碎片整合
- 每日凌晨生成摘要时，自动读取最近3天碎片存档
- MEMORY.md 更新时追加碎片统计（总条数 + 高置信度 topic 列表）
- 摘要输出包含最近5条碎片预览（topics + 内容节选）

## Discord To-Do-List 频道
- 频道名：to-do-list
- 频道 ID：1490258439220236349
- 用途：所有任务的永久记录，包括已完成/待处理/已取消
- 格式：🆕 + 描述 + 来源 + 状态 + 备注
- 状态：✅ Done / ⏳ Pending / ❌ Cancelled
- 原则：任何任务都要留一条记录在 to-do-list

## 任务进度监控系统
- 进度文件：memory/kairos/progress.json
- Cron Job：每3分钟检查一次（ID: a01d31b1）
- 检测逻辑：status=running + lastUpdated 超过3分钟 → 发送 Discord 告警
- ⚠️ isolated session 发 Discord 消息有格式限制，待修复

## 腾讯云新加坡服务器
- IP: 43.160.218.220，SSH: 22022，代理: 15430
- 详情见：`memory/singapore-server-guide.md`

## 待完成项目（锦上添花）
- autoDream.py（凌晨记忆整理脚本）
- 作业截止检查 Cron
- GitHub Trending 收藏 Cron
- 服务器结果拉取（需先配服务器）

## 重要规则

### 任务自我进度检测规则
**每次任务执行时，无论什么任务，每3分钟进行一次自我进度检测。**
- 目的：让 Lucas 能判断我是卡死了还是在进行某个步骤
- webchat：heartbeat回复即可看到（每次heartbeat就是一次自然检测）
- discord：cron job 每3分钟检查 progress.json，超时则发告警到 to-do-list ✅

### 任务进度文件规则
**执行多步骤任务（>2步）时，必须更新 progress.json：**
1. 任务开始时：写入 `status=running` + 开始时间 + 步骤信息
2. 每完成一个步骤：更新 `completedSteps` + `lastUpdated` + 当前步骤描述
3. 任务结束时：写入 `status=idle`
文件路径：`memory/kairos/progress.json`

### Discord 心跳/告警问题
- 状态：✅ 已解决
- 方案：cron job（每3分钟）检查 progress.json，超时发 Discord to-do-list 告警

### 计划/方案提出前必读

### 计划/方案提出前必读
**提出任何计划或方案之前，必须先判断可行性。不可行的方案不要给用户选。**

流程：先确认能做到 → 再生成方案 → 确认后执行。

### 清理 C 盘时的附带任务
**当我让 Lucas 清理 C 盘时，必须同时执行以下操作：**
- 检查 `memory/conversations/` 目录
- 清理创建时间超过 **1 个月**的存档文件（.json 和 raw/*.txt）
- 执行命令：`powershell -File memory/conversations/chat-memory.ps1 -Action cleanup`
- 确认已删除的文件数量和大小
