# OCR helper script - extracts text from image using tesseract
# Usage: .\ocr.ps1 <imagePath> [lang]
#   lang: comma-separated languages, e.g. "eng", "eng+chi_sim" (default: eng)

param(
    [Parameter(Mandatory=$true)][string]$ImagePath,
    [string]$Lang = "eng"
)

$Tesseract = "C:\Program Files\Tesseract-OCR\tesseract.exe"

if (-not (Test-Path $Tesseract)) {
    Write-Error "Tesseract not found at $Tesseract"
    exit 1
}

if (-not (Test-Path $ImagePath)) {
    Write-Error "Image file not found: $ImagePath"
    exit 1
}

& $Tesseract $ImagePath stdout --psm 6 -l $Lang --oem 3
