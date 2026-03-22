# SSD优化模块
# 针对SSD硬盘的特殊优化，延长寿命并提升性能

<#
.SYNOPSIS
    SSD硬盘优化工具

.DESCRIPTION
    检测SSD状态，执行TRIM操作，优化系统设置以延长SSD寿命并提升性能

.PARAMETER AnalyzeOnly
    仅分析，不执行实际优化操作

.PARAMETER Force
    强制执行（即使检测到非SSD也继续）

.EXAMPLE
    .\ssd_optimize.ps1
    检测SSD并执行优化

.EXAMPLE
    .\ssd_optimize.ps1 -AnalyzeOnly
    仅分析SSD状态，不执行优化

.NOTES
    需要管理员权限运行
    支持Windows 10/11
#>

param(
    [switch]$AnalyzeOnly,          # 仅分析，不执行优化
    [switch]$Force,                # 强制执行（忽略警告）
    [string]$LogPath = ""
)

# 检查管理员权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ 需要管理员权限运行此脚本" -ForegroundColor Red
    Write-Host "   请右键点击脚本，选择'使用 PowerShell 运行'" -ForegroundColor Gray
    exit 1
}

# 初始化
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrEmpty($LogPath)) {
    $LogPath = Join-Path $env:TEMP "ssd_optimization_$timestamp.log"
}

"==========================================" | Out-File -FilePath $LogPath -Encoding UTF8
"SSD优化 - 执行日志" | Out-File -FilePath $LogPath -Append -Encoding UTF8
"开始时间: $(Get-Date)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
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
Write-Host "   SSD优化模块" -ForegroundColor Cyan
Write-Host "   延长寿命，提升性能" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# 检测是否为SSD
# ==========================================

function Test-IsSSD {
    param([string]$DriveLetter = "C")
    
    try {
        $physicalDisk = Get-PhysicalDisk | Where-Object { 
            $_.DeviceId -eq (Get-Partition -DriveLetter $DriveLetter | Get-Disk).Number 
        }
        
        if ($physicalDisk.MediaType -eq "SSD") {
            return $true
        }
        
        # 备用检测方法
        $msftDisk = Get-WmiObject -Class MSFT_Disk -Namespace "root\microsoft\windows\storage" | 
                    Where-Object { $_.Number -eq (Get-Partition -DriveLetter $DriveLetter | Get-Disk).Number }
        
        if ($msftDisk) {
            $physicalDisk = Get-WmiObject -Class MSFT_PhysicalDisk -Namespace "root\microsoft\windows\storage" |
                           Where-Object { $_.DeviceId -eq $msftDisk.PhysicalDiskIds[0] }
            
            return ($physicalDisk.MediaType -eq 3 -or $physicalDisk.MediaType -eq 4)  # 3=SSD, 4=NVMe
        }
        
        return $false
    } catch {
        Write-Log "无法检测磁盘类型: $($_.Exception.Message)" "WARN"
        return $null
    }
}

# ==========================================
# 检测SSD健康状态
# ==========================================

function Get-SSDHealth {
    try {
        $health = @()
        
        # 使用WMI获取SMART信息
        $disks = Get-WmiObject -Class MSFT_PhysicalDisk -Namespace "root\microsoft\windows\storage"
        
        foreach ($disk in $disks | Where-Object { $_.MediaType -eq 3 -or $_.MediaType -eq 4 }) {
            $diskInfo = [PSCustomObject]@{
                DeviceId = $disk.DeviceId
                FriendlyName = $disk.FriendlyName
                MediaType = if ($disk.MediaType -eq 4) { "NVMe SSD" } else { "SSD" }
                SizeGB = [math]::Round($disk.Size / 1GB, 2)
                HealthStatus = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
            }
            
            $health += $diskInfo
        }
        
        return $health
    } catch {
        Write-Log "无法获取SSD健康状态: $($_.Exception.Message)" "WARN"
        return $null
    }
}

# ==========================================
# 执行TRIM操作
# ==========================================

