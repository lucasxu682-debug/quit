# C盘垃圾清理脚本 - 终极整合版 v5.0
# 整合所有优化功能：清理 + 分析 + 大文件 + 历史 + SSD优化

param(
    [switch]$Quick,                  # 快速模式（只清理基本项目）
    [switch]$Deep,                   # 深度模式（包含所有高级功能）
    [switch]$Analyze,                # 仅分析模式
    [switch]$AutoClean,              # 自动清理（无交互）
    [switch]$Help                    # 显示帮助
)

# 显示帮助
if ($Help) {
    @"
C盘垃圾清理脚本 - 终极整合版 v5.0

使用方法:
  .\cleanup_c_drive_master.ps1              标准模式（推荐）
  .\cleanup_c_drive_master.ps1 -Quick       快速模式（只清理基本项目）
  .\cleanup_c_drive_master.ps1 -Deep        深度模式（包含所有高级功能）
  .\cleanup_c_drive_master.ps1 -Analyze     仅分析，不清理
  .\cleanup_c_drive_master.ps1 -AutoClean   自动清理（无交互）

功能模块:
  1. 基础清理 - 临时文件、缓存、回收站等
  2. 磁盘分析 - 可视化空间使用报告
  3. 大文件清理 - 智能识别和清理大文件
  4. 历史记录 - 记录清理效果，生成趋势
  5. SSD优化 - 针对SSD的特殊优化（如果是SSD）

示例:
  # 标准清理（推荐首次使用）
  .\cleanup_c_drive_master.ps1

  # 深度清理（释放更多空间）
  .\cleanup_c_drive_master.ps1 -Deep

  # 仅查看分析报告
  .\cleanup_c_drive_master.ps1 -Analyze
"@ | Write-Host
    exit 0
}

# ==========================================
# 初始化
# ==========================================
$script:Version = "5.0"
$script:StartTime = Get-Date
$script:TotalCleaned = 0
$script:TotalFiles = 0
$script:LogPath = Join-Path $env:TEMP "cleanup_master_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:HistoryPath = "C:\Users\xumou\quit\memory\cleanup_history.json"

# 确保memory目录存在
if (-not (Test-Path "C:\Users\xumou\quit\memory")) {
    New-Item -Path "C:\Users\xumou\quit\memory" -ItemType Directory -Force | Out-Null
}

# 初始化日志
"==========================================" | Out-File -FilePath $script:LogPath -Encoding UTF8
"C盘清理脚本 v$script:Version - 执行日志" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
"开始时间: $(Get-Date)" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
"模式: $(if($Quick){'快速'}elseif($Deep){'深度'}elseif($Analyze){'分析'}else{'标准'})" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
"==========================================" | Out-File -FilePath $script:LogPath -Append -Encoding UTF8

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $entry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "INFO"  { Write-Host $Message -ForegroundColor Gray }
        "HEADER" { Write-Host $Message -ForegroundColor Cyan }
    }
}

# ==========================================
# 显示欢迎信息
# ==========================================
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   C盘垃圾清理脚本 v$script:Version" -ForegroundColor Cyan
Write-Host "   终极整合版 - 智能清理与优化" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "❌ 需要管理员权限" "ERROR"
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Log "✅ 管理员权限检查通过" "SUCCESS"

# ==========================================
# 模块1: 磁盘空间分析
# ==========================================
function Show-DiskAnalysis {
    Write-Host ""
    Write-Log "📊 正在分析磁盘空间..." "HEADER"
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = $totalGB - $freeGB
    $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
    
    Write-Host "   总容量: $totalGB GB" -ForegroundColor Gray
    Write-Host "   已使用: $usedGB GB" -ForegroundColor Gray
    Write-Host "   可用空间: $freeGB GB ($percentFree%)" -ForegroundColor $(if($percentFree -lt 10){"Red"}elseif($percentFree -lt 20){"Yellow"}else{"Green"})
    
    if ($percentFree -lt 10) {
        Write-Log "⚠️ 警告：C盘可用空间不足10%" "WARN"
    }
    
    return @{
        TotalGB = $totalGB
        FreeGB = $freeGB
        UsedGB = $usedGB
        PercentFree = $percentFree
    }
}

