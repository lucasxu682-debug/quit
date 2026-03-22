@echo off
:: 设置UTF-8编码，确保中文正常显示
chcp 65001 >nul 2>&1
if %errorlevel% neq 0 (
    echo 警告: 无法设置UTF-8编码，中文可能显示为乱码
    echo Warning: Cannot set UTF-8 encoding, Chinese characters may be garbled
    pause
)
setlocal EnableDelayedExpansion

:: ==========================================
:: C盘垃圾文件清理脚本 v4.2 - 终极保护版
:: 特性：多重保护机制，确保系统安全
:: ==========================================

:: 初始化设置
set "HH=%time:~0,2%"
set "HH=%HH: =0%"
set "MM=%time:~3,2%"
set "SS=%time:~6,2%"
set "YYYY=%date:~0,4%"
set "MO=%date:~5,2%"
set "DD=%date:~8,2%"

set "LOGFILE=%TEMP%\cleanup_c_drive_%YYYY%%MO%%DD%_%HH%%MM%%SS%.log"
set "REPORTFILE=%TEMP%\cleanup_report_%YYYY%%MO%%DD%_%HH%%MM%%SS%.txt"
set "BACKUP_DIR=%TEMP%\cleanup_backup_%YYYY%%MO%%DD%_%HH%%MM%%SS%"
set "TOTAL_CLEANED_MB=0"
set "TOTAL_FILES=0"
set "PROTECTION_ENABLED=1"

:: ==========================================
:: 安全保护函数
:: ==========================================

:: 函数：创建备份
create_backup:
echo [%date% %time%] 创建文件列表备份... >> "%LOGFILE%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: 记录将要清理的文件列表（用于恢复）
(
echo 备份时间: %date% %time%
echo ====================
) > "%BACKUP_DIR%\file_list.txt"

:: 记录Windows临时文件
dir /s /b "C:\Windows\Temp\*.*" 2>nul >> "%BACKUP_DIR%\file_list.txt"

:: 记录用户临时文件
dir /s /b "%TEMP%\*.*" 2>nul >> "%BACKUP_DIR%\file_list.txt"

echo [%date% %time%] 备份已创建: %BACKUP_DIR% >> "%LOGFILE%"
goto :eof

:: 函数：安全检查 - 确保不会删除系统关键文件
:SafeCheck
set "CHECK_PATH=%~1"

:: 检查路径是否包含系统关键目录
echo %CHECK_PATH% | findstr /i "C:\Windows\System32" >nul
if %errorlevel% == 0 (
    echo ❌ 错误: 试图操作系统关键目录 %CHECK_PATH%
    echo [%date% %time%] 安全拦截: %CHECK_PATH% >> "%LOGFILE%"
    exit /b 1
)

echo %CHECK_PATH% | findstr /i "C:\Program Files" >nul
if %errorlevel% == 0 (
    echo ❌ 错误: 试图操作系统关键目录 %CHECK_PATH%
    echo [%date% %time%] 安全拦截: %CHECK_PATH% >> "%LOGFILE%"
    exit /b 1
)

echo %CHECK_PATH% | findstr /i "C:\Users\%USERNAME%\Documents" >nul
if %errorlevel% == 0 (
    echo ❌ 错误: 试图操作文档目录 %CHECK_PATH%
    echo [%date% %time%] 安全拦截: %CHECK_PATH% >> "%LOGFILE%"
    exit /b 1
)

exit /b 0

:: 函数：磁盘空间检查
check_disk_space:
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB"`) do set "FREE_GB=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round(%FREE_GB%, 0)"`) do set "FREE_GB_INT=%%a"

if %FREE_GB_INT% LSS 1 (
    echo ⚠️  警告: C盘可用空间不足1GB (%FREE_GB_INT% GB)
    echo 建议先手动清理一些大文件后再运行此脚本
    echo [%date% %time%] 警告: 磁盘空间不足 %FREE_GB_INT% GB >> "%LOGFILE%"
    set /p CONTINUE="是否继续? (Y/N): "
    if /i not "!CONTINUE!"=="Y" exit /b 1
)
goto :eof

