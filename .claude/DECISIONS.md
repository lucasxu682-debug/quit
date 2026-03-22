# 项目决策记录 (ADR)

## 决策列表

### [2026-03-17] 项目初始化 - ✅ 已采纳

决定创建项目文档系统。

**原因**: 提高 AI 助手效率，减少上下文重复加载。

**影响**: 需要维护文档更新。

### [2026-03-17] 安装 Superpowers skill - ✅ 已采纳

安装 Superpowers 开发工作流 skill，尽管被标记为 SUSPICIOUS。

**原因**: 需要结构化的开发工作流，来自知名项目 obra/superpowers。

**影响**: 建立了监控机制，每次使用会检查行为。

### [2026-03-17] 使用 Tavily 替代 Brave Search - ✅ 已采纳

在 MCP 配置中用 Tavily 替换 Brave Search。

**原因**: Tavily 专为 AI 设计，返回结构化结果，更适合 LLM 使用。

**影响**: 需要 Tavily API Key，已获得并配置。

### [2026-03-17] 创建 doc-converter skill - ✅ 已采纳

创建自定义 skill 整合 PDF、DOCX、HTML 到 Markdown 的转换功能。

**原因**: 需要一个统一的文档转换工具。

**影响**: 需要安装 pdfplumber、python-docx、markdownify 等依赖。

### [2026-03-17] 安装 Ollama 本地模型系统 - ✅ 已采纳

安装 Ollama 并配置三个本地模型：Phi-3 Mini（编程）、Qwen 2.5 7B（中文）、Llama 3.2 1B（快速查询）。

**原因**: 本地模型提供隐私保护、零成本、离线可用，且你的 RTX 4070 配置可以流畅运行。

**影响**: 占用约 8GB 硬盘空间，显存按需分配。

### [2026-03-17] 暂缓安装 WSL2 - ⏸️ 待定

了解 WSL2 的用途后决定暂不安装，等待实际需求出现时再安装。

**原因**: 目前所有工作都能在 Windows 下完成，没有迫切需要。

**触发条件**: 当遇到以下情况时提醒我安装：
- Python/Node.js 开发环境在 Windows 下出现问题
- 需要使用 Docker/Kubernetes
- 某些开源工具在 Windows 上无法安装
- 需要与 Linux 服务器环境保持一致
- 需要学习或使用 Linux 命令行工具

---
*记录格式: [日期] 决策标题 - 状态*
