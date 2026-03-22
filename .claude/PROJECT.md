# OpenClaw Workspace

## 项目概述
- **创建时间**: 2026-03-17T07:22:56.341067
- **最后更新**: 2026-03-17T07:25:00
- **状态**: 活跃开发中

## 技术栈
- **OpenClaw** - AI 助手平台
- **Python** - 脚本开发
- **GitHub CLI** - 版本控制
- **Whisper** - 语音转文字
- **MCP** - 模型上下文协议
- **Tavily** - AI 搜索引擎
- **Auto-Backup** - 自动备份与回档系统
- **Ollama** - 本地AI模型（Phi-3 + Qwen + Llama3.2）

## 项目结构
```
C:\Users\xumou\quit\
├── .claude/              # 项目文档
├── skills/               # OpenClaw skills
│   ├── github/           # GitHub 操作
│   ├── openai-whisper/   # 语音转文字
│   ├── mcporter/         # MCP 工具
│   ├── superpowers/      # 开发工作流
│   └── doc-converter/    # 文档转换
├── tools/                # 自定义工具
│   ├── whisper.bat       # Whisper 包装器
│   ├── context_manager.py # 项目管理
│   ├── backup_manager.py # 备份管理器
│   ├── bak.bat           # 备份快捷命令
│   ├── ollama-run.bat    # Ollama 快捷命令
│   └── ai.bat            # AI模型智能路由
├── docs/                 # 文档
│   └── ollama-model-guide.md # 模型使用指南
├── config/               # 配置文件
│   └── mcporter.json     # MCP 配置
├── memory/               # 记忆文件
├── AGENTS.md             # 工作区指南
├── SOUL.md               # AI 人格
├── USER.md               # 用户信息
├── TOOLS.md              # 工具笔记
└── BOOTSTRAP.md          # 启动指南
```

## 当前任务
- 维护和更新项目文档
- 使用 OpenClaw skills 进行开发

## 待办事项
- [x] 完善项目文档
- [x] 设置开发环境
- [x] 安装 GitHub skill
- [x] 安装 Whisper skill
- [x] 配置 MCP 工具
- [x] 安装 Superpowers skill
- [x] 安装 doc-converter skill
- [x] 建立自动备份系统
- [x] 安装 Ollama 本地模型
- [x] 配置 Phi-3 Mini (编程)
- [x] 配置 Qwen 2.5 7B (中文)
- [x] 配置 Llama 3.2 1B (快速查询)
- [ ] 探索更多 skills

## 未来可能需要的工具
- [ ] **WSL2** - 当需要 Linux 开发环境时安装（已了解，暂不安装）

## 关键决策
See [DECISIONS.md](DECISIONS.md)

## 进度跟踪
See [PROGRESS.md](PROGRESS.md)