# ==========================================
# 模块2: 基础清理功能
# ==========================================
function Start-BasicCleanup {
    Write-Host ""
    Write-Log "🧹 开始基础清理..." "HEADER"
    
    $cleanedTotal = 0
    
    # 1. Windows临时文件
    Write-Log "  清理 Windows 临时文件..." "INFO"
    $before = (Get-ChildItem "C:\Windows\Temp" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem "C:\Windows\Temp" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $cleaned = [math]::Round(($before - $after) / 1MB, 2)
    $cleanedTotal += $cleaned
    Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    
    # 2. 用户临时文件
    Write-Log "  清理用户临时文件..." "INFO"
    $before = (Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $cleaned = [math]::Round(($before - $after) / 1MB, 2)
    $cleanedTotal += $cleaned
    Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    
    # 3. 回收站
    Write-Log "  清空回收站..." "INFO"
    try {
        $rb = (New-Object -ComObject Shell.Application).Namespace(0xA)
        $rbSize = 0
        foreach ($item in $rb.Items()) { try { $rbSize += $item.Size } catch {} }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        $cleaned = [math]::Round($rbSize / 1MB, 2)
        $cleanedTotal += $cleaned
        Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    } catch {
        Write-Log "    ⚠️ 回收站清理失败" "WARN"
    }
    
    # 4. 浏览器缓存（如果浏览器未运行）
    $browsers = @(
        @{ Name = "msedge"; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" },
        @{ Name = "chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" }
    )
    
    foreach ($browser in $browsers) {
        $process = Get-Process -Name $browser.Name -ErrorAction SilentlyContinue
        if (-not $process -and (Test-Path $browser.Path)) {
            Write-Log "  清理 $($browser.Name) 缓存..." "INFO"
            $before = (Get-ChildItem $browser.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item "$($browser.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
            $after = (Get-ChildItem $browser.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $cleaned = [math]::Round(($before - $after) / 1MB, 2)
            $cleanedTotal += $cleaned
            if ($cleaned -gt 0) {
                Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
            }
        }
    }
    
    return $cleanedTotal
}

# ==========================================
# 模块3: 深度清理（仅Deep模式）
# ==========================================
function Start-DeepCleanup {
    Write-Host ""
    Write-Log "🔧 开始深度清理..." "HEADER"
    
    $cleanedTotal = 0
    
    # 1. Windows更新缓存
    Write-Log "  清理 Windows 更新缓存..." "INFO"
    try {
        $service = Get-Service wuauserv -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        }
        $before = (Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        $after = (Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $cleaned = [math]::Round(($before - $after) / 1MB, 2)
        $cleanedTotal += $cleaned
        if ($service -and $service.Status -eq 'Stopped') {
            Start-Service wuauserv -ErrorAction SilentlyContinue
        }
        Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    } catch {
        Write-Log "    ⚠️ Windows更新缓存清理失败" "WARN"
    }
    
    # 2. 缩略图缓存
    Write-Log "  清理缩略图缓存..." "INFO"
    try {
        $thumbFiles = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -ErrorAction SilentlyContinue
        $thumbSize = ($thumbFiles | Measure-Object -Property Length -Sum).Sum
        $explorer = Get-Process explorer -ErrorAction SilentlyContinue
        if ($explorer) { Stop-Process -Name explorer -Force }
        $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Start-Process explorer
        $cleaned = [math]::Round($thumbSize / 1MB, 2)
        $cleanedTotal += $cleaned
        Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    } catch {
        Write-Log "    ⚠️ 缩略图缓存清理失败" "WARN"
    }
    
    # 3. 崩溃转储文件
    Write-Log "  清理崩溃转储文件..." "INFO"
    try {
        $dumpSize = 0
        if (Test-Path "C:\Windows\Minidump") {
            $dumps = Get-ChildItem "C:\Windows\Minidump" -Filter "*.dmp" -ErrorAction SilentlyContinue
            $dumpSize += ($dumps | Measure-Object -Property Length -Sum).Sum
            $dumps | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "C:\Windows\Memory.dmp") {
            $dumpSize += (Get-Item "C:\Windows\Memory.dmp").Length
            Remove-Item "C:\Windows\Memory.dmp" -Force -ErrorAction SilentlyContinue
        }
        $cleaned = [math]::Round($dumpSize / 1MB, 2)
        $cleanedTotal += $cleaned
        Write-Log "    ✓ 释放 $cleaned MB" "SUCCESS"
    } catch {
        Write-Log "    ⚠️ 崩溃转储文件清理失败" "WARN"
    }
    
    return $cleanedTotal
}

# ==========================================
# 模块4: 大文件扫描（Deep模式）
# ==========================================
function Find-LargeFiles {
    param([int]$ThresholdMB = 100)
    
    Write-Host ""
    Write-Log "🔍 扫描大文件（>$ThresholdMB MB）..." "HEADER"
    
    $largeFiles = @()
    $searchPaths = @(
        @{ Path = (Join-Path $env:USERPROFILE "Downloads"); Depth = 2 },
        @{ Path = (Join-Path $env:USERPROFILE "Desktop"); Depth = 1 },
        @{ Path = (Join-Path $env:USERPROFILE "Videos"); Depth = 2 }
    )
    
    foreach ($search in $searchPaths) {
        if (Test-Path $search.Path) {
            try {
                $files = Get-ChildItem $search.Path -File -Recurse -Depth $search.Depth -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Length -gt ($ThresholdMB * 1MB) } |
                         Select-Object -First 5
                $largeFiles += $files | ForEach-Object {
                    [PSCustomObject]@{
                        Name = $_.Name
                        Path = $_.FullName
                        SizeGB = [math]::Round($_.Length / 1GB, 2)
                        LastModified = $_.LastWriteTime
                    }
                }
            } catch {}
        }
    }
    
    $largeFiles = $largeFiles | Sort-Object SizeGB -Descending | Select-Object -First 10
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "   发现 $($largeFiles.Count) 个大文件:" -ForegroundColor Yellow
        $largeFiles | ForEach-Object {
            Write-Host "   - $($_.Name) ($($_.SizeGB) GB)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   未发现大于 $ThresholdMB MB 的文件" -ForegroundColor Gray
    }
    
    return $largeFiles
}

# ==========================================
# 模块5: 记录历史
# ==========================================
function Save-CleanupHistory {
    param([double]$SpaceFreedMB, [int]$FilesDeleted)
    
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
            FilesDeleted = $FilesDeleted
            Mode = if($Quick){"Quick"}elseif($Deep){"Deep"}else{"Standard"}
        }
        
        $history += $newRecord
        if ($history.Count -gt 100) {
            $history = $history | Sort-Object Timestamp -Descending | Select-Object -First 100
        }
        
        $history | ConvertTo-Json -Depth 3 | Out-File -FilePath $script:HistoryPath -Encoding UTF8
        Write-Log "✅ 已保存清理历史" "SUCCESS"
    } catch {
        Write-Log "⚠️ 保存历史记录失败: $($_.Exception.Message)" "WARN"
    }
}

# ==========================================
# 模块6: SSD检测和提示
# ==========================================
function Test-SSDAndOptimize {
    Write-Host ""
    Write-Log "💾 检测磁盘类型..." "HEADER"
    
    try {
        $physicalDisk = Get-PhysicalDisk | Where-Object { 
            $_.DeviceId -eq (Get-Partition -DriveLetter C | Get-Disk).Number 
        }
        
        if ($physicalDisk.MediaType -eq "SSD" -or $physicalDisk.MediaType -eq "NVMe") {
            Write-Host "   ✅ 检测到SSD硬盘" -ForegroundColor Green
            Write-Host "   型号: $($physicalDisk.FriendlyName)" -ForegroundColor Gray
            Write-Host "   容量: $([math]::Round($physicalDisk.Size / 1GB, 2)) GB" -ForegroundColor Gray
            
            # 执行TRIM
            Write-Log "  执行TRIM优化..." "INFO"
            try {
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
                Write-Log "    ✓ TRIM完成" "SUCCESS"
            } catch {
                Write-Log "    ⚠️ TRIM失败" "WARN"
            }
            
            return $true
        } else {
            Write-Host "   ℹ️  检测到HDD硬盘" -ForegroundColor Gray
            return $false
        }
    } catch {
        Write-Log "⚠️ 无法检测磁盘类型" "WARN"
        return $null
    }
}

# ==========================================
# 显示最终结果
# ==========================================
function Show-FinalReport {
    param($DiskBefore, $TotalCleanedMB, $Duration, $LargeFiles)
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $totalCleanedGB = [math]::Round($TotalCleanedMB / 1024, 2)
    $reportPath = Join-Path $env:TEMP "cleanup_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   📊 清理完成报告" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⏱️  执行时间: $($Duration.ToString('mm\:ss'))" -ForegroundColor Gray
    Write-Host "💾 释放空间: $totalCleanedGB GB ($([math]::Round($TotalCleanedMB, 2)) MB)" -ForegroundColor Green
    Write-Host "💾 当前可用: $freeGB GB" -ForegroundColor Gray
    Write-Host ""
    
    # 显示历史趋势
    if (Test-Path $script:HistoryPath) {
        try {
            $history = Get-Content $script:HistoryPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($history -is [array] -and $history.Count -gt 0) {
                $totalHistory = ($history | Measure-Object SpaceFreedGB -Sum).Sum
                $count = $history.Count
                Write-Host "📈 累计清理: $count 次，共释放 $([math]::Round($totalHistory, 2)) GB" -ForegroundColor Green
            }
        } catch {}
    }
    
    Write-Host ""
    Write-Host "📝 日志文件: $($script:LogPath)" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan
}

# ==========================================
# 主程序
# ==========================================

# 分析模式
if ($Analyze) {
    Show-DiskAnalysis
    Find-LargeFiles -ThresholdMB 100
    exit 0
}

# 显示磁盘分析
$diskBefore = Show-DiskAnalysis

# 确认执行
if (-not $AutoClean) {
    Write-Host ""
    $mode = if ($Quick) { "快速" } elseif ($Deep) { "深度" } else { "标准" }
    Write-Host "💡 即将执行 $mode 清理模式" -ForegroundColor Yellow
    $confirm = Read-Host "是否继续? (输入 YES 确认)"
    if ($confirm -ne 'YES') {
        Write-Log "用户取消操作" "INFO"
        exit 0
    }
}

# 执行清理
$totalCleaned = 0

# 基础清理（所有模式）
$totalCleaned += Start-BasicCleanup

# 深度清理（仅Deep模式）
if ($Deep) {
    $totalCleaned += Start-DeepCleanup
    Find-LargeFiles -ThresholdMB 100 | Out-Null
}

# SSD优化
$isSSD = Test-SSDAndOptimize

# 保存历史
Save-CleanupHistory -SpaceFreedMB $totalCleaned -FilesDeleted $script:TotalFiles

# 显示报告
$duration = (Get-Date) - $script:StartTime
Show-FinalReport -DiskBefore $diskBefore -TotalCleanedMB $totalCleaned -Duration $duration

Write-Host ""
Write-Host "💡 提示:" -ForegroundColor DarkGray
Write-Host "   使用 -Analyze 查看分析报告（不清理）" -ForegroundColor DarkGray
Write-Host "   使用 -Deep 进行深度清理" -ForegroundColor DarkGray
Write-Host "   使用 -Help 查看更多选项" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

Read-Host "`n按 Enter 键退出"
