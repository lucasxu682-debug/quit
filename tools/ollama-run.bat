@echo off
REM Ollama quick launcher

set OLLAMA_PATH=C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe

if "%1"=="" (
    echo Ollama Quick Commands
    echo.
    echo Usage:
    echo   ollama-run phi3          - Run Phi-3 Mini
    echo   ollama-run llama3.2      - Run Llama 3.2 1B
    echo   ollama-run qwen          - Run Qwen 2.5 7B
    echo   ollama-run codellama     - Run CodeLlama 7B
    echo   ollama-list              - List installed models
    echo   ollama-ps                - Check running models
    echo.
    echo Or use full command:
    echo   %OLLAMA_PATH% [command]
) else if "%1"=="phi3" (
    %OLLAMA_PATH% run phi3:mini
) else if "%1"=="llama3.2" (
    %OLLAMA_PATH% run llama3.2:1b
) else if "%1"=="qwen" (
    %OLLAMA_PATH% run qwen2.5:7b
) else if "%1"=="codellama" (
    %OLLAMA_PATH% run codellama:7b
) else if "%1"=="list" (
    %OLLAMA_PATH% list
) else if "%1"=="ps" (
    %OLLAMA_PATH% ps
) else (
    %OLLAMA_PATH% %*
)