function Invoke-TRIM {
    Write-Host ""
    Write-Host "🧹 执行TRIM操作..." -ForegroundColor Yellow
    Write-Log "开始TRIM操作"
    
    try {
        # 检查TRIM支持
        $trimSupport = fsutil behavior query DisableDeleteNotify
        
        if ($trimSupport -match "DisableDeleteNotify = 0") {
            Write-Host "   ✅ TRIM已启用" -ForegroundColor Green
            Write-Log "TRIM已启用"
        } else {
            Write-Host "   ⚠️  TRIM未启用，正在启用..." -ForegroundColor Yellow
            fsutil behavior set DisableDeleteNotify 0 | Out-Null
            Write-Host "   ✅ TRIM已启用" -ForegroundColor Green
            Write-Log "TRIM已启用"
        }
        
        if (-not $AnalyzeOnly) {
            # 执行优化（包含TRIM）
            Write-Host "   正在执行优化..." -ForegroundColor Gray
            Optimize-Volume -DriveLetter C -ReTrim -Verbose 2>&1 | ForEach-Object {
                Write-Log $_.ToString()
            }
            Write-Host "   ✅ TRIM操作完成" -ForegroundColor Green
            Write-Log "TRIM操作完成"
        } else {
            Write-Host "   ℹ️  分析模式：跳过实际TRIM操作" -ForegroundColor Gray
        }
        
        return $true
    } catch {
        Write-Log "TRIM操作失败: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ==========================================
# 优化SSD设置
# ==========================================

function Optimize-SSDSettings {
    Write-Host ""
    Write-Host "⚙️  优化SSD设置..." -ForegroundColor Yellow
    
    $optimizations = @()
    
    # 1. 禁用磁盘碎片整理（SSD不需要）
    try {
        $schedule = Get-ScheduledTask -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
        if ($schedule -and $schedule.State -eq "Ready") {
            if (-not $AnalyzeOnly) {
                Disable-ScheduledTask -TaskName "ScheduledDefrag" -Confirm:$false | Out-Null
                $optimizations += "已禁用磁盘碎片整理计划"
            } else {
                $optimizations += "建议禁用磁盘碎片整理计划"
            }
        } else {
            $optimizations += "磁盘碎片整理计划已禁用"
        }
    } catch {
        Write-Log "检查碎片整理计划失败: $($_.Exception.Message)" "WARN"
    }
    
    # 2. 检查Superfetch/SysMain服务（对SSD帮助不大）
    try {
        $sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sysMain -and $sysMain.Status -eq "Running") {
            if (-not $AnalyzeOnly) {
                Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
                $optimizations += "已禁用SysMain服务（Superfetch）"
            } else {
                $optimizations += "建议禁用SysMain服务（Superfetch）"
            }
        } else {
            $optimizations += "SysMain服务已禁用"
        }
    } catch {
        Write-Log "检查SysMain服务失败: $($_.Exception.Message)" "WARN"
    }
    
    # 3. 检查预读设置
    try {
        $prefetch = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
        if ($prefetch.EnablePrefetcher -ne 0) {
            if (-not $AnalyzeOnly) {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0
                $optimizations += "已禁用预读功能"
            } else {
                $optimizations += "建议禁用预读功能"
            }
        } else {
            $optimizations += "预读功能已禁用"
        }
    } catch {
        Write-Log "检查预读设置失败: $($_.Exception.Message)" "WARN"
    }
    
    # 4. 检查休眠文件（hiberfil.sys占用空间）
    try {
        # 更可靠的休眠状态检测
        $hiberFile = Get-ChildItem "C:\hiberfil.sys" -ErrorAction SilentlyContinue
        if ($hiberFile) {
            $hiberSize = $hiberFile.Length / 1GB
            # 检查休眠是否启用（通过电源配置）
            $powerConfig = powercfg /a 2>&1
            $hibernateEnabled = $powerConfig -match "休眠"
            
            if ($hibernateEnabled) {
                if (-not $AnalyzeOnly) {
                    powercfg /hibernate off 2>&1 | Out-Null
                    $optimizations += "已禁用休眠（释放 $([math]::Round($hiberSize, 2)) GB）"
                } else {
                    $optimizations += "建议禁用休眠（可释放 $([math]::Round($hiberSize, 2)) GB）"
                }
            } else {
                $optimizations += "休眠已禁用（hiberfil.sys存在但未启用）"
            }
        } else {
            $optimizations += "休眠已禁用"
        }
    } catch {
        Write-Log "检查休眠设置失败: $($_.Exception.Message)" "WARN"
    }
    
    # 显示结果
    foreach ($opt in $optimizations) {
        Write-Host "   $opt" -ForegroundColor Green
        Write-Log $opt
    }
    
    return $optimizations
}

# ==========================================
# 分析SSD使用情况
# ==========================================

function Get-SSDAnalysis {
    Write-Host ""
    Write-Host "📊 SSD使用情况分析..." -ForegroundColor Yellow
    
    try {
        $volume = Get-Volume -DriveLetter C
        $disk = Get-Disk | Where-Object { $_.IsSystem -eq $true }
        
        $analysis = [PSCustomObject]@{
            TotalSizeGB = [math]::Round($volume.Size / 1GB, 2)
            UsedSpaceGB = [math]::Round(($volume.Size - $volume.SizeRemaining) / 1GB, 2)
            FreeSpaceGB = [math]::Round($volume.SizeRemaining / 1GB, 2)
            UsagePercent = [math]::Round((($volume.Size - $volume.SizeRemaining) / $volume.Size) * 100, 1)
            HealthStatus = $volume.HealthStatus
        }
        
        Write-Host "   总容量: $($analysis.TotalSizeGB) GB" -ForegroundColor Gray
        Write-Host "   已使用: $($analysis.UsedSpaceGB) GB ($($analysis.UsagePercent)%)" -ForegroundColor Gray
        Write-Host "   可用空间: $($analysis.FreeSpaceGB) GB" -ForegroundColor Gray
        Write-Host "   健康状态: $($analysis.HealthStatus)" -ForegroundColor $(if($analysis.HealthStatus -eq "Healthy"){"Green"}else{"Red"})
        
        # 建议
        if ($analysis.UsagePercent -gt 90) {
            Write-Host "   ⚠️  警告：SSD使用率超过90%，建议立即清理！" -ForegroundColor Red
            Write-Log "SSD使用率超过90%" "WARN"
        } elseif ($analysis.UsagePercent -gt 80) {
            Write-Host "   ⚠️  建议：SSD使用率超过80%，建议清理" -ForegroundColor Yellow
        }
        
        return $analysis
    } catch {
        Write-Log "分析SSD使用情况失败: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# ==========================================
# 主程序
# ==========================================

# 检测是否为SSD
Write-Host "🔍 检测磁盘类型..." -ForegroundColor Yellow
$isSSD = Test-IsSSD -DriveLetter "C"

if ($isSSD -eq $null) {
    Write-Host "❌ 无法确定磁盘类型，退出" -ForegroundColor Red
    exit 1
}

if (-not $isSSD) {
    Write-Host "⚠️  检测到C盘不是SSD，此脚本专为SSD优化设计" -ForegroundColor Yellow
    Write-Host "   继续执行可能会影响HDD性能" -ForegroundColor Yellow
    
    if (-not $Force) {
        $continue = Read-Host "是否继续? (Y/N)"
        if ($continue -ne 'Y') {
            exit 0
        }
    }
}

Write-Host "   ✅ 检测到SSD硬盘" -ForegroundColor Green
Write-Host ""

# 获取SSD健康状态
$health = Get-SSDHealth
if ($health) {
    Write-Host "💚 SSD健康状态:" -ForegroundColor Yellow
    foreach ($ssd in $health) {
        Write-Host "   设备: $($ssd.FriendlyName)" -ForegroundColor Gray
        Write-Host "   类型: $($ssd.MediaType)" -ForegroundColor Gray
        Write-Host "   容量: $($ssd.SizeGB) GB" -ForegroundColor Gray
        Write-Host "   健康: $($ssd.HealthStatus)" -ForegroundColor $(if($ssd.HealthStatus -eq "Healthy"){"Green"}else{"Red"})
    }
}

# 分析使用情况
$analysis = Get-SSDAnalysis

# 执行优化
$trimResult = Invoke-TRIM
$optimizations = Optimize-SSDSettings

# 总结
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📋 优化总结" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if ($AnalyzeOnly) {
    Write-Host "模式: 仅分析（未执行实际优化）" -ForegroundColor Yellow
    Write-Host "建议执行以下操作:" -ForegroundColor Gray
} else {
    Write-Host "模式: 实际优化" -ForegroundColor Green
    Write-Host "已完成操作:" -ForegroundColor Gray
}

Write-Host "   • TRIM操作: $(if($trimResult){'完成'}else{'失败'})" -ForegroundColor Gray
Write-Host "   • 系统优化: $($optimizations.Count) 项" -ForegroundColor Gray

if ($analysis) {
    Write-Host ""
    Write-Host "SSD状态:" -ForegroundColor Yellow
    Write-Host "   使用率: $($analysis.UsagePercent)%" -ForegroundColor $(if($analysis.UsagePercent -gt 90){"Red"}elseif($analysis.UsagePercent -gt 80){"Yellow"}else{"Green"})
    Write-Host "   可用空间: $($analysis.FreeSpaceGB) GB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📝 日志文件: $LogPath" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan

# 使用提示
Write-Host ""
Write-Host "💡 SSD使用建议:" -ForegroundColor DarkGray
Write-Host "   1. 保持至少10-20%的可用空间" -ForegroundColor DarkGray
Write-Host "   2. 避免频繁的写入操作" -ForegroundColor DarkGray
Write-Host "   3. 定期执行TRIM（Windows会自动执行）" -ForegroundColor DarkGray
Write-Host "   4. 不要对SSD进行磁盘碎片整理" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan
