# C盘垃圾清理脚本 - 主控面板版 v5.1
# 交互式菜单，更友好的用户体验

# 初始化
$script:Version = "5.1"
$script:StartTime = Get-Date
$script:TotalCleaned = 0
$script:TotalFiles = 0
$script:LogPath = Join-Path $env:TEMP "cleanup_master_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:HistoryPath = "C:\Users\xumou\quit\memory\cleanup_history.json"

# 确保目录存在
if (-not (Test-Path "C:\Users\xumou\quit\memory")) {
    New-Item -Path "C:\Users\xumou\quit\memory" -ItemType Directory -Force | Out-Null
}

# 初始化日志
"==========================================" | Out-File -FilePath $script:LogPath -Encoding UTF8
"C盘清理脚本 v$script:Version - 执行日志" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
"开始时间: $(Get-Date)" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
"==========================================" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $entry -ErrorAction SilentlyContinue
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO"  { "Gray" }
        "HEADER" { "Cyan" }
    }
    Write-Host $Message -ForegroundColor $color
}

# 检查权限
function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ==========================================
# 检测系统信息
# ==========================================
function Get-SystemInfo {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $os = Get-CimInstance Win32_OperatingSystem
    
    # 检测SSD
    try {
        $physicalDisk = Get-PhysicalDisk | Where-Object { 
            $_.DeviceId -eq (Get-Partition -DriveLetter C | Get-Disk).Number 
        }
        $isSSD = ($physicalDisk.MediaType -eq "SSD" -or $physicalDisk.MediaType -eq "NVMe")
    } catch {
        $isSSD = $false
    }
    
    return @{
        TotalGB = [math]::Round($disk.Size / 1GB, 2)
        FreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        UsedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        PercentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
        IsSSD = $isSSD
        OSVersion = $os.Caption
    }
}

# ==========================================
# 显示主菜单
# ==========================================
function Show-MainMenu {
    param($SystemInfo)
    
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   🖥️  C盘清理工具 v$script:Version" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 系统状态
    $freeColor = if ($SystemInfo.PercentFree -lt 10) { "Red" } elseif ($SystemInfo.PercentFree -lt 20) { "Yellow" } else { "Green" }
    Write-Host "📊 系统状态:" -ForegroundColor Yellow
    Write-Host "   总容量: $($SystemInfo.TotalGB) GB" -ForegroundColor Gray
    Write-Host "   已使用: $($SystemInfo.UsedGB) GB" -ForegroundColor Gray
    Write-Host "   可用空间: $($SystemInfo.FreeGB) GB ($($SystemInfo.PercentFree)%)" -ForegroundColor $freeColor
    Write-Host "   磁盘类型: $(if($SystemInfo.IsSSD){'SSD 💾'}else{'HDD 💿'})" -ForegroundColor Gray
    Write-Host ""
    
    if ($SystemInfo.PercentFree -lt 10) {
        Write-Host "⚠️  警告：C盘空间严重不足！建议立即清理" -ForegroundColor Red
        Write-Host ""
    }
    
    # 历史记录
    if (Test-Path $script:HistoryPath) {
        try {
            $history = Get-Content $script:HistoryPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($history -is [array] -and $history.Count -gt 0) {
                $totalCleaned = ($history | Measure-Object SpaceFreedGB -Sum).Sum
                $lastCleanup = $history | Sort-Object Timestamp -Descending | Select-Object -First 1
                $daysSince = ([DateTime]::Now - [DateTime]::Parse($lastCleanup.Date)).Days
                
                Write-Host "📈 清理历史:" -ForegroundColor Yellow
                Write-Host "   累计清理: $($history.Count) 次，共 $([math]::Round($totalCleaned, 2)) GB" -ForegroundColor Gray
                Write-Host "   上次清理: $daysSince 天前" -ForegroundColor $(if($daysSince -gt 7){"Yellow"}else{"Green"})
                Write-Host ""
            }
        } catch {}
    }
    
    # 主菜单
    Write-Host "📋 主菜单:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [1] 🔍  磁盘空间分析" -ForegroundColor White
    Write-Host "   [2] 🧹  快速清理（推荐）" -ForegroundColor Green
    Write-Host "   [3] 🔧  深度清理" -ForegroundColor Cyan
    Write-Host "   [4] 📦  大文件清理" -ForegroundColor Yellow
    Write-Host "   [5] 💾  SSD优化$(if(-not $SystemInfo.IsSSD){' (非SSD)'})" -ForegroundColor $(if($SystemInfo.IsSSD){'Green'}else{'DarkGray'})
    Write-Host "   [6] 📊  查看清理历史" -ForegroundColor Gray
    Write-Host "   [7] ❓  帮助与说明" -ForegroundColor Gray
    Write-Host "   [0] 🚪  退出" -ForegroundColor Red
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
}

