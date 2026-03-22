# 大文件智能识别和清理模块
# 自动扫描、分析并建议清理大文件

param(
    [int]$SizeThresholdMB = 100,      # 大文件阈值（MB）
    [int]$TopCount = 20,               # 显示前N个大文件
    [switch]$AutoClean,                # 自动清理模式
    [string[]]$ExcludePaths = @(),     # 排除路径
    [string]$LogPath = ""
)

# 初始化
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrEmpty($LogPath)) {
    $LogPath = Join-Path $env:TEMP "large_files_cleanup_$timestamp.log"
}

"==========================================" | Out-File -FilePath $LogPath -Encoding UTF8
"大文件智能识别和清理 - 执行日志" | Out-File -FilePath $LogPath -Append -Encoding UTF8
"开始时间: $(Get-Date)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
"阈值: $SizeThresholdMB MB" | Out-File -FilePath $LogPath -Append -Encoding UTF8
"==========================================" | Out-File -FilePath $LogPath -Append -Encoding UTF8

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    Add-Content -Path $LogPath -Value $entry -ErrorAction SilentlyContinue
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "Gray" }
    }
    Write-Host $Message -ForegroundColor $color
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   大文件智能识别和清理" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# 智能扫描策略
# ==========================================

# 定义扫描路径和优先级
$scanStrategy = @(
    # 高优先级 - 用户数据，通常有大文件
    @{ Path = (Join-Path $env:USERPROFILE "Downloads"); Priority = 1; Name = "下载文件夹"; Depth = 2 }
    @{ Path = (Join-Path $env:USERPROFILE "Desktop"); Priority = 1; Name = "桌面"; Depth = 1 }
    @{ Path = (Join-Path $env:USERPROFILE "Documents"); Priority = 2; Name = "文档"; Depth = 2 }
    @{ Path = (Join-Path $env:USERPROFILE "Videos"); Priority = 1; Name = "视频"; Depth = 2 }
    @{ Path = (Join-Path $env:USERPROFILE "Pictures"); Priority = 2; Name = "图片"; Depth = 2 }
    
    # 中优先级 - 临时文件
    @{ Path = $env:TEMP; Priority = 3; Name = "临时文件"; Depth = 2 }
    @{ Path = "C:\Windows\Temp"; Priority = 3; Name = "系统临时文件"; Depth = 1 }
    
    # 低优先级 - 其他位置
    @{ Path = "C:\ProgramData"; Priority = 4; Name = "程序数据"; Depth = 1 }
)

# 检查PowerShell版本（递归深度参数兼容性）
$psVersion = $PSVersionTable.PSVersion.Major
$supportsDepth = $psVersion -ge 5

# 排除的系统关键路径（安全检查）
$systemPaths = @(
    "C:\Windows\System32",
    "C:\Windows\SysWOW64",
    "C:\Program Files",
    "C:\Program Files (x86)"
)

Write-Host "🔍 开始智能扫描大文件（>$SizeThresholdMB MB）..." -ForegroundColor Yellow
Write-Host ""

$allLargeFiles = @()
$scannedCount = 0
$startTime = Get-Date

