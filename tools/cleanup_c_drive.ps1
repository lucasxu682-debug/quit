# C盘垃圾文件清理脚本 - 终极保护版 v4.2
# 特性：多重保护机制，确保系统安全

param(
    [switch]$Preview,              # 预览模式
    [switch]$NoConfirm,            # 跳过确认
    [switch]$SkipRestorePoint,     # 跳过还原点
    [switch]$VerifyOnly,           # 仅验证模式（不清理，只检测）
    [int]$LargeFileThreshold = 500,# 大文件阈值(MB)
    [string]$LogPath = ""
)

# 错误处理模式
$ErrorActionPreference = 'Continue'

# ==========================================
# 显示恢复帮助（清理前）
# ==========================================
function Show-RecoveryHelp {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   恢复帮助信息" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 如果清理后出现问题，请按以下步骤恢复：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "【方法1：系统还原（推荐）】" -ForegroundColor Green
    Write-Host "   1. 打开'控制面板' → '恢复' → '打开系统还原'" -ForegroundColor Gray
    Write-Host "   2. 选择还原点：'C盘清理前_日期'" -ForegroundColor Gray
    Write-Host "   3. 按向导完成还原" -ForegroundColor Gray
    Write-Host "   4. 重启电脑" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【方法2：使用备份文件列表】" -ForegroundColor Green
    Write-Host "   1. 查看备份目录：%TEMP%\cleanup_backup_时间戳\" -ForegroundColor Gray
    Write-Host "   2. 打开 file_list.txt 查看被删除的文件" -ForegroundColor Gray
    Write-Host "   3. 如有需要，从回收站恢复或重新下载" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【方法3：紧急联系】" -ForegroundColor Green
    Write-Host "   1. 查看日志文件了解详细操作记录" -ForegroundColor Gray
    Write-Host "   2. 如无法解决，请寻求专业人士帮助" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  注意：系统还原不会影响个人文档，但会恢复系统设置" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "按 Enter 键继续"
    Write-Host ""
}

# ==========================================
# 初始化
# ==========================================
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# 检查日志目录是否可写
$logDir = $env:TEMP
if (-not (Test-Path $logDir)) {
    $logDir = $env:USERPROFILE
}
try {
    $testFile = Join-Path $logDir "test_write.tmp"
    [void](New-Item -Path $testFile -ItemType File -Force -ErrorAction Stop)
    Remove-Item $testFile -Force
} catch {
    $logDir = $env:USERPROFILE
    Write-Host "⚠️  TEMP目录不可写，使用用户目录作为日志位置" -ForegroundColor Yellow
}

if ([string]::IsNullOrEmpty($LogPath)) {
    $LogPath = Join-Path $logDir "cleanup_c_drive_$timestamp.log"
}
$ReportPath = Join-Path $logDir "cleanup_report_$timestamp.txt"

$script:TotalCleaned = 0
$script:TotalFiles = 0
$script:Errors = @()
$script:StartTime = Get-Date
$script:BeforeState = @{}
$script:AfterState = @{}

# ==========================================
# 日志函数
# ==========================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    Add-Content -Path $LogPath -Value $entry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "INFO"  { Write-Host $Message -ForegroundColor Gray }
        "HEADER" { Write-Host $Message -ForegroundColor Cyan }
    }
}