# ==========================================
# 功能1: 磁盘空间分析
# ==========================================
function Start-DiskAnalysis {
    Write-Host ""
    Write-Log "🔍 正在分析磁盘空间..." "HEADER"
    
    # 调用独立的分析器
    $analyzerPath = Join-Path $PSScriptRoot "disk_analyzer.ps1"
    if (Test-Path $analyzerPath) {
        & $analyzerPath
    } else {
        # 内置简单分析
        $folders = @(
            @{ Name = "Windows"; Path = "C:\Windows" },
            @{ Name = "Program Files"; Path = "C:\Program Files" },
            @{ Name = "用户数据"; Path = "C:\Users" }
        )
        
        foreach ($folder in $folders) {
            if (Test-Path $folder.Path) {
                $size = (Get-ChildItem $folder.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $sizeGB = [math]::Round($size / 1GB, 2)
                Write-Host "   $($folder.Name): $sizeGB GB" -ForegroundColor Gray
            }
        }
    }
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能2: 快速清理
# ==========================================
function Start-QuickCleanup {
    Write-Host ""
    Write-Log "🧹 开始快速清理..." "HEADER"
    
    $cleaned = 0
    
    # Windows临时文件
    Write-Log "  清理 Windows 临时文件..." "INFO"
    $before = (Get-ChildItem "C:\Windows\Temp" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem "C:\Windows\Temp" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $cleaned += ($before - $after)
    
    # 用户临时文件
    Write-Log "  清理用户临时文件..." "INFO"
    $before = (Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $cleaned += ($before - $after)
    
    # 回收站
    Write-Log "  清空回收站..." "INFO"
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "    ✓ 回收站已清空" "SUCCESS"
    } catch {
        Write-Log "    ⚠️ 回收站清理失败" "WARN"
    }
    
    $cleanedMB = [math]::Round($cleaned / 1MB, 2)
    Write-Log "✅ 快速清理完成，释放 $cleanedMB MB" "SUCCESS"
    
    # 保存历史
    Save-CleanupHistory -SpaceFreedMB $cleanedMB -Mode "Quick"
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能3: 深度清理
# ==========================================
function Start-DeepCleanup {
    Write-Host ""
    Write-Log "🔧 开始深度清理..." "HEADER"
    Write-Host "   这将清理更多项目，包括:" -ForegroundColor Gray
    Write-Host "   • Windows更新缓存" -ForegroundColor Gray
    Write-Host "   • 缩略图缓存" -ForegroundColor Gray
    Write-Host "   • 崩溃转储文件" -ForegroundColor Gray
    Write-Host "   • 浏览器缓存" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "确认执行深度清理? (Y/N)"
    if ($confirm -ne 'Y') { return }
    
    # 调用主清理脚本
    $masterPath = Join-Path $PSScriptRoot "cleanup_c_drive_master.ps1"
    if (Test-Path $masterPath) {
        & $masterPath -Deep
    } else {
        Write-Log "⚠️ 深度清理模块未找到" "WARN"
    }
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能4: 大文件清理
# ==========================================
function Start-LargeFilesCleanup {
    Write-Host ""
    Write-Log "📦 大文件清理..." "HEADER"
    
    $threshold = Read-Host "请输入大文件阈值(MB，默认100)"
    if ([string]::IsNullOrEmpty($threshold)) { $threshold = 100 }
    
    $toolPath = Join-Path $PSScriptRoot "large_files_cleanup.ps1"
    if (Test-Path $toolPath) {
        & $toolPath -SizeThresholdMB $threshold
    } else {
        Write-Log "⚠️ 大文件清理模块未找到" "WARN"
    }
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能5: SSD优化
# ==========================================
function Start-SSDOptimize {
    param($SystemInfo)
    
    Write-Host ""
    if (-not $SystemInfo.IsSSD) {
        Write-Log "⚠️ 当前磁盘不是SSD，SSD优化可能无效" "WARN"
        $continue = Read-Host "是否继续? (Y/N)"
        if ($continue -ne 'Y') { return }
    }
    
    Write-Log "💾 SSD优化..." "HEADER"
    
    $toolPath = Join-Path $PSScriptRoot "ssd_optimize.ps1"
    if (Test-Path $toolPath) {
        & $toolPath
    } else {
        Write-Log "⚠️ SSD优化模块未找到" "WARN"
    }
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能6: 查看历史
# ==========================================
function Show-CleanupHistory {
    Write-Host ""
    Write-Log "📊 清理历史..." "HEADER"
    
    $toolPath = Join-Path $PSScriptRoot "cleanup_history.ps1"
    if (Test-Path $toolPath) {
        & $toolPath -ShowReport
    } else {
        if (Test-Path $script:HistoryPath) {
            try {
                $history = Get-Content $script:HistoryPath -Raw | ConvertFrom-Json
                $history | Sort-Object Timestamp -Descending | Select-Object -First 10 | Format-Table Date, SpaceFreedGB, FilesDeleted, Mode -AutoSize
            } catch {
                Write-Log "无法读取历史记录" "ERROR"
            }
        } else {
            Write-Log "暂无历史记录" "INFO"
        }
    }
    
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 功能7: 帮助
# ==========================================
function Show-Help {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   ❓ 帮助与说明" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📌 功能说明:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 磁盘空间分析" -ForegroundColor White
    Write-Host "   分析C盘空间使用情况，找出占用最大的文件夹" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 快速清理" -ForegroundColor White
    Write-Host "   清理临时文件、回收站等，安全快速" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 深度清理" -ForegroundColor White
    Write-Host "   清理更多项目，释放更多空间" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. 大文件清理" -ForegroundColor White
    Write-Host "   扫描并清理大文件，可自定义阈值" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. SSD优化" -ForegroundColor White
    Write-Host "   针对SSD硬盘的特殊优化" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 建议:" -ForegroundColor Yellow
    Write-Host "   • 每周运行一次快速清理" -ForegroundColor Gray
    Write-Host "   • 每月运行一次深度清理" -ForegroundColor Gray
    Write-Host "   • 保持C盘至少有20%的可用空间" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Read-Host "`n按 Enter 键返回主菜单"
}

# ==========================================
# 保存历史记录
# ==========================================
function Save-CleanupHistory {
    param([double]$SpaceFreedMB, [string]$Mode)
    
    try {
        $history = @()
        if (Test-Path $script:HistoryPath) {
            $history = Get-Content $script:HistoryPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($history -isnot [array]) { $history = @($history) }
        }
        
        $newRecord = [PSCustomObject]@{
            Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            SpaceFreedMB = [math]::Round($SpaceFreedMB, 2)
            SpaceFreedGB = [math]::Round($SpaceFreedMB / 1024, 2)
            Mode = $Mode
        }
        
        $history += $newRecord
        if ($history.Count -gt 100) {
            $history = $history | Sort-Object Timestamp -Descending | Select-Object -First 100
        }
        
        $history | ConvertTo-Json -Depth 3 | Out-File -FilePath $script:HistoryPath -Encoding UTF8
    } catch {}
}

# ==========================================
# 主程序
# ==========================================

# 检查权限
if (-not (Test-AdminRights)) {
    Write-Host "❌ 需要管理员权限运行此脚本" -ForegroundColor Red
    Write-Host "   请右键点击脚本，选择'使用 PowerShell 运行'" -ForegroundColor Gray
    Read-Host "`n按 Enter 键退出"
    exit 1
}

# 获取系统信息
$systemInfo = Get-SystemInfo

# 主循环
while ($true) {
    Show-MainMenu -SystemInfo $systemInfo
    
    $choice = Read-Host "请选择操作 (0-7)"
    
    switch ($choice) {
        "1" { Start-DiskAnalysis }
        "2" { Start-QuickCleanup; $systemInfo = Get-SystemInfo }
        "3" { Start-DeepCleanup; $systemInfo = Get-SystemInfo }
        "4" { Start-LargeFilesCleanup }
        "5" { Start-SSDOptimize -SystemInfo $systemInfo }
        "6" { Show-CleanupHistory }
        "7" { Show-Help }
        "0" { 
            Write-Host ""
            Write-Host "感谢使用，再见！👋" -ForegroundColor Green
            Write-Host ""
            exit 0 
        }
        default {
            Write-Host ""
            Write-Host "❌ 无效选择，请重新输入" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
