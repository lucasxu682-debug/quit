import whisper
import sys

print("Whisper 版本:", whisper.__version__ if hasattr(whisper, '__version__') else "已安装")
print("可用模型:", ", ".join(whisper.available_models()))