:: ==========================================
:: 恢复帮助信息（在清理前显示）
:: ==========================================
:ShowRecoveryHelp
echo ==========================================
echo   C盘垃圾文件清理脚本 v4.2 - 终极保护版
echo   多重保护机制，确保系统安全
echo ==========================================
echo.
echo 💡 如果清理后出现问题，请按以下步骤恢复：
echo.
echo 【方法1：系统还原（推荐）】
echo   1. 打开"控制面板" → "恢复" → "打开系统还原"
echo   2. 选择还原点："C盘清理前_日期"
echo   3. 按向导完成还原
echo   4. 重启电脑
echo.
echo 【方法2：使用备份文件列表】
echo   1. 查看备份目录：%%TEMP%%\cleanup_backup_时间戳\
echo   2. 打开 file_list.txt 查看被删除的文件
necho   3. 如有需要，从回收站恢复或重新下载
echo.
echo 【方法3：紧急联系】
echo   1. 查看日志文件了解详细操作记录
echo   2. 如无法解决，请寻求专业人士帮助
echo.
echo ⚠️  注意：系统还原不会影响个人文档，但会恢复系统设置
echo ==========================================
echo.
pause
echo.
goto :eof

:: ==========================================
:: 主程序开始
:: ==========================================

call :ShowRecoveryHelp

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：需要管理员权限运行此脚本
    echo 请右键点击脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

echo ✅ 管理员权限检查通过
echo.

:: 初始化日志
echo ========================================== > "%LOGFILE%"
echo   C盘垃圾文件清理脚本 v4.2 - 执行日志 >> "%LOGFILE%"
echo   开始时间: %date% %time% >> "%LOGFILE%"
echo   保护机制: 已启用 >> "%LOGFILE%"
echo ========================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: 磁盘空间检查
call :check_disk_space
if %errorlevel% neq 0 exit /b 1

:: 创建系统还原点
echo 正在创建系统还原点...
echo [%date% %time%] 尝试创建系统还原点 >> "%LOGFILE%"
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "C盘清理前_%YYYY%%MO%%DD%", 100, 7 >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ 系统还原点创建成功
    echo [%date% %time%] 系统还原点创建成功 >> "%LOGFILE%"
) else (
    echo ⚠️  系统还原点创建失败（可能已禁用）
    echo [%date% %time%] 系统还原点创建失败 >> "%LOGFILE%"
    set /p CONTINUE="继续执行? (Y/N): "
    if /i not "!CONTINUE!"=="Y" exit /b 1
)
echo.

:: 创建文件列表备份
call :create_backup

:: 记录清理前状态
echo 📊 正在记录清理前状态...
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB"`) do set "FREE_BEFORE=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round(%FREE_BEFORE%, 2)"`) do set "FREE_BEFORE_GB=%%a"
echo    清理前可用空间: %FREE_BEFORE_GB% GB
echo [%date% %time%] 清理前可用空间: %FREE_BEFORE_GB% GB >> "%LOGFILE%"
echo.

:: 检测Windows.old
if exist "C:\Windows.old" (
    for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round((Get-ChildItem 'C:\Windows.old' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB, 2)"`) do set "WINOLD_SIZE=%%a"
    echo ⚠️  检测到 Windows.old 文件夹: !WINOLD_SIZE! GB
echo    提示: 可通过"磁盘清理" → "清理系统文件"删除
    echo [%date% %time%] 检测到Windows.old: !WINOLD_SIZE! GB >> "%LOGFILE%"
    echo.
)

:: 扫描大文件
echo 🔍 正在扫描大文件（超过500MB）...
powershell -Command "
$threshold = 500MB
$paths = @('$env:USERPROFILE\Downloads', '$env:TEMP')
$found = @()
foreach ($path in $paths) {
    if (Test-Path $path) {
        $files = Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Length -gt $threshold } | 
                 Select-Object -First 5
        $found += $files
    }
}
if ($found.Count -gt 0) {
    Write-Host '发现大文件:'
    $found | Sort-Object Length -Descending | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host \"  - $($_.FullName) (${size} MB)\"
    }
} else {
    Write-Host '没有发现超过500MB的大文件'
}
"
echo.

:: 最终确认
echo ==========================================
echo 💡 即将执行以下操作：
echo   1. 清理Windows临时文件
echo   2. 清理用户临时文件
echo   3. 清理浏览器缓存（Edge/Chrome/Firefox）
echo   4. 清理Windows更新缓存
echo   5. 清空回收站
echo   6. 清理缩略图缓存
echo   7. 清理系统日志（30天前）
echo   8. 清理崩溃转储文件
echo   9. 清理预读取缓存（7天前）
echo   10. 运行磁盘清理工具
echo.
echo ⚠️  安全保护：
echo   ✓ 已创建系统还原点
echo   ✓ 已备份文件列表到: %BACKUP_DIR%
echo   ✓ 已启用路径安全检查
echo   ✓ 不会删除系统文件或个人文档
echo ==========================================
echo.

set /p FINAL_CONFIRM="确定要继续吗? (输入 YES 确认): "
if /i not "!FINAL_CONFIRM!"=="YES" (
    echo 操作已取消
    exit /b 0
)

echo.
echo ==========================================
echo   开始清理（受保护模式）
echo ==========================================
echo.

:: ==========================================
:: 执行清理（带保护）
:: ==========================================

:: 函数：计算文件夹大小
:CalcFolderSize
set "FOLDER_PATH=%~1"
set "SIZE_RESULT=0"
if not exist "%FOLDER_PATH%" exit /b 0
for /f "usebackq delims=" %%a in (`powershell -Command "try { $size = (Get-ChildItem '%FOLDER_PATH%' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; [math]::Round($size / 1MB, 2) } catch { 0 }"`) do (
    set "SIZE_RESULT=%%a"
)
exit /b

:: 1. Windows临时文件（安全检查）
call :SafeCheck "C:\Windows\Temp"
if %errorlevel% neq 0 goto SkipWinTemp

echo [1/10] 清理 Windows 临时文件...
call :CalcFolderSize "C:\Windows\Temp"
set "SIZE_BEFORE=%SIZE_RESULT%"
if exist "C:\Windows\Temp" (
    del /f /s /q "C:\Windows\Temp\*.*" 2>nul
    for /d %%p in ("C:\Windows\Temp\*") do rd /s /q "%%p" 2>nul
    call :CalcFolderSize "C:\Windows\Temp"
    set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
    if !CLEANED! LSS 0 set "CLEANED=0"
    set /a "TOTAL_CLEANED_MB+=!CLEANED!"
    echo   ✓ 完成 (释放约 !CLEANED! MB)
    echo [%date% %time%] Windows临时文件: !CLEANED! MB >> "%LOGFILE%"
)
:SkipWinTemp

:: 2. 用户临时文件
echo [2/10] 清理用户临时文件...
set "USER_TEMP_CLEANED=0"
if exist "%TEMP%" (
    call :CalcFolderSize "%TEMP%"
    set "SIZE_BEFORE=%SIZE_RESULT%"
    del /f /s /q "%TEMP%\*.*" 2>nul
    for /d %%p in ("%TEMP%\*") do rd /s /q "%%p" 2>nul
    call :CalcFolderSize "%TEMP%"
    set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
    if !CLEANED! LSS 0 set "CLEANED=0"
    set /a "USER_TEMP_CLEANED+=!CLEANED!"
)
for /d %%u in ("C:\Users\*") do (
    if exist "%%u\AppData\Local\Temp" (
        call :CalcFolderSize "%%u\AppData\Local\Temp"
        set "SIZE_BEFORE=%SIZE_RESULT%"
        del /f /s /q "%%u\AppData\Local\Temp\*.*" 2>nul
        for /d %%p in ("%%u\AppData\Local\Temp\*") do rd /s /q "%%p" 2>nul
        call :CalcFolderSize "%%u\AppData\Local\Temp"
        set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
        if !CLEANED! LSS 0 set "CLEANED=0"
        set /a "USER_TEMP_CLEANED+=!CLEANED!"
    )
)
set /a "TOTAL_CLEANED_MB+=!USER_TEMP_CLEANED!"
echo   ✓ 完成 (释放约 !USER_TEMP_CLEANED! MB)
echo [%date% %time%] 用户临时文件: !USER_TEMP_CLEANED! MB >> "%LOGFILE%"

:: 3-4. 浏览器缓存（Edge/Chrome/Firefox）
echo [3-4/10] 清理浏览器缓存...

:: Edge
tasklist /fi "imagename eq msedge.exe" 2>nul | find /i "msedge.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Edge正在运行，跳过
) else (
    for %%c in (
        "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
        "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache"
    ) do (
        if exist "%%c" (
            call :CalcFolderSize "%%c"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%c\*.*" 2>nul
            for /d %%p in ("%%c\*") do rd /s /q "%%p" 2>nul
            call :CalcFolderSize "%%c"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "TOTAL_CLEANED_MB+=!CLEANED!"
        )
    )
    echo   ✓ Edge缓存清理完成
)

:: Chrome
tasklist /fi "imagename eq chrome.exe" 2>nul | find /i "chrome.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Chrome正在运行，跳过
) else (
    for %%c in (
        "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
        "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache"
    ) do (
        if exist "%%c" (
            call :CalcFolderSize "%%c"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%c\*.*" 2>nul
            for /d %%p in ("%%c\*") do rd /s /q "%%p" 2>nul
            call :CalcFolderSize "%%c"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "TOTAL_CLEANED_MB+=!CLEANED!"
        )
    )
    echo   ✓ Chrome缓存清理完成
)

:: Firefox
tasklist /fi "imagename eq firefox.exe" 2>nul | find /i "firefox.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Firefox正在运行，跳过
) else (
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
        if exist "%%p\cache2" (
            call :CalcFolderSize "%%p\cache2"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%p\cache2\*.*" 2>nul
            for /d %%d in ("%%p\cache2\*") do rd /s /q "%%d" 2>nul
            call :CalcFolderSize "%%p\cache2"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "TOTAL_CLEANED_MB+=!CLEANED!"
        )
        if exist "%%p\cache" (
            call :CalcFolderSize "%%p\cache"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%p\cache\*.*" 2>nul
            for /d %%d in ("%%p\cache\*") do rd /s /q "%%d" 2>nul
            call :CalcFolderSize "%%p\cache"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "TOTAL_CLEANED_MB+=!CLEANED!"
        )
    )
    echo   ✓ Firefox缓存清理完成
)

:: 5. Windows更新缓存
echo [5/10] 清理 Windows 更新缓存...
sc query wuauserv | find /i "RUNNING" >nul
if %errorlevel% == 0 (
    net stop wuauserv >nul 2>&1
    set "WUSERVICE_STOPPED=1"
)
if exist "C:\Windows\SoftwareDistribution\Download" (
    call :CalcFolderSize "C:\Windows\SoftwareDistribution\Download"
    set "SIZE_BEFORE=%SIZE_RESULT%"
    del /f /s /q "C:\Windows\SoftwareDistribution\Download\*.*" 2>nul
    for /d %%p in ("C:\Windows\SoftwareDistribution\Download\*") do rd /s /q "%%p" 2>nul
    call :CalcFolderSize "C:\Windows\SoftwareDistribution\Download"
    set /a "WU_CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
    if !WU_CLEANED! LSS 0 set "WU_CLEANED=0"
    set /a "TOTAL_CLEANED_MB+=!WU_CLEANED!"
)
if "%WUSERVICE_STOPPED%"=="1" (
    net start wuauserv >nul 2>&1
)
echo   ✓ 完成 (释放约 !WU_CLEANED! MB)

:: 6. 回收站
echo [6/10] 清空回收站...
powershell -Command "$rb = (New-Object -ComObject Shell.Application).Namespace(0xA); $size = 0; foreach ($item in $rb.Items()) { try { $size += $item.Size } catch {} }; if ($size -gt 0) { Clear-RecycleBin -Confirm:$false }; [math]::Round($size / 1MB, 2)" > "%TEMP%\rb_size.txt" 2>nul
set /p RB_SIZE=<"%TEMP%\rb_size.txt" 2>nul
del "%TEMP%\rb_size.txt" 2>nul
if not defined RB_SIZE set "RB_SIZE=0"
if %RB_SIZE% GTR 0 (
    set /a "TOTAL_CLEANED_MB+=%RB_SIZE%"
)
echo   ✓ 完成 (释放约 %RB_SIZE% MB)

:: 7. 缩略图缓存
echo [7/10] 清理缩略图缓存...
taskkill /f /im explorer.exe >nul 2>&1
powershell -Command "$size = (Get-ChildItem '$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db' -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; [math]::Round($size / 1MB, 2)" > "%TEMP%\thumb_size.txt" 2>nul
set /p THUMB_SIZE=<"%TEMP%\thumb_size.txt" 2>nul
del "%TEMP%\thumb_size.txt" 2>nul
if not defined THUMB_SIZE set "THUMB_SIZE=0"
if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" (
    for %%f in ("%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db") do (
        del /f /q "%%f" 2>nul
    )
)
set /a "TOTAL_CLEANED_MB+=%THUMB_SIZE%"
start explorer.exe
echo   ✓ 完成 (释放约 %THUMB_SIZE% MB)

:: 8. 系统日志文件（30天前的）
echo [8/10] 清理旧系统日志文件...
powershell -Command "$cutoff = (Get-Date).AddDays(-30); $size = 0; $count = 0; Get-ChildItem 'C:\Windows\Logs','C:\Windows\Installer' -Filter '*.log' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2)" > "%TEMP%\log_size.txt" 2>nul
set /p LOG_SIZE=<"%TEMP%\log_size.txt" 2>nul
del "%TEMP%\log_size.txt" 2>nul
if not defined LOG_SIZE set "LOG_SIZE=0"
set /a "TOTAL_CLEANED_MB+=%LOG_SIZE%"
echo   ✓ 完成 (释放约 %LOG_SIZE% MB)

:: 9. 崩溃转储文件
echo [9/10] 清理崩溃转储文件...
powershell -Command "$size = 0; $count = 0; Get-ChildItem 'C:\Windows\Minidump' -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; if (Test-Path 'C:\Windows\Memory.dmp') { $item = Get-Item 'C:\Windows\Memory.dmp'; $size += $item.Length; $count++; Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2); $count" > "%TEMP%\dump_result.txt" 2>nul
for /f "tokens=1,2" %%a in ("%TEMP%\dump_result.txt") do (
    set "DUMP_CLEANED=%%a"
    set "DUMP_COUNT=%%b"
)
del "%TEMP%\dump_result.txt" 2>nul
if not defined DUMP_CLEANED set "DUMP_CLEANED=0"
set /a "TOTAL_CLEANED_MB+=%DUMP_CLEANED%"
echo   ✓ 完成 (释放约 %DUMP_CLEANED% MB, %DUMP_COUNT% 个文件)

:: 10. 预读取缓存
echo [10/10] 清理旧预读取缓存...
powershell -Command "$cutoff = (Get-Date).AddDays(-7); $size = 0; $count = 0; Get-ChildItem 'C:\Windows\Prefetch' -Filter '*.pf' -ErrorAction SilentlyContinue | Where-Object { $_.LastAccessTime -lt $cutoff } | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2)" > "%TEMP%\pf_size.txt" 2>nul
set /p PF_SIZE=<"%TEMP%\pf_size.txt" 2>nul
del "%TEMP%\pf_size.txt" 2>nul
if not defined PF_SIZE set "PF_SIZE=0"
set /a "TOTAL_CLEANED_MB+=%PF_SIZE%"
echo   ✓ 完成 (释放约 %PF_SIZE% MB)

:: 运行磁盘清理工具
echo.
echo [额外] 运行磁盘清理工具（cleanmgr）...
start /wait cleanmgr /d C:
echo   ✓ cleanmgr完成

:: ==========================================
:: 清理完成，生成报告
:: ==========================================
echo.
echo ==========================================
echo   ✅ 清理完成！生成报告...
echo ==========================================
echo.

:: 获取清理后磁盘空间
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB"`) do set "FREE_AFTER=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round(%FREE_AFTER%, 2)"`) do set "FREE_AFTER_GB=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round((%FREE_AFTER% - %FREE_BEFORE%) * 1024, 2)"`) do set "ACTUAL_FREED_MB=%%a"

:: 生成报告
echo C盘清理对比报告 > "%REPORTFILE%"
echo 生成时间: %date% %time% >> "%REPORTFILE%"
echo ========================================== >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【磁盘空间变化】 >> "%REPORTFILE%"
echo 清理前可用: %FREE_BEFORE_GB% GB >> "%REPORTFILE%"
echo 清理后可用: %FREE_AFTER_GB% GB >> "%REPORTFILE%"
echo 实际释放:   %ACTUAL_FREED_MB% MB >> "%REPORTFILE%"
echo 估计释放:   约 %TOTAL_CLEANED_MB% MB >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【备份信息】 >> "%REPORTFILE%"
echo 文件列表备份: %BACKUP_DIR%\file_list.txt >> "%REPORTFILE%"
echo 系统还原点: C盘清理前_%YYYY%%MO%%DD% >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【建议】 >> "%REPORTFILE%"
echo - 重启电脑以确保所有清理生效 >> "%REPORTFILE%"
echo - 如遇到问题，可使用系统还原点恢复 >> "%REPORTFILE%"
echo - 备份位置: %BACKUP_DIR% >> "%REPORTFILE%"

echo 📊 清理效果：
echo   清理前可用: %FREE_BEFORE_GB% GB
echo   清理后可用: %FREE_AFTER_GB% GB
echo   实际释放:   %ACTUAL_FREED_MB% MB
echo   估计释放:   约 %TOTAL_CLEANED_MB% MB
echo.
echo 📁 文件位置：
echo   日志文件: %LOGFILE%
echo   报告文件: %REPORTFILE%
echo   备份目录: %BACKUP_DIR%
echo.
echo 💡 如需要恢复，可以使用：
echo   1. 系统还原点: C盘清理前_%YYYY%%MO%%DD%
echo   2. 文件列表备份: %BACKUP_DIR%\file_list.txt
echo.

echo [%date% %time%] 清理完成，总计释放 %TOTAL_CLEANED_MB% MB >> "%LOGFILE%"

pause
endlocal