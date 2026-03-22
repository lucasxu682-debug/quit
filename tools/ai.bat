@echo off
REM Ollama Model Router - Smart model selection

echo ========================================
echo Ollama Local Model Router
echo ========================================
echo.

if "%1"=="" goto :help
if "%1"=="phi3" goto :phi3
if "%1"=="qwen" goto :qwen
if "%1"=="llama3.2" goto :llama32
if "%1"=="list" goto :list
if "%1"=="status" goto :status
if "%1"=="help" goto :help

REM Smart routing based on keywords
set "query=%*"
echo Detecting best model for: %query%
echo.

REM Check for Chinese characters (simplified check)
echo %query% | findstr /C:"中文" /C:"翻译" /C:"中文" >nul
if %errorlevel%==0 goto :route_qwen

REM Check for programming keywords
echo %query% | findstr /I /C:"python" /C:"code" /C:"programming" /C:"algorithm" /C:"debug" /C:"function" /C:"class" >nul
if %errorlevel%==0 goto :route_phi3

REM Check for quick query keywords
echo %query% | findstr /I /C:"what is" /C:"how to" /C:"list" /C:"quick" >nul
if %errorlevel%==0 goto :route_llama32

REM Default to Phi-3
goto :route_phi3

:phi3
echo [Phi-3 Mini] Programming ^& Technical Tasks
echo Strengths: Code generation, algorithms, debugging
echo.
C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe run phi3:mini
goto :end

:qwen
echo [Qwen 2.5 7B] Chinese Language Tasks
echo Strengths: Chinese writing, translation, Chinese Q^&A
echo.
C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe run qwen2.5:7b
goto :end

:llama32
echo [Llama 3.2 1B] Quick Queries
echo Strengths: Speed, simple lookups, low resource
echo.
C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe run llama3.2:1b
goto :end

:route_qwen
echo [Router] Chinese detected - Using Qwen 2.5
echo.
goto :qwen

:route_phi3
echo [Router] Programming/Technical task detected - Using Phi-3 Mini
echo.
goto :phi3

:route_llama32
echo [Router] Quick query detected - Using Llama 3.2
echo.
goto :llama32

:list
echo Installed Models:
echo.
C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe list
echo.
echo Model Usage Guide:
echo   phi3:mini    - Programming, algorithms, technical Q^&A
echo   qwen2.5:7b   - Chinese tasks, translation
echo   llama3.2:1b  - Quick queries, simple lookups
goto :end

:status
echo System Status:
echo.
echo GPU Status:
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader 2^>nul || echo GPU info not available
echo.
echo Running Models:
C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe ps 2^>nul || echo No models currently running
goto :end

:help
echo Usage: ai [command] [query]
echo.
echo Commands:
echo   ai phi3 [question]     - Use Phi-3 Mini (programming/technical)
echo   ai qwen [question]     - Use Qwen 2.5 (Chinese tasks)
echo   ai llama3.2 [question] - Use Llama 3.2 (quick queries)
echo   ai list                - Show installed models
echo   ai status              - Check GPU and running models
echo   ai help                - Show this help
echo.
echo Smart Routing (auto-detect):
echo   ai [your question]     - Automatically selects best model
echo.
echo Examples:
echo   ai "Write a Python function"
echo   ai qwen "用中文解释什么是机器学习"
echo   ai llama3.2 "List Python dict methods"
echo   ai "Debug this error: IndexError"
echo.
echo Model Selection Guide:
echo   Programming/Code    -^> Phi-3 Mini
echo   Chinese/Translation -^> Qwen 2.5
echo   Quick/Fast          -^> Llama 3.2

:end