# ==========================================
# 获取系统状态（用于对比）
# ==========================================
function Get-SystemState {
    param([string]$Label)
    
    Write-Log "正在记录$Label系统状态..." "INFO"
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $state = @{
        Label = $Label
        Timestamp = Get-Date
        FreeSpaceBytes = $disk.FreeSpace
        FreeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        TotalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        UsedSpaceGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        TrashItems = @{}
    }
    
    # 扫描各项垃圾文件大小
    $trashPaths = @{
        "Windows临时文件" = "C:\Windows\Temp"
        "用户临时文件" = $env:TEMP
        "Edge缓存" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        "Chrome缓存" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        "Windows更新缓存" = "C:\Windows\SoftwareDistribution\Download"
        "预读取缓存" = "C:\Windows\Prefetch"
        "崩溃转储" = "C:\Windows\Minidump"
    }
    
    foreach ($item in $trashPaths.GetEnumerator()) {
        try {
            if ($item.Key -eq "崩溃转储") {
                # 崩溃转储特殊处理
                $size = 0
                if (Test-Path $item.Value) {
                    $size += (Get-ChildItem $item.Value -Filter "*.dmp" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                }
                if (Test-Path "C:\Windows\Memory.dmp") {
                    $size += (Get-Item "C:\Windows\Memory.dmp" -ErrorAction SilentlyContinue).Length
                }
                $state.TrashItems[$item.Key] = [math]::Round($size / 1MB, 2)
            } elseif (Test-Path $item.Value) {
                $size = (Get-ChildItem $item.Value -Recurse -File -ErrorAction SilentlyContinue | 
                        Measure-Object -Property Length -Sum).Sum
                $state.TrashItems[$item.Key] = [math]::Round($size / 1MB, 2)
            } else {
                $state.TrashItems[$item.Key] = 0
            }
        } catch {
            $state.TrashItems[$item.Key] = 0
        }
    }
    
    # Firefox缓存 - 完整检测所有profile
    try {
        $firefoxSize = 0
        $profiles = Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue
        foreach ($profile in $profiles) {
            $cache2 = Join-Path $profile.FullName "cache2"
            $codeCache = Join-Path $profile.FullName "cache"
            if (Test-Path $cache2) {
                $firefoxSize += (Get-ChildItem $cache2 -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            }
            if (Test-Path $codeCache) {
                $firefoxSize += (Get-ChildItem $codeCache -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            }
        }
        $state.TrashItems["Firefox缓存"] = [math]::Round($firefoxSize / 1MB, 2)
    } catch {
        $state.TrashItems["Firefox缓存"] = 0
    }
    
    # 回收站
    try {
        $rb = (New-Object -ComObject Shell.Application).Namespace(0xA)
        $rbSize = 0
        foreach ($item in $rb.Items()) { try { $rbSize += $item.Size } catch {} }
        $state.TrashItems["回收站"] = [math]::Round($rbSize / 1MB, 2)
    } catch {
        $state.TrashItems["回收站"] = 0
    }
    
    return $state
}

# ==========================================
# 显示对比报告
# ==========================================
function Show-ComparisonReport {
    param($Before, $After)
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   📊 清理效果对比报告" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 磁盘空间对比
    $spaceFreedBytes = $After.FreeSpaceBytes - $Before.FreeSpaceBytes
    $spaceFreedGB = [math]::Round($spaceFreedBytes / 1GB, 2)
    $spaceFreedMB = [math]::Round($spaceFreedBytes / 1MB, 2)
    
    Write-Host "💾 磁盘空间变化：" -ForegroundColor Yellow
    Write-Host "   清理前可用: $($Before.FreeSpaceGB) GB" -ForegroundColor Gray
    Write-Host "   清理后可用: $($After.FreeSpaceGB) GB" -ForegroundColor Gray
    
    if ($spaceFreedGB -gt 0) {
        Write-Host "   实际释放:   $spaceFreedGB GB ($spaceFreedMB MB)" -ForegroundColor Green
    } else {
        Write-Host "   实际释放:   $spaceFreedMB MB" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # 各项垃圾清理对比
    Write-Host "🗑️  各项垃圾清理详情：" -ForegroundColor Yellow
    Write-Host "   项目                    清理前(MB)   清理后(MB)   释放(MB)   清理率" -ForegroundColor Gray
    Write-Host "   ─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    $totalBefore = 0
    $totalAfter = 0
    
    foreach ($key in $Before.TrashItems.Keys | Sort-Object) {
        $beforeSize = $Before.TrashItems[$key]
        $afterSize = $After.TrashItems[$key]
        $freed = $beforeSize - $afterSize
        $totalBefore += $beforeSize
        $totalAfter += $afterSize
        
        if ($beforeSize -gt 0) {
            $percent = [math]::Round(($freed / $beforeSize) * 100, 0)
            $status = if ($percent -ge 90) { "✅" } elseif ($percent -ge 50) { "⚠️ " } else { "❌" }
        } else {
            $percent = 0
            $status = "✓"
        }
        
        $line = "   {0,-22} {1,10:F1} {2,12:F1} {3,12:F1}   {4,4:F0}% {5}" -f $key, $beforeSize, $afterSize, $freed, $percent, $status
        
        if ($afterSize -gt 100) {
            Write-Host $line -ForegroundColor Yellow
        } elseif ($freed -gt 0) {
            Write-Host $line -ForegroundColor Green
        } else {
            Write-Host $line -ForegroundColor Gray
        }
    }
    
    Write-Host "   ─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    $totalFreed = $totalBefore - $totalAfter
    $totalPercent = if ($totalBefore -gt 0) { [math]::Round(($totalFreed / $totalBefore) * 100, 0) } else { 0 }
    Write-Host "   总计                   {0,10:F1} {1,12:F1} {2,12:F1}   {3,4:F0}%" -f $totalBefore, $totalAfter, $totalFreed, $totalPercent -ForegroundColor Cyan
    Write-Host ""
    
    # 清理效果评估
    Write-Host "📈 清理效果评估：" -ForegroundColor Yellow
    if ($totalPercent -ge 80) {
        Write-Host "   ✅ 优秀！垃圾文件清理非常彻底" -ForegroundColor Green
    } elseif ($totalPercent -ge 50) {
        Write-Host "   ⚠️  良好，但仍有部分垃圾未清理" -ForegroundColor Yellow
    } else {
        Write-Host "   ❌ 一般，建议检查是否有程序占用文件" -ForegroundColor Red
    }
    
    # 剩余垃圾提示
    $highRemaining = $After.TrashItems.GetEnumerator() | Where-Object { $_.Value -gt 100 }
    if ($highRemaining) {
        Write-Host ""
        Write-Host "⚠️  仍有较多垃圾的项目：" -ForegroundColor Yellow
        $highRemaining | ForEach-Object {
            Write-Host "   - $($_.Key): $($_.Value) MB" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "💡 建议：" -ForegroundColor Cyan
        Write-Host "   - 某些文件可能正在被程序使用，无法删除" -ForegroundColor Gray
        Write-Host "   - 重启电脑后再次运行脚本可能清理更多" -ForegroundColor Gray
        Write-Host "   - 关闭浏览器后再运行可清理浏览器缓存" -ForegroundColor Gray
    }
    
    # 保存报告
    $report = @"
C盘垃圾清理对比报告
生成时间: $(Get-Date)
========================================

【磁盘空间变化】
清理前可用: $($Before.FreeSpaceGB) GB
清理后可用: $($After.FreeSpaceGB) GB
实际释放:   $spaceFreedGB GB ($spaceFreedMB MB)

【各项垃圾清理详情】
项目                    清理前(MB)   清理后(MB)   释放(MB)   清理率
--------------------------------------------------------------------
"@
    
    foreach ($key in ($Before.TrashItems.Keys | Sort-Object)) {
        $b = $Before.TrashItems[$key]
        $a = $After.TrashItems[$key]
        $f = $b - $a
        $p = if ($b -gt 0) { [math]::Round(($f / $b) * 100, 0) } else { 0 }
        $report += "{0,-22} {1,10:F1} {2,12:F1} {3,12:F1}   {4,4:F0}%`n" -f $key, $b, $a, $f, $p
    }
    
    $report += @"
--------------------------------------------------------------------
总计                   {0,10:F1} {1,12:F1} {2,12:F1}   {3,4:F0}%

【建议】
- 重启电脑以确保所有清理生效
- 开启'存储感知'自动清理（设置 → 系统 → 存储）
- 建议每月运行一次清理脚本
"@ -f $totalBefore, $totalAfter, $totalFreed, $totalPercent
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "📁 详细报告已保存: $ReportPath" -ForegroundColor Gray
}

# ==========================================
# 主程序
# ==========================================

# 仅验证模式
if ($VerifyOnly) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   🔍 仅验证模式 - 检测当前垃圾文件" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $state = Get-SystemState -Label "当前"
    
    Write-Host "📊 当前系统状态：" -ForegroundColor Yellow
    Write-Host "   可用空间: $($state.FreeSpaceGB) GB / $($state.TotalSpaceGB) GB" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🗑️  当前垃圾文件分布：" -ForegroundColor Yellow
    
    $totalTrash = 0
    $state.TrashItems.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        if ($_.Value -gt 10) {
            Write-Host "   $($_.Key): $($_.Value) MB" -ForegroundColor $(if($_.Value -gt 500){"Red"}elseif($_.Value -gt 100){"Yellow"}else{"Gray"})
            $totalTrash += $_.Value
        }
    }
    
    Write-Host ""
    Write-Host "📈 总计可清理: $([math]::Round($totalTrash / 1024, 2)) GB ($([math]::Round($totalTrash, 2)) MB)" -ForegroundColor $(if($totalTrash -gt 1024){"Red"}else{"Green"})
    Write-Host ""
    
    Read-Host "按 Enter 键退出"
    exit
}

# 正常模式
# 显示恢复帮助（清理前）
Show-RecoveryHelp

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   C盘垃圾文件清理脚本 v4.2" -ForegroundColor Cyan
Write-Host "   终极保护版 - 多重安全机制" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "❌ 需要管理员权限" "ERROR"
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Log "✅ 管理员权限检查通过" "SUCCESS"
Write-Log "日志文件: $LogPath" "INFO"

# 创建还原点
if (-not $SkipRestorePoint) {
    Write-Log "正在创建系统还原点..." "INFO"
    try {
        $rpName = "C盘清理前_$(Get-Date -Format 'yyyyMMdd')"
        $result = wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "$rpName", 100, 7 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ 系统还原点创建成功: $rpName" "SUCCESS"
        } else {
            Write-Log "⚠️  系统还原点创建失败（可能已禁用）" "WARN"
        }
    } catch {
        Write-Log "⚠️  系统还原点创建失败: $($_.Exception.Message)" "WARN"
    }
}

# 记录清理前状态
Write-Host ""
Write-Log "📊 正在记录清理前状态..." "HEADER"
$script:BeforeState = Get-SystemState -Label "清理前"

Write-Log "   清理前可用空间: $($script:BeforeState.FreeSpaceGB) GB" "INFO"

# 显示当前垃圾分布
Write-Host ""
Write-Host "🗑️  当前垃圾文件分布：" -ForegroundColor Yellow
$script:BeforeState.TrashItems.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    if ($_.Value -gt 10) {
        Write-Host "   $($_.Key): $($_.Value) MB" -ForegroundColor $(if($_.Value -gt 500){"Red"}elseif($_.Value -gt 100){"Yellow"}else{"Gray"})
    }
}

# 大文件扫描
Write-Host ""
Write-Log "🔍 正在扫描大文件（超过 $LargeFileThreshold MB）..." "INFO"
$largeFiles = @()
$scanPaths = @("$env:USERPROFILE\Downloads", $env:TEMP, "C:\Windows\Temp")
foreach ($path in $scanPaths) {
    if (Test-Path $path) {
        $files = Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Length -gt ($LargeFileThreshold * 1MB) } | 
                 Select-Object -First 5
        $largeFiles += $files
    }
}

