---
name: ollama-llama32-agent
description: Local AI assistant powered by Llama 3.2 1B. Use for: (1) quick simple queries, (2) fast factual lookups, (3) when system resources are constrained, (4) simple translations, (5) basic Q&A. NOT for: complex coding, detailed explanations, Chinese tasks. Requires Ollama with llama3.2:1b model.
---

# Llama 3.2 1B Agent

Lightning-fast local AI assistant for quick tasks.

## Model Info
- **Model**: Llama 3.2 1B (1B parameters)
- **Strengths**: Speed, low resource usage
- **Speed**: Lightning fast (~1s response)
- **Language**: English (primary)
- **VRAM**: Minimal (~1GB)

## When to Use

### ✅ Use for:
- Quick factual questions
- Simple lookups
- When you need instant response
- While running other GPU-intensive tasks
- Basic brainstorming
- Simple list generation

### ❌ Don't use for:
- Complex coding tasks
- Detailed explanations
- Chinese content
- Multi-step reasoning
- Code review

## Usage

```bash
# Direct usage
ollama-run llama3.2

# Or via this agent
```

## Example Tasks

1. "What is the capital of France?"
2. "List 5 Python list methods"
3. "Quick reminder: what does REST stand for?"
4. "Give me a one-sentence summary of..."

## Tips
- Keep questions simple and direct
- Don't expect detailed responses
- Perfect for quick lookups while coding
- Can run alongside other GPU tasks
