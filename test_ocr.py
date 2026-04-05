import sys
import os

try:
    from PIL import Image
    print("PIL: OK")
except ImportError as e:
    print(f"PIL: MISSING - {e}")
    sys.exit(1)

try:
    import pytesseract
    print("pytesseract: OK")
except ImportError as e:
    print(f"pytesseract: MISSING - {e}")
    # Try to use Windows built-in OCR as fallback
    try:
        import subprocess
        result = subprocess.run(
            ['powershell', '-Command', 
             'Add-Type -AssemblyName System.Runtime.WindowsRuntime; '
             '$null = [Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime; '
             '[Windows.Media.Ocr.OcrEngine]::IsSupported'],
            capture_output=True, text=True
        )
        print(f"Windows OCR support: {result.stdout.strip()}")
    except Exception as ex:
        print(f"Windows OCR check failed: {ex}")
    sys.exit(1)

# Test with a real image if provided
if len(sys.argv) > 1:
    img_path = sys.argv[1]
    if os.path.exists(img_path):
        text = pytesseract.image_to_string(img_path)
        print(f"OCR result:\n{text}")
    else:
        print(f"File not found: {img_path}")