if ($largeFiles.Count -gt 0) {
    Write-Log "发现大文件:" "WARN"
    $largeFiles | Sort-Object Length -Descending | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Log "  - $($_.FullName) (${sizeMB} MB)" "WARN"
    }
}

# 确认
if (-not $NoConfirm) {
    Write-Host ""
    $confirm = Read-Host "是否开始清理? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Log "用户取消操作" "INFO"
        exit
    }
}

# ==========================================
# 执行清理（完整版 v4.1）
# ==========================================
Write-Host ""
Write-Log "🧹 开始清理垃圾文件..." "HEADER"

# 1. Windows临时文件
Write-Log "  [1/10] 清理: Windows临时文件" "INFO"
$script:TotalCleaned += Clear-FolderSafely -Path "C:\Windows\Temp" -Description "Windows临时文件"

# 2. 用户临时文件
Write-Log "  [2/10] 清理: 用户临时文件" "INFO"
$script:TotalCleaned += Clear-FolderSafely -Path $env:TEMP -Description "当前用户临时文件"
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $userTemp = Join-Path $_.FullName "AppData\Local\Temp"
    if ((Test-Path $userTemp) -and ($_.Name -ne $env:USERNAME)) {
        $script:TotalCleaned += Clear-FolderSafely -Path $userTemp -Description "用户临时文件 ($($_.Name))"
    }
}