# 按优先级扫描
foreach ($scan in ($scanStrategy | Sort-Object Priority)) {
    $path = $scan.Path
    $name = $scan.Name
    $depth = $scan.Depth
    
    # 检查排除路径
    $isExcluded = $false
    foreach ($exclude in $ExcludePaths) {
        if ($path -like "$exclude*") {
            $isExcluded = $true
            break
        }
    }
    if ($isExcluded) { continue }
    
    # 检查系统路径
    $isSystem = $false
    foreach ($sysPath in $systemPaths) {
        if ($path -like "$sysPath*") {
            $isSystem = $true
            break
        }
    }
    if ($isSystem) { continue }
    
    if (Test-Path $path) {
        Write-Host "  扫描: $name" -ForegroundColor Gray
        Write-Log "扫描: $path (深度: $depth)"
        
        try {
            # 根据PowerShell版本选择扫描方式
            if ($supportsDepth) {
                $files = Get-ChildItem $path -File -Recurse -Depth $depth -ErrorAction SilentlyContinue | 
                         Where-Object { 
                             $_.Length -gt ($SizeThresholdMB * 1MB) -and 
                             $_.FullName -notmatch '\.sys$|\.dll$|\.exe$'
                         }
            } else {
                # 旧版本PowerShell兼容
                $files = Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue | 
                         Where-Object { 
                             $_.Length -gt ($SizeThresholdMB * 1MB) -and 
                             $_.FullName -notmatch '\.sys$|\.dll$|\.exe$' -and
                             ($_.FullName.Split('\').Count - $path.Split('\').Count) -le $depth
                         }
            }
            
            $processedFiles = $files | ForEach-Object {
                $scannedCount++
                [PSCustomObject]@{
                    Name = $_.Name
                    Path = $_.FullName
                    SizeMB = [math]::Round($_.Length / 1MB, 2)
                    SizeGB = [math]::Round($_.Length / 1GB, 2)
                    LastAccess = $_.LastAccessTime
                    LastModified = $_.LastWriteTime
                    Category = $name
                    IsOld = ($_.LastAccessTime -lt (Get-Date).AddDays(-30))
                }
            }
            $allLargeFiles += $processedFiles
        } catch {
            Write-Log "扫描失败: $path - $($_.Exception.Message)" "WARN"
        }
    } else {
        Write-Log "路径不存在，跳过: $path" "INFO"
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "✅ 扫描完成" -ForegroundColor Green
Write-Host "   扫描文件数: $scannedCount" -ForegroundColor Gray
Write-Host "   发现大文件: $($allLargeFiles.Count)" -ForegroundColor Gray
Write-Host "   耗时: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host ""

# 排序并取前N个
$topFiles = $allLargeFiles | Sort-Object SizeMB -Descending | Select-Object -First $TopCount

# ==========================================
# 智能分析和分类
# ==========================================

Write-Host "📊 智能分析中..." -ForegroundColor Yellow

$fileCategories = @{
    "视频文件" = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm')
    "音频文件" = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma')
    "压缩文件" = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2')
    "镜像文件" = @('.iso', '.img', '.dmg', '.vmdk')
    "安装包" = @('.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm')
    "数据库" = @('.db', '.sqlite', '.mdb', '.accdb')
    "日志文件" = @('.log', '.logs')
    "临时文件" = @('.tmp', '.temp', '.cache')
}

$analyzedFiles = $topFiles | ForEach-Object {
    $ext = [System.IO.Path]::GetExtension($_.Name).ToLower()
    $type = "其他"
    $action = "检查"
    $risk = "低"
    
    foreach ($cat in $fileCategories.GetEnumerator()) {
        if ($cat.Value -contains $ext) {
            $type = $cat.Key
            break
        }
    }
    
    # 智能建议
    switch ($type) {
        "视频文件" { 
            $action = if ($_.IsOld) { "可删除（旧视频）" } else { "建议保留" }
            $risk = "低"
        }
        "临时文件" { 
            $action = "可安全删除"
            $risk = "无"
        }
        "安装包" { 
            $action = if ($_.IsOld) { "可删除（已安装）" } else { "检查是否已安装" }
            $risk = "低"
        }
        "日志文件" { 
            $action = if ($_.SizeMB -gt 500) { "可删除或压缩" } else { "保留" }
            $risk = "低"
        }
        "压缩文件" { 
            $action = "检查内容后决定"
            $risk = "中"
        }
        default { 
            $action = "手动检查"
            $risk = "中"
        }
    }
    
    $_ | Add-Member -NotePropertyName FileType -NotePropertyValue $type -Force
    $_ | Add-Member -NotePropertyName SuggestedAction -NotePropertyValue $action -Force
    $_ | Add-Member -NotePropertyName RiskLevel -NotePropertyValue $risk -Force
    $_
}

# ==========================================
# 显示结果
# ==========================================

Write-Host ""
Write-Host "📋 大文件分析报告（前$TopCount个）" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$index = 1
foreach ($file in $analyzedFiles) {
    $color = switch ($file.RiskLevel) {
        "无" { "Green" }
        "低" { "Yellow" }
        default { "Red" }
    }
    
    Write-Host "[$index] $($file.Name)" -ForegroundColor White
    Write-Host "    大小: $($file.SizeGB) GB ($($file.SizeMB) MB)" -ForegroundColor Gray
    Write-Host "    类型: $($file.FileType)" -ForegroundColor Gray
    Write-Host "    位置: $($file.Path)" -ForegroundColor DarkGray
    Write-Host "    建议: $($file.SuggestedAction)" -ForegroundColor $color
    Write-Host "    风险: $($file.RiskLevel)" -ForegroundColor $color
    
    if ($file.IsOld) {
        Write-Host "    ⚠️  30天未访问" -ForegroundColor Yellow
    }
    
    Write-Host ""
    $index++
}

# 统计
$totalSizeGB = ($analyzedFiles | Measure-Object SizeGB -Sum).Sum
$safeToDelete = $analyzedFiles | Where-Object { $_.RiskLevel -eq "无" -or ($_.RiskLevel -eq "低" -and $_.IsOld) }
$potentialSpace = ($safeToDelete | Measure-Object SizeGB -Sum).Sum

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📊 统计摘要" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "总大小: $([math]::Round($totalSizeGB, 2)) GB" -ForegroundColor White
Write-Host "可安全清理: $($safeToDelete.Count) 个文件" -ForegroundColor Green
Write-Host "可释放空间: $([math]::Round($potentialSpace, 2)) GB" -ForegroundColor Green
Write-Host ""

# ==========================================
# 自动清理或交互式清理
# ==========================================

if ($AutoClean -and $safeToDelete.Count -gt 0) {
    Write-Host "🧹 自动清理模式" -ForegroundColor Yellow
    $deletedSize = 0
    $deletedCount = 0
    
    foreach ($file in $safeToDelete) {
        try {
            Remove-Item $file.Path -Force -ErrorAction Stop
            $deletedSize += $file.SizeGB
            $deletedCount++
            Write-Log "已删除: $($file.Name) ($($file.SizeGB) GB)" "SUCCESS"
        } catch {
            Write-Log "删除失败: $($file.Name) - $($_.Exception.Message)" "ERROR"
        }
    }
    
    Write-Host ""
    Write-Host "✅ 自动清理完成" -ForegroundColor Green
    Write-Host "   删除文件: $deletedCount" -ForegroundColor Gray
    Write-Host "   释放空间: $([math]::Round($deletedSize, 2)) GB" -ForegroundColor Gray
} else {
    # 交互式清理
    if ($safeToDelete.Count -gt 0) {
        Write-Host "💡 发现 $($safeToDelete.Count) 个可安全清理的文件" -ForegroundColor Yellow
        $clean = Read-Host "是否清理这些文件? (Y/N)"
        
        if ($clean -eq 'Y' -or $clean -eq 'y') {
            $deletedSize = 0
            $deletedCount = 0
            
            foreach ($file in $safeToDelete) {
                try {
                    Remove-Item $file.Path -Force -ErrorAction Stop
                    $deletedSize += $file.SizeGB
                    $deletedCount++
                    Write-Host "   ✓ 已删除: $($file.Name)" -ForegroundColor Green
                } catch {
                    Write-Host "   ✗ 删除失败: $($file.Name)" -ForegroundColor Red
                }
            }
            
            Write-Host ""
            Write-Host "✅ 清理完成" -ForegroundColor Green
            Write-Host "   删除文件: $deletedCount" -ForegroundColor Gray
            Write-Host "   释放空间: $([math]::Round($deletedSize, 2)) GB" -ForegroundColor Gray
        }
    }
}

# 保存报告
$reportPath = Join-Path $env:TEMP "large_files_report_$timestamp.txt"
$report = @"
大文件分析报告
生成时间: $(Get-Date)
========================================

扫描统计:
- 扫描文件数: $scannedCount
- 发现大文件: $($allLargeFiles.Count)
- 分析文件数: $TopCount
- 耗时: $($duration.ToString('mm\:ss'))

空间统计:
- 总大小: $([math]::Round($totalSizeGB, 2)) GB
- 可安全清理: $($safeToDelete.Count) 个文件
- 可释放空间: $([math]::Round($potentialSpace, 2)) GB

详细列表:
$($analyzedFiles | ForEach-Object { "`n[$($_.Category)] $($_.Name)`n  大小: $($_.SizeGB) GB`n  路径: $($_.Path)`n  建议: $($_.SuggestedAction)`n  风险: $($_.RiskLevel)" })

日志文件: $LogPath
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "📁 报告已保存: $reportPath" -ForegroundColor Gray
Write-Host "📝 日志文件: $LogPath" -ForegroundColor Gray
# 使用示例说明
<#
.SYNOPSIS
    智能大文件识别和清理工具

.DESCRIPTION
    自动扫描、分析并建议清理大文件，支持智能分类和风险评估

.PARAMETER SizeThresholdMB
    大文件阈值（MB），默认100MB

.PARAMETER TopCount
    显示前N个大文件，默认20个

.PARAMETER AutoClean
    自动清理模式（只清理标记为"无风险"的文件）

.PARAMETER ExcludePaths
    排除路径数组

.EXAMPLE
    .\large_files_cleanup.ps1
    交互模式，扫描并询问是否清理

.EXAMPLE
    .\large_files_cleanup.ps1 -SizeThresholdMB 500 -TopCount 10
    只显示大于500MB的前10个文件

.EXAMPLE
    .\large_files_cleanup.ps1 -AutoClean
    自动清理无风险的大文件
#>

Write-Host ""
Write-Host "💡 使用提示:" -ForegroundColor DarkGray
Write-Host "   阈值: $SizeThresholdMB MB | 显示前 $TopCount 个" -ForegroundColor DarkGray
if ($AutoClean) {
    Write-Host "   模式: 自动清理（仅无风险文件）" -ForegroundColor Yellow
} else {
    Write-Host "   模式: 交互式" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
