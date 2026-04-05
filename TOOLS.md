# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## 腾讯云新加坡翻墙服务器

| 项目 | 内容 |
|------|------|
| **IP** | 43.160.218.220 |
| **SSH 端口** | 22022（Key 免密登录） |
| **代理端口** | 15430（HTTP gost） |
| **3x-ui 面板** | https://43.160.218.220:61153/pHgce0yS6aqIWsO2Ek |
| **SSH 命令** | `ssh root@43.160.218.220 -p 22022` |
| **代理地址** | `http://43.160.218.220:15430` |

详细流程见：`memory/singapore-server-guide.md`

## TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod

## Serper.dev API

- API Key: `5351bf144e4251aa3234ca378e99c65be054413d`
- 用途: 实时搜索（2500次/月免费）
- 端点: `https://google.serper.dev/search`
- 注意: OpenClaw web_search 工具使用 Brave API，不支持 Serper；需要通过 exec/curl 直接调用

## 搜索配置

- Brave API Key: （未配置，网页搜索不可用）
- Serper.dev API Key: `5351bf144e4251aa3234ca378e99c65be054413d` ✅ 已配置

## exec 中文编码

Windows PowerShell 默认输出编码是 GBK，exec 调用 Python 时中文会乱码。

**解决方法：** 在涉及中文的 exec 命令前加编码前缀：

```bash
$env:PYTHONIOENCODING='utf-8'; python -c "..."
```

**示例：**
```bash
$env:PYTHONIOENCODING='utf-8'; python -c "from docx import Document; ..."
$env:PYTHONIOENCODING='utf-8'; python -c "print('测试中文')"
```

PowerShell profile 已写入 `chcp 65001` 和 PYTHONIOENCODING 配置，新 session 理论上自动生效。若仍有乱码，手动加前缀。

## Gemini 子代理（多模态专用）

当需要分析图片/视频时，spawn一个 Gemini 子代理处理：

```
sessions_spawn:
  task: "描述/分析这张图片/视频中的一切"
  runtime: "subagent"
  model: "google/gemini-2.5-flash"
  mode: "run"
```

**触发时机：** 你发图片并说"帮我看这张图" / "描述一下" / "分析这个视频"时自动调用。

**优势：** 主对话保持 MiniMax-M2.7（快/便宜），图片分析用 Gemini（多模态强，context window 1M）。

---

## KAIROS 项目 — Roo Code 协作

**Roo Code 工作目录：** `c:/Users/xumou/Desktop/Object-oriented programming/quiz`

**协作约定：**
- OpenClaw 写任务 → `memory/kairos/task.md`
- Roo Code 读任务 → 手动：`请读取 ./kairos/task.md`
- Roo Code 结果 → 写到指定路径
- OpenClaw 读结果 → 下次 Heartbeat/Cron 时检查

**KAIROS 项目目录：** `C:\Users\xumou\.openclaw\workspace\memory\kairos\`
- task.md — 当前任务
- results/ — Roo Code 输出结果
- observations/ — 每日观察日志
- autoDream.py — 夜间记忆整理脚本（待创建）
- rules.md — 主动触发规则（待创建）