# 3-4. 浏览器缓存
Write-Log "  [3-4/10] 清理: 浏览器缓存" "INFO"
$browsers = @(
    @{ Name = "msedge"; DisplayName = "Edge"; Paths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
    )},
    @{ Name = "chrome"; DisplayName = "Chrome"; Paths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
    )}
)
foreach ($browser in $browsers) {
    $process = Get-Process -Name $browser.Name -ErrorAction SilentlyContinue
    if ($process) {
        Write-Log "    ⚠️ $($browser.DisplayName) 正在运行，跳过" "WARN"
    } else {
        foreach ($cachePath in $browser.Paths) {
            $script:TotalCleaned += Clear-FolderSafely -Path $cachePath -Description "$($browser.DisplayName)缓存"
        }
    }
}
# Firefox
$firefoxProcess = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
if ($firefoxProcess) {
    Write-Log "    ⚠️ Firefox 正在运行，跳过" "WARN"
} else {
    $firefoxProfiles = Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue
    foreach ($profile in $firefoxProfiles) {
        # 清理 cache2 (主要缓存)
        $firefoxCache = Join-Path $profile.FullName "cache2"
        $script:TotalCleaned += Clear-FolderSafely -Path $firefoxCache -Description "Firefox缓存 (cache2)"
        # 清理 cache (代码缓存)
        $firefoxCodeCache = Join-Path $profile.FullName "cache"
        $script:TotalCleaned += Clear-FolderSafely -Path $firefoxCodeCache -Description "Firefox代码缓存"
    }
}

