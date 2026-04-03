# skill: ocr
# description: Use tesseract OCR to extract readable text from images. Invoke when user sends a screenshot or image and needs text recognition.
# triggers: 提取文字 / 识别文字 / OCR / 把图片变文字 / 图片转文字 / 扫描 / scan / 文字识别 / extract text

## When to Use This Skill

<trigger>
用户发送了一张图片/截图，并要求提取图片中的文字内容时使用。
不包括：只需要描述图片画面内容（那是 vision skill 的职责）。
</trigger>

## How It Works

1. Receive an image attachment from the user
2. Save the image to a temporary location
3. Run `tesseract` to extract text from the image
4. Return the extracted text to the user

## Tesseract path

`tesseract.exe` is at: `C:\Program Files\Tesseract-OCR\tesseract.exe`

## Usage

When the user sends an image, call the tool:

```
exec: tesseract <imagePath> stdout [--psm <mode>]
```

Common tesseract arguments:
- `<imagePath>` — path to the image file (png/jpg/webp/gif/bmp supported)
- `stdout` — output to console
- `--psm 6` — page segmentation mode 6 (single uniform block of text, recommended for screenshots)
- `-l eng+chi_sim` — English + Simplified Chinese (add if image may contain Chinese)
- `--oem 3` — LSTM neural network mode (best accuracy)

Example command for a screenshot with mixed content:
```
& "C:\Program Files\Tesseract-OCR\tesseract.exe" <path-to-image> stdout --psm 6 -l eng+chi_sim --oem 3
```

Example command for English-only:
```
& "C:\Program Files\Tesseract-OCR\tesseract.exe" <path-to-image> stdout --psm 6 --oem 3
```

## Notes

<psm_guide>
- PSM 3=full auto, 4=single column, 6=single uniform block (best for screenshots)
- If text looks garbled, try different PSM values (3, 4, 6, 11)
</psm_guide>

## Vision vs OCR 选择指南

<decision>
- 用户问"这张图里写了什么"、"提取文字" → ocr
- 用户问"这张图是什么意思"、"描述画面" → vision
- 不确定时 → 先 vision，文字部分可以用 ocr 补充
</decision>
