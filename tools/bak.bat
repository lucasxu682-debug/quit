@echo off
REM Backup manager quick commands

if "%1"=="backup" (
    python "%~dp0backup_manager.py" backup --reason "manual" %2 %3
) else if "%1"=="restore" (
    python "%~dp0backup_manager.py" restore %2 %3
) else if "%1"=="list" (
    python "%~dp0backup_manager.py" list %2
) else if "%1"=="cleanup" (
    python "%~dp0backup_manager.py" cleanup %2 %3
) else if "%1"=="pre" (
    python "%~dp0backup_manager.py" pre-action "%2"
) else if "%1"=="verify" (
    python "%~dp0backup_manager.py" verify
) else (
    echo Backup Manager - Quick Commands
    echo.
    echo Usage:
    echo   bak backup [reason]          - Create backup
    echo   bak restore [id]             - Restore backup
    echo   bak list                     - List backups
    echo   bak cleanup [--dry-run]      - Clean old backups
    echo   bak pre "action-name"        - Pre-action backup
    echo   bak verify                   - Verify integrity
    echo.
    echo Examples:
    echo   bak backup "before-major-change"
    echo   bak pre "installing-new-skill"
    echo   bak restore 20260317_072500_a1b2c3
)