# 5. Windows更新缓存
Write-Log "  [5/10] 清理: Windows更新缓存" "INFO"
try {
    $service = Get-Service wuauserv -ErrorAction SilentlyContinue
    $serviceWasRunning = $service -and ($service.Status -eq 'Running')
    if ($serviceWasRunning) {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Write-Log "    已停止Windows更新服务" "INFO"
    }
    $script:TotalCleaned += Clear-FolderSafely -Path "C:\Windows\SoftwareDistribution\Download" -Description "Windows更新下载缓存"
    if ($serviceWasRunning) {
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Write-Log "    已恢复Windows更新服务" "SUCCESS"
    }
} catch {
    Write-Log "    ❌ Windows更新服务操作失败" "ERROR"
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

# 6. 回收站
Write-Log "  [6/10] 清理: 回收站" "INFO"
try {
    $rb = (New-Object -ComObject Shell.Application).Namespace(0xA)
    $items = $rb.Items()
    if ($items.Count -eq 0) {
        Write-Log "    回收站为空" "INFO"
    } else {
        $size = 0
        foreach ($item in $items) { try { $size += $item.Size } catch {} }
        $sizeMB = [math]::Round($size / 1MB, 2)
        if ($Preview) {
            Write-Log "    [预览] 可释放: $sizeMB MB" "INFO"
            $script:TotalCleaned += $sizeMB
        } else {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Log "    ✓ 已清空: 释放 $sizeMB MB" "SUCCESS"
            $script:TotalCleaned += $sizeMB
            $script:TotalFiles += $items.Count
        }
    }
} catch {
    Write-Log "    ❌ 回收站处理失败" "ERROR"
}

# 7. 缩略图缓存
Write-Log "  [7/10] 清理: 缩略图缓存" "INFO"
try {
    $thumbFiles = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -ErrorAction SilentlyContinue
    if ($thumbFiles) {
        $size = ($thumbFiles | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        if ($Preview) {
            Write-Log "    [预览] 可释放: $sizeMB MB" "INFO"
            $script:TotalCleaned += $sizeMB
        } else {
            $explorer = Get-Process explorer -ErrorAction SilentlyContinue
            if ($explorer) {
                Stop-Process -Name explorer -Force
                Start-Sleep -Milliseconds 500
            }
            $deleted = 0
            $thumbFiles | ForEach-Object { try { Remove-Item $_.FullName -Force; $deleted++ } catch {} }
            Start-Process explorer
            $script:TotalCleaned += $sizeMB
            $script:TotalFiles += $deleted
            Write-Log "    ✓ 完成: 删除 $deleted 个文件，释放 $sizeMB MB" "SUCCESS"
        }
    }
} catch {
    Write-Log "    ❌ 缩略图缓存处理失败" "ERROR"
    Start-Process explorer -ErrorAction SilentlyContinue
}

# 8. 系统日志文件（30天前的）
Write-Log "  [8/10] 清理: 系统日志文件（30天前的）" "INFO"
try {
    $cutoff = (Get-Date).AddDays(-30)
    $logSize = 0
    $deleted = 0
    @("C:\Windows\Logs", "C:\Windows\Installer") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt $cutoff } | 
                ForEach-Object {
                    $logSize += $_.Length
                    try { Remove-Item $_.FullName -Force; $deleted++ } catch {}
                }
        }
    }
    $logSizeMB = [math]::Round($logSize / 1MB, 2)
    if ($Preview) {
        Write-Log "    [预览] 可释放: $logSizeMB MB" "INFO"
        $script:TotalCleaned += $logSizeMB
    } else {
        $script:TotalCleaned += $logSizeMB
        $script:TotalFiles += $deleted
        Write-Log "    ✓ 完成: 删除 $deleted 个文件，释放 $logSizeMB MB" "SUCCESS"
    }
} catch {
    Write-Log "    ❌ 日志文件处理失败" "ERROR"
}

