@echo off
REM Quick context manager commands for Windows

if "%1"=="init" (
    python "%~dp0context_manager.py" init --path %2
) else if "%1"=="status" (
    python "%~dp0context_manager.py" status --path %2
) else if "%1"=="update" (
    python "%~dp0context_manager.py" update --task "%2" --status "%3"
) else if "%1"=="decision" (
    python "%~dp0context_manager.py" decision --title "%2" --decision "%3" --reason "%4"
) else (
    echo Usage:
    echo   ctx init [path]           - Initialize project
    echo   ctx status [path]         - Show project status
    echo   ctx update "task" "status" - Update progress
    echo   ctx decision "title" "decision" "reason" - Record decision
)
