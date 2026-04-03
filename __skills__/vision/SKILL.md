# skill: vision
# description: Use Ollama's llava model to analyze and describe images. Invoke when user sends a screenshot, photo, or image and needs visual understanding.
# triggers: 看图 / 看一眼 / 图片分析 / 描述这张图 / 这是什么 / describe / analyze / screenshot / 截图 / 照片 / 图片描述

## When to Use This Skill

<trigger>
用户发送了一张图片/截图/照片，并要求描述、分析、理解画面内容时使用。
不包括：只需要提取图片中的文字（那是 ocr skill 的职责）。
</trigger>

## How It Works

1. Receive an image attachment or path from the user
2. Use Ollama's `llava` model to analyze the image
3. Return a detailed description of what's in the image

## Ollama Model

- **Model name**: `llava:latest`
- **Size**: 4.7 GB
- **Purpose**: Visual question answering, image description, screenshot understanding

## Usage

When the user sends an image, run:

```
ollama run llava "Describe what's in this image in detail. Just describe what you see on the screen: <imagePath>" --verbose
```

### Important Notes

- Use `--verbose` flag to see full output
- The image path should be an absolute path (Windows format: `C:/Users/...`)
- Forward slashes work better than backslashes in the command
- If the command seems slow, wait for it to complete (can take 30-60 seconds)
- If it fails, try checking if Ollama is running: `ollama list`

## Troubleshooting

- **Error "model not found"**: Run `ollama pull llava` to download the model
- **Error "connection refused"**: Ollama service might not be running; try `ollama serve`
- **Very slow**: Normal for first run; model loads into memory

## Example Use Cases

<examples>
- User sends a screenshot of an error message → describe the error
- User sends a photo → describe what's in it
- User sends a graph/chart → describe the data trends
- User sends an email page → describe the content
</examples>