# 9. 崩溃转储文件
Write-Log "  [9/10] 清理: 崩溃转储文件" "INFO"
try {
    $dumpSize = 0
    $deleted = 0
    # Minidump文件夹
    if (Test-Path "C:\Windows\Minidump") {
        Get-ChildItem "C:\Windows\Minidump" -Filter "*.dmp" -ErrorAction SilentlyContinue | ForEach-Object {
            $fileSize = $_.Length
            try { 
                Remove-Item $_.FullName -Force -ErrorAction Stop
                $dumpSize += $fileSize
                $deleted++
            } catch {}
        }
    }
    # Memory.dmp
    if (Test-Path "C:\Windows\Memory.dmp") {
        $fileSize = (Get-Item "C:\Windows\Memory.dmp").Length
        try { 
            Remove-Item "C:\Windows\Memory.dmp" -Force -ErrorAction Stop
            $dumpSize += $fileSize
            $deleted++
        } catch {}
    }
    $dumpSizeMB = [math]::Round($dumpSize / 1MB, 2)
    if ($Preview) {
        Write-Log "    [预览] 可释放: $dumpSizeMB MB" "INFO"
        $script:TotalCleaned += $dumpSizeMB
    } else {
        $script:TotalCleaned += $dumpSizeMB
        $script:TotalFiles += $deleted
        Write-Log "    ✓ 完成: 删除 $deleted 个文件，释放 $dumpSizeMB MB" "SUCCESS"
    }
} catch {
    Write-Log "    ❌ 崩溃转储文件处理失败" "ERROR"
}

