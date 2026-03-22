---
name: ollama-qwen-agent
description: Local AI assistant powered by Qwen 2.5 7B. Use for: (1) Chinese content creation and writing, (2) Chinese-English translation, (3) Chinese programming documentation, (4) complex reasoning in Chinese, (5) Chinese Q&A and explanations. NOT for: quick simple queries, resource-constrained scenarios. Requires Ollama with qwen2.5:7b model and 6-8GB VRAM.
---

# Qwen 2.5 7B Agent

Local AI assistant optimized for Chinese language tasks.

## Model Info
- **Model**: Qwen 2.5 7B (7B parameters)
- **Strengths**: Chinese language, translation, complex reasoning
- **Speed**: Moderate (~3-5s response)
- **Language**: Chinese (excellent), English (good)
- **VRAM**: Requires 6-8GB

## When to Use

### ✅ Use for:
- Chinese content writing and editing
- Chinese-English translation
- Reading and explaining Chinese documentation
- Complex questions in Chinese
- Chinese programming tutorials
- Writing Chinese comments and documentation

### ❌ Don't use for:
- Quick simple queries (overkill)
- When VRAM is needed for other tasks
- Simple English-only tasks

## Usage

```bash
# Direct usage
ollama-run qwen

# Or via this agent
```

## Example Tasks

1. "用中文解释什么是机器学习"
2. "把这段英文翻译成中文：..."
3. "帮我写一段Python代码的中文注释"
4. "解释这个中文技术文档"

## Tips
- Best for Chinese-first tasks
- Can handle complex reasoning in Chinese
- More capable but slower than smaller models
