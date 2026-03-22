---
name: ollama-router
description: Intelligent router for local Ollama models. Automatically selects the best model for your task: Phi-3 Mini for programming, Qwen 2.5 for Chinese, Llama 3.2 for quick queries. Use when you want to use local AI but don't know which model to choose. Requires Ollama with phi3:mini, qwen2.5:7b, and llama3.2:1b models installed.
---

# Ollama Model Router

Automatically routes your queries to the best local model.

## Model Selection Logic

```
User Query
    ↓
┌─────────────────────────────────────┐
│  Is it Chinese?                     │
│  → Yes: Use Qwen 2.5 7B             │
│  → No: Continue                     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Is it programming/coding?          │
│  → Yes: Use Phi-3 Mini              │
│  → No: Continue                     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Is it simple/quick?                │
│  → Yes: Use Llama 3.2 1B            │
│  → No: Use Phi-3 Mini (default)     │
└─────────────────────────────────────┘
```

## Quick Reference

| Task Type | Model | Why |
|-----------|-------|-----|
| 中文写作 | Qwen 2.5 | 中文最强 |
| 写代码 | Phi-3 Mini | 代码能力强 |
| 快速查询 | Llama 3.2 | 速度最快 |
| 算法题 | Phi-3 Mini | 推理能力强 |
| 翻译 | Qwen 2.5 | 中英互译 |
| Debug | Phi-3 Mini | 代码审查 |
| 简单问答 | Llama 3.2 | 省资源 |

## Usage

### Option 1: Let me choose
Just tell me what you want to do, I'll pick the right model.

### Option 2: Direct model access
```bash
ollama-run phi3     # Programming
ollama-run qwen     # Chinese
ollama-run llama3.2 # Quick queries
```

## Examples

**You**: "用Python写个爬虫"
→ **Router**: Use Phi-3 Mini (programming task)

**You**: "把这段话翻译成中文"
→ **Router**: Use Qwen 2.5 (Chinese translation)

**You**: "Python的list有哪些方法？"
→ **Router**: Use Llama 3.2 (quick factual query)

**You**: "解释什么是RAG"
→ **Router**: Use Phi-3 Mini (technical explanation)

## Model Status Check

```bash
# Check which models are available
ollama list

# Check GPU usage
nvidia-smi
```

## Tips
- When in doubt, I default to Phi-3 Mini (most capable)
- For Chinese, always use Qwen
- For speed, use Llama 3.2
- You can override my choice by specifying the model
