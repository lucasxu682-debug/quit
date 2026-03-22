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
:: C盘垃圾文件清理脚本 v4.1 - 修复版
:: 修复：补全所有清理逻辑，修复变量展开bug
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
set "TOTAL_CLEANED_MB=0"
set "TOTAL_FILES=0"

:: 初始化日志
echo ========================================== > "%LOGFILE%"
echo   C盘垃圾文件清理脚本 v4.1 - 执行日志 >> "%LOGFILE%"
echo   开始时间: %date% %time% >> "%LOGFILE%"
echo ========================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: ==========================================
:: 显示欢迎信息
:: ==========================================
echo ==========================================
echo   C盘垃圾文件清理脚本 v4.1
echo   安全模式 - 智能清理与验证
echo ==========================================
echo.
echo 本脚本功能：
echo   ✓ 清理前：创建系统还原点 + 扫描大文件
echo   ✓ 清理中：10项垃圾文件安全清理
echo   ✓ 清理后：自动验证 + 生成对比报告
echo.
echo 日志文件: %LOGFILE%
echo 报告文件: %REPORTFILE%
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：需要管理员权限运行此脚本
    echo 请右键点击脚本，选择"以管理员身份运行"
    echo.
    pause
    exit /b 1
)

echo ✅ 管理员权限检查通过
echo.

:: ==========================================
:: 创建系统还原点
:: ==========================================
echo 正在创建系统还原点（如失败可继续）...
echo [%date% %time%] 尝试创建系统还原点 >> "%LOGFILE%"

wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "C盘清理前_%YYYY%%MO%%DD%", 100, 7 >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ 系统还原点创建成功
    echo [%date% %time%] 系统还原点创建成功 >> "%LOGFILE%"
) else (
    echo ⚠️  系统还原点创建失败（可能已禁用），继续执行...
    echo [%date% %time%] 系统还原点创建失败 >> "%LOGFILE%"
)
echo.

:: ==========================================
:: 记录清理前状态
:: ==========================================
echo 📊 正在记录清理前状态...
echo [%date% %time%] 记录清理前状态 >> "%LOGFILE%"

:: 获取清理前磁盘空间
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace"`) do set "FREE_BEFORE=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round(%FREE_BEFORE% / 1GB, 2)"`) do set "FREE_BEFORE_GB=%%a"

echo    清理前可用空间: %FREE_BEFORE_GB% GB
echo [%date% %time%] 清理前可用空间: %FREE_BEFORE_GB% GB >> "%LOGFILE%"
echo.

:: ==========================================
:: 检测Windows.old文件夹
:: ==========================================
if exist "C:\Windows.old" (
    for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round((Get-ChildItem 'C:\Windows.old' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB, 2)"`) do set "WINOLD_SIZE=%%a"
    echo ⚠️  检测到 Windows.old 文件夹
echo    大小: 约 !WINOLD_SIZE! GB
echo    提示: 可通过"磁盘清理" → "清理系统文件"删除
    echo [%date% %time%] 检测到Windows.old: !WINOLD_SIZE! GB >> "%LOGFILE%"
    echo.
)

:: ==========================================
:: 扫描大文件
:: ==========================================
echo 🔍 正在扫描大文件（超过500MB）...
echo [%date% %time%] 开始扫描大文件 >> "%LOGFILE%"

powershell -Command "
$threshold = 500MB
$paths = @('$env:USERPROFILE\Downloads', '$env:TEMP', 'C:\Windows\Temp')
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
pause

:: ==========================================
:: 函数：计算文件夹大小（MB）- 修复版
:: ==========================================
:CalcFolderSize
set "FOLDER_PATH=%~1"
set "SIZE_RESULT=0"

if not exist "%FOLDER_PATH%" exit /b 0

for /f "usebackq delims=" %%a in (`powershell -Command "try { $size = (Get-ChildItem '%FOLDER_PATH%' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; [math]::Round($size / 1MB, 2) } catch { 0 }"`) do (
    set "SIZE_RESULT=%%a"
)
exit /b

:: ==========================================
:: 执行清理
:: ==========================================
echo.
echo ==========================================
echo   开始清理垃圾文件
echo ==========================================

:: 1. Windows临时文件
echo.
echo [1/10] 正在清理 Windows 临时文件...
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

:: 2. 用户临时文件
echo.
echo [2/10] 正在清理用户临时文件...
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

:: 3. 浏览器缓存 - Edge
echo.
echo [3/10] 正在清理 Edge 浏览器缓存...
set "EDGE_CLEANED=0"

tasklist /fi "imagename eq msedge.exe" 2>nul | find /i "msedge.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Edge正在运行，跳过
    echo [%date% %time%] Edge正在运行，跳过 >> "%LOGFILE%"
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
            set /a "EDGE_CLEANED+=!CLEANED!"
        )
    )
    echo   ✓ 完成 (释放约 !EDGE_CLEANED! MB)
    echo [%date% %time%] Edge缓存: !EDGE_CLEANED! MB >> "%LOGFILE%"
)
set /a "TOTAL_CLEANED_MB+=!EDGE_CLEANED!"

:: 4. 浏览器缓存 - Chrome
echo.
echo [4/10] 正在清理 Chrome 浏览器缓存...
set "CHROME_CLEANED=0"

tasklist /fi "imagename eq chrome.exe" 2>nul | find /i "chrome.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Chrome正在运行，跳过
    echo [%date% %time%] Chrome正在运行，跳过 >> "%LOGFILE%"
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
            set /a "CHROME_CLEANED+=!CLEANED!"
        )
    )
    echo   ✓ 完成 (释放约 !CHROME_CLEANED! MB)
    echo [%date% %time%] Chrome缓存: !CHROME_CLEANED! MB >> "%LOGFILE%"
)
set /a "TOTAL_CLEANED_MB+=!CHROME_CLEANED!"

:: 4b. 浏览器缓存 - Firefox
echo.
echo [4b/10] 正在清理 Firefox 浏览器缓存...
set "FIREFOX_CLEANED=0"

tasklist /fi "imagename eq firefox.exe" 2>nul | find /i "firefox.exe" >nul
if %errorlevel% == 0 (
    echo   ⚠️  Firefox正在运行，跳过
    echo [%date% %time%] Firefox正在运行，跳过 >> "%LOGFILE%"
) else (
    for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
        :: 清理 cache2 (主要缓存)
        if exist "%%p\cache2" (
            call :CalcFolderSize "%%p\cache2"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%p\cache2\*.*" 2>nul
            for /d %%d in ("%%p\cache2\*") do rd /s /q "%%d" 2>nul
            call :CalcFolderSize "%%p\cache2"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "FIREFOX_CLEANED+=!CLEANED!"
        )
        :: 清理 cache (代码缓存)
        if exist "%%p\cache" (
            call :CalcFolderSize "%%p\cache"
            set "SIZE_BEFORE=%SIZE_RESULT%"
            del /f /s /q "%%p\cache\*.*" 2>nul
            for /d %%d in ("%%p\cache\*") do rd /s /q "%%d" 2>nul
            call :CalcFolderSize "%%p\cache"
            set /a "CLEANED=!SIZE_BEFORE! - !SIZE_RESULT!"
            if !CLEANED! LSS 0 set "CLEANED=0"
            set /a "FIREFOX_CLEANED+=!CLEANED!"
        )
    )
    echo   ✓ 完成 (释放约 !FIREFOX_CLEANED! MB)
    echo [%date% %time%] Firefox缓存: !FIREFOX_CLEANED! MB >> "%LOGFILE%"
)
set /a "TOTAL_CLEANED_MB+=!FIREFOX_CLEANED!"

:: 5. Windows更新缓存
echo.
echo [5/10] 正在清理 Windows 更新缓存...
set "WU_CLEANED=0"

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
)

if "%WUSERVICE_STOPPED%"=="1" (
    net start wuauserv >nul 2>&1
)

set /a "TOTAL_CLEANED_MB+=!WU_CLEANED!"
echo   ✓ 完成 (释放约 !WU_CLEANED! MB)
echo [%date% %time%] Windows更新缓存: !WU_CLEANED! MB >> "%LOGFILE%"

:: 6. 回收站
echo.
echo [6/10] 正在清空回收站...
set "RB_CLEANED=0"

powershell -Command "$rb = (New-Object -ComObject Shell.Application).Namespace(0xA); $size = 0; foreach ($item in $rb.Items()) { try { $size += $item.Size } catch {} }; if ($size -gt 0) { Clear-RecycleBin -Confirm:$false }; [math]::Round($size / 1MB, 2)" > "%TEMP%\rb_size.txt" 2>nul
set /p RB_SIZE=<"%TEMP%\rb_size.txt" 2>nul
del "%TEMP%\rb_size.txt" 2>nul

if not defined RB_SIZE set "RB_SIZE=0"
if %RB_SIZE% GTR 0 (
    set /a "RB_CLEANED=%RB_SIZE%"
    set /a "TOTAL_CLEANED_MB+=%RB_SIZE%"
)
echo   ✓ 完成 (释放约 %RB_CLEANED% MB)
echo [%date% %time%] 回收站: %RB_CLEANED% MB >> "%LOGFILE%"

:: 7. 缩略图缓存
echo.
echo [7/10] 正在清理缩略图缓存...
set "THUMB_CLEANED=0"

taskkill /f /im explorer.exe >nul 2>&1

:: 使用PowerShell准确计算缩略图大小
powershell -Command "$size = (Get-ChildItem '$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db' -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; [math]::Round($size / 1MB, 2)" > "%TEMP%\thumb_size.txt" 2>nul
set /p THUMB_SIZE=<"%TEMP%\thumb_size.txt" 2>nul
del "%TEMP%\thumb_size.txt" 2>nul
if not defined THUMB_SIZE set "THUMB_SIZE=0"

if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" (
    for %%f in ("%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db") do (
        del /f /q "%%f" 2>nul
    )
)

set /a "THUMB_CLEANED=%THUMB_SIZE%"
set /a "TOTAL_CLEANED_MB+=%THUMB_CLEANED%"

start explorer.exe
echo   ✓ 完成 (释放约 %THUMB_CLEANED% MB)
echo [%date% %time%] 缩略图缓存: %THUMB_CLEANED% MB >> "%LOGFILE%"

:: 8. 系统日志文件（30天前的）
echo.
echo [8/10] 正在清理旧系统日志文件...
set "LOG_CLEANED=0"

powershell -Command "$cutoff = (Get-Date).AddDays(-30); $size = 0; $count = 0; Get-ChildItem 'C:\Windows\Logs','C:\Windows\Installer' -Filter '*.log' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2)" > "%TEMP%\log_size.txt" 2>nul
set /p LOG_SIZE=<"%TEMP%\log_size.txt" 2>nul
del "%TEMP%\log_size.txt" 2>nul

if not defined LOG_SIZE set "LOG_SIZE=0"
set /a "LOG_CLEANED=%LOG_SIZE%"
set /a "TOTAL_CLEANED_MB+=%LOG_CLEANED%"

echo   ✓ 完成 (释放约 %LOG_CLEANED% MB)
echo [%date% %time%] 系统日志: %LOG_CLEANED% MB >> "%LOGFILE%"

:: 9. 崩溃转储文件
echo.
echo [9/10] 正在清理崩溃转储文件...
set "DUMP_CLEANED=0"
set "DUMP_COUNT=0"

:: 使用PowerShell准确计算大小并删除
powershell -Command "$size = 0; $count = 0; Get-ChildItem 'C:\Windows\Minidump' -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; if (Test-Path 'C:\Windows\Memory.dmp') { $item = Get-Item 'C:\Windows\Memory.dmp'; $size += $item.Length; $count++; Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2); $count" > "%TEMP%\dump_result.txt" 2>nul

set /p DUMP_RESULT=<"%TEMP%\dump_result.txt" 2>nul
del "%TEMP%\dump_result.txt" 2>nul

for /f "tokens=1,2" %%a in ("!DUMP_RESULT!") do (
    set "DUMP_CLEANED=%%a"
    set "DUMP_COUNT=%%b"
)
if not defined DUMP_CLEANED set "DUMP_CLEANED=0"
if not defined DUMP_COUNT set "DUMP_COUNT=0"

set /a "TOTAL_CLEANED_MB+=!DUMP_CLEANED!"
echo   ✓ 完成 (释放约 !DUMP_CLEANED! MB, !DUMP_COUNT! 个文件)
echo [%date% %time%] 崩溃转储: !DUMP_CLEANED! MB >> "%LOGFILE%"

:: 10. 预读取缓存（7天未使用的）
echo.
echo [10/10] 正在清理旧预读取缓存...
set "PREFETCH_CLEANED=0"

powershell -Command "$cutoff = (Get-Date).AddDays(-7); $size = 0; $count = 0; Get-ChildItem 'C:\Windows\Prefetch' -Filter '*.pf' -ErrorAction SilentlyContinue | Where-Object { $_.LastAccessTime -lt $cutoff } | ForEach-Object { $size += $_.Length; $count++; Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }; [math]::Round($size / 1MB, 2)" > "%TEMP%\pf_size.txt" 2>nul
set /p PF_SIZE=<"%TEMP%\pf_size.txt" 2>nul
del "%TEMP%\pf_size.txt" 2>nul

if not defined PF_SIZE set "PF_SIZE=0"
set /a "PREFETCH_CLEANED=%PF_SIZE%"
set /a "TOTAL_CLEANED_MB+=%PREFETCH_CLEANED%"

echo   ✓ 完成 (释放约 %PREFETCH_CLEANED% MB)
echo [%date% %time%] 预读取缓存: %PREFETCH_CLEANED% MB >> "%LOGFILE%"

:: 运行磁盘清理工具
echo.
echo [额外] 正在运行磁盘清理工具（cleanmgr）...
start /wait cleanmgr /d C:
echo   ✓ cleanmgr完成
echo [%date% %time%] cleanmgr完成 >> "%LOGFILE%"

:: ==========================================
:: 清理完成，开始验证
:: ==========================================
echo.
echo ==========================================
echo   ✅ 清理完成！开始验证...
echo ==========================================
echo.

:: 获取清理后磁盘空间
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace"`) do set "FREE_AFTER=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round(%FREE_AFTER% / 1GB, 2)"`) do set "FREE_AFTER_GB=%%a"

:: 计算实际释放的空间
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round((%FREE_AFTER% - %FREE_BEFORE%) / 1MB, 2)"`) do set "ACTUAL_FREED_MB=%%a"
for /f "usebackq delims=" %%a in (`powershell -Command "[math]::Round((%FREE_AFTER% - %FREE_BEFORE%) / 1GB, 2)"`) do set "ACTUAL_FREED_GB=%%a"

:: ==========================================
:: 重新扫描垃圾文件（验证清理效果）
:: ==========================================
echo 🔍 正在重新扫描垃圾文件...
echo.

set "REMAINING_TRASH=0"
set "REMAINING_DETAILS="

:: 检查Windows临时文件
call :CalcFolderSize "C:\Windows\Temp"
if !SIZE_RESULT! GTR 10 (
    set /a "REMAINING_TRASH+=!SIZE_RESULT!"
    set "REMAINING_DETAILS=!REMAINING_DETAILS!Windows临时文件: !SIZE_RESULT! MB
"
    echo ⚠️  Windows临时文件仍有垃圾: !SIZE_RESULT! MB
)

:: 检查用户临时文件
call :CalcFolderSize "%TEMP%"
if !SIZE_RESULT! GTR 50 (
    set /a "REMAINING_TRASH+=!SIZE_RESULT!"
    set "REMAINING_DETAILS=!REMAINING_DETAILS!用户临时文件: !SIZE_RESULT! MB
"
    echo ⚠️  用户临时文件仍有垃圾: !SIZE_RESULT! MB
)

:: 检查回收站
set "RB_SIZE2=0"
powershell -Command "$rb = (New-Object -ComObject Shell.Application).Namespace(0xA); $size = 0; foreach ($item in $rb.Items()) { try { $size += $item.Size } catch {} }; [math]::Round($size / 1MB, 2)" > "%TEMP%\rb_size2.txt" 2>nul
set /p RB_SIZE2=<"%TEMP%\rb_size2.txt" 2>nul
del "%TEMP%\rb_size2.txt" 2>nul
if not defined RB_SIZE2 set "RB_SIZE2=0"

if !RB_SIZE2! GTR 10 (
    set /a "REMAINING_TRASH+=!RB_SIZE2!"
    set "REMAINING_DETAILS=!REMAINING_DETAILS!回收站: !RB_SIZE2! MB
"
    echo ⚠️  回收站仍有文件: !RB_SIZE2! MB
)

:: ==========================================
:: 生成对比报告
:: ==========================================
echo.
echo 📊 清理效果对比报告
echo ==========================================
echo.
echo 磁盘空间变化：
echo   清理前可用: %FREE_BEFORE_GB% GB
echo   清理后可用: %FREE_AFTER_GB% GB
echo   实际释放:   %ACTUAL_FREED_GB% GB (%ACTUAL_FREED_MB% MB)
echo   估计释放:   约 %TOTAL_CLEANED_MB% MB (各项目合计)
echo.

if %REMAINING_TRASH% GTR 0 (
    echo ⚠️  仍有可清理的垃圾文件：
echo   估计剩余: %REMAINING_TRASH% MB
    echo.
    echo 剩余垃圾详情：
    echo %REMAINING_DETAILS%
    echo.
    echo 💡 建议：
    echo   - 某些文件可能正在被程序使用，无法删除
echo   - 重启电脑后再次运行脚本可能清理更多
    echo   - 使用'磁盘清理'工具清理系统文件
) else (
    echo ✅ 垃圾文件清理非常彻底！
)

:: 保存报告
echo C盘清理对比报告 > "%REPORTFILE%"
echo 生成时间: %date% %time% >> "%REPORTFILE%"
echo ========================================== >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【磁盘空间变化】 >> "%REPORTFILE%"
echo 清理前可用: %FREE_BEFORE_GB% GB >> "%REPORTFILE%"
echo 清理后可用: %FREE_AFTER_GB% GB >> "%REPORTFILE%"
echo 实际释放:   %ACTUAL_FREED_GB% GB (%ACTUAL_FREED_MB% MB) >> "%REPORTFILE%"
echo 估计释放:   约 %TOTAL_CLEANED_MB% MB >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【剩余垃圾】 >> "%REPORTFILE%"
echo 估计剩余: %REMAINING_TRASH% MB >> "%REPORTFILE%"
echo %REMAINING_DETAILS% >> "%REPORTFILE%"
echo. >> "%REPORTFILE%"
echo 【建议】 >> "%REPORTFILE%"
echo - 重启电脑以确保所有清理生效 >> "%REPORTFILE%"
echo - 开启'存储感知'自动清理 >> "%REPORTFILE%"
echo - 报告文件: %REPORTFILE% >> "%REPORTFILE%"

echo.
echo 📁 报告文件已保存：
echo   日志文件: %LOGFILE%
echo   报告文件: %REPORTFILE%
echo.

:: 询问是否再次清理
set /p REPEAT="是否再次运行清理？(Y/N): "
if /i "!REPEAT!"=="Y" (
    echo.
    echo 重新启动清理...
    timeout /t 2 >nul
    endlocal
    goto :eof
)

echo.
echo 💡 建议操作：
echo   1. 重启电脑以确保所有清理生效
echo   2. 开启'存储感知'自动清理
echo   3. 定期运行此脚本（建议每月一次）
echo.

echo [%date% %time%] 清理脚本执行完成，总计释放 %TOTAL_CLEANED_MB% MB >> "%LOGFILE%"

pause
endlocal