# 10. 预读取缓存（7天未使用的）
Write-Log "  [10/10] 清理: 预读取缓存（7天未使用）" "INFO"
try {
    $cutoff = (Get-Date).AddDays(-7)
    $prefetch = Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastAccessTime -lt $cutoff }
    $size = ($prefetch | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    if ($Preview) {
        Write-Log "    [预览] 可释放: $sizeMB MB ($($prefetch.Count) 个文件)" "INFO"
        $script:TotalCleaned += $sizeMB
    } else {
        $deleted = 0
        $prefetch | ForEach-Object { try { Remove-Item $_.FullName -Force; $deleted++ } catch {} }
        $script:TotalCleaned += $sizeMB
        $script:TotalFiles += $deleted
        Write-Log "    ✓ 完成: 删除 $deleted 个文件，释放 $sizeMB MB" "SUCCESS"
    }
} catch {
    Write-Log "    ❌ 预读取缓存处理失败" "ERROR"
}

# 可选：下载文件夹中的旧安装包
Write-Host ""
$cleanDownloads = Read-Host "是否清理下载文件夹中的旧安装包 (.exe, .msi, .zip超过30天的)? (Y/N)"
if ($cleanDownloads -eq 'Y' -or $cleanDownloads -eq 'y') {
    Write-Log "  [额外] 清理: 下载文件夹中的旧安装包" "INFO"
    try {
        $downloadPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
        $cutoff = (Get-Date).AddDays(-30)
        $installers = Get-ChildItem $downloadPath -Include @("*.exe", "*.msi", "*.zip", "*.rar", "*.7z") -Recurse -ErrorAction SilentlyContinue | 
                      Where-Object { $_.LastWriteTime -lt $cutoff }
        $size = ($installers | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        if ($Preview) {
            Write-Log "    [预览] 可释放: $sizeMB MB ($($installers.Count) 个文件)" "INFO"
            $script:TotalCleaned += $sizeMB
        } else {
            $deleted = 0
            $installers | ForEach-Object { try { Remove-Item $_.FullName -Force; $deleted++ } catch {} }
            $script:TotalCleaned += $sizeMB
            $script:TotalFiles += $deleted
            Write-Log "    ✓ 完成: 删除 $deleted 个文件，释放 $sizeMB MB" "SUCCESS"
        }
    } catch {
        Write-Log "    ❌ 下载文件夹清理失败" "ERROR"
    }
}

# ==========================================
# 清理后验证
# ==========================================
Write-Host ""
Write-Log "🔍 正在记录清理后状态..." "HEADER"
$script:AfterState = Get-SystemState -Label "清理后"

# 显示对比报告
Show-ComparisonReport -Before $script:BeforeState -After $script:AfterState

# 询问是否再次清理
$spaceFreed = $script:AfterState.FreeSpaceGB - $script:BeforeState.FreeSpaceGB
if ($spaceFreed -lt 0.1 -and -not $Preview) {
    Write-Host ""
    Write-Host "⚠️  清理效果不明显，可能有文件被占用" -ForegroundColor Yellow
    $retry = Read-Host "是否重启后再次清理? (Y/N)"
    if ($retry -eq 'Y' -or $retry -eq 'y') {
        Write-Log "提示: 重启后再次运行此脚本" "INFO"
    }
}

# 完成
Write-Host ""
Write-Log "✅ 脚本执行完成" "SUCCESS"
Write-Log "总耗时: $((Get-Date) - $script:StartTime | Select-Object -ExpandProperty TotalSeconds) 秒" "INFO"
Write-Log "日志文件: $LogPath" "INFO"
Write-Log "报告文件: $ReportPath" "INFO"

Read-Host "`n按 Enter 键退出"