---
name: vision
description: >
  Use Gemini subagent to analyze and describe images. Invoke when user sends a screenshot,
  photo, or image and needs visual understanding. NOT for: extracting text from images (use ocr skill).
triggers: 看图 / 描述一下 / 分析这张 / 这是什么 / describe / analyze / screenshot / 截图 / 照片 / 图片
---

# Vision Skill — 图片理解

## 触发条件

用户发送图片并问"什么意思"、"描述一下"、"这是什么"时使用。
不包括：只需要提取图片中的文字（那是 ocr skill 的职责）。

## 实际使用方式

**主对话用 MiniMax M2（不支持图片），图片分析用 Gemini 子代理。**

当收到图片时，spawn 一个 Gemini 子代理：

```
sessions_spawn:
  task: "描述/分析这张图片中的一切，请详细说明"
  runtime: "subagent"
  model: "google/gemini-2.5-flash"
  mode: "run"
```

## 为什么用 Gemini

- MiniMax M2 不支持图片输入
- Gemini 2.5 Flash 多模态强，context window 1M
- 子代理处理完结果自动返回主对话

## 决策流程

```
用户发送图片
    │
    ├── 问"图里写的什么" / "提取文字" → ocr skill
    │
    └── 问"这张图什么意思" / "描述一下" → vision skill（Gemini 子代理）
            │
            └── 不确定 → 先 vision，文字部分补充 ocr
```

## 使用示例

用户发送图片说"帮我看看这张图"：
1. Spawn Gemini 子代理分析图片
2. 子代理返回描述结果
3. 在主对话呈现结果

## 注意事项

- 图片路径要用绝对路径（Windows: `C:/Users/...`）
- Forward slash 比 backslash 更稳定
- 第一次分析可能较慢（Gemini 预热）
