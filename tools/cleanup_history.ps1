# 清理历史记录和趋势分析模块
# 记录每次清理效果，生成趋势图表

param(
    [switch]$ShowReport,           # 显示历史报告
    [switch]$ExportCSV,             # 导出CSV数据
    [int]$Days = 30,                # 显示最近N天的记录
    [string]$HistoryPath = ""       # 历史文件路径
)

# 初始化
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrEmpty($HistoryPath)) {
    $HistoryPath = "C:\Users\xumou\quit\memory\cleanup_history.json"
}

$ReportPath = Join-Path $env:TEMP "cleanup_trend_report_$timestamp.html"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   清理历史记录和趋势分析" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# 历史记录管理
# ==========================================

function Add-CleanupRecord {
    param(
        [double]$SpaceFreedMB,
        [int]$FilesDeleted,
        [string]$CategoriesCleaned = "",
        [string]$Notes = ""
    )
    
    # 读取现有历史
    $history = @()
    if (Test-Path $HistoryPath) {
        try {
            $history = Get-Content $HistoryPath -Raw | ConvertFrom-Json
            if ($history -isnot [array]) {
                $history = @($history)
            }
        } catch {
            $history = @()
        }
    }
    
    # 添加新记录
    $newRecord = [PSCustomObject]@{
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        SpaceFreedMB = [math]::Round($SpaceFreedMB, 2)
        SpaceFreedGB = [math]::Round($SpaceFreedMB / 1024, 2)
        FilesDeleted = $FilesDeleted
        CategoriesCleaned = $CategoriesCleaned
        Notes = $Notes
        DiskFreeBefore = 0  # 可由调用者提供
        DiskFreeAfter = 0   # 可由调用者提供
    }
    
    # 获取当前磁盘空间
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $newRecord.DiskFreeAfter = [math]::Round($disk.FreeSpace / 1GB, 2)
        $newRecord.DiskFreeBefore = $newRecord.DiskFreeAfter + $newRecord.SpaceFreedGB
    } catch {
        # 忽略错误
    }
    
    $history += $newRecord
    
    # 只保留最近100条记录
    if ($history.Count -gt 100) {
        $history = $history | Sort-Object Timestamp -Descending | Select-Object -First 100
    }
    
    # 保存
    $history | ConvertTo-Json -Depth 3 | Out-File -FilePath $HistoryPath -Encoding UTF8
    
    Write-Host "✅ 已记录清理历史: $HistoryPath" -ForegroundColor Green
    return $newRecord
}

function Get-CleanupHistory {
    param([int]$LastDays = 30)
    
    if (-not (Test-Path $HistoryPath)) {
        Write-Host "ℹ️  首次使用，暂无历史记录" -ForegroundColor Gray
        return @()
    }
    
    try {
        $content = Get-Content $HistoryPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            return @()
        }
        
        $history = $content | ConvertFrom-Json -ErrorAction Stop
        if ($history -isnot [array]) {
            $history = @($history)
        }
        
        # 过滤最近N天（使用Timestamp更安全）
        $cutoffTimestamp = [DateTimeOffset]::Now.AddDays(-$LastDays).ToUnixTimeSeconds()
        $history = $history | Where-Object { 
            $_.Timestamp -gt $cutoffTimestamp 
        }
        
        # 数据验证
        $history = $history | Where-Object { 
            $_.SpaceFreedGB -ge 0 -and $_.FilesDeleted -ge 0 
        }
        
        return $history | Sort-Object Timestamp
    } catch {
        Write-Host "⚠️  读取历史记录失败: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   将创建新的历史记录文件" -ForegroundColor Gray
        return @()
    }
}

# ==========================================
# 生成趋势报告
# ==========================================

function Show-TrendReport {
    param([array]$History)
    
    if ($History.Count -eq 0) {
        Write-Host "📊 暂无清理历史记录" -ForegroundColor Yellow
        Write-Host "   请先运行清理脚本，历史记录会自动保存" -ForegroundColor Gray
        return
    }
    
    Write-Host "📊 清理历史趋势分析（最近$Days天）" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 统计数据
    $totalCleanups = $History.Count
    $totalSpaceFreed = ($History | Measure-Object SpaceFreedGB -Sum).Sum
    $totalFilesDeleted = ($History | Measure-Object FilesDeleted -Sum).Sum
    $avgSpacePerCleanup = if ($totalCleanups -gt 0) { $totalSpaceFreed / $totalCleanups } else { 0 }
    
    # 找出最大清理
    $maxCleanup = $History | Sort-Object SpaceFreedGB -Descending | Select-Object -First 1
    
    # 最近清理
    $lastCleanup = $History | Sort-Object Timestamp -Descending | Select-Object -First 1
    $daysSinceLast = if ($lastCleanup) { 
        ([DateTime]::Now - [DateTime]::Parse($lastCleanup.Date)).Days 
    } else { 0 }
    
    # 显示统计
    Write-Host "📈 总体统计:" -ForegroundColor Yellow
    Write-Host "   清理次数: $totalCleanups" -ForegroundColor Gray
    Write-Host "   总释放空间: $([math]::Round($totalSpaceFreed, 2)) GB" -ForegroundColor Green
    Write-Host "   总删除文件: $totalFilesDeleted" -ForegroundColor Gray
    Write-Host "   平均每次: $([math]::Round($avgSpacePerCleanup, 2)) GB" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🏆 最佳清理:" -ForegroundColor Yellow
    if ($maxCleanup) {
        Write-Host "   日期: $($maxCleanup.Date)" -ForegroundColor Gray
        Write-Host "   释放: $($maxCleanup.SpaceFreedGB) GB" -ForegroundColor Green
        Write-Host "   文件: $($maxCleanup.FilesDeleted) 个" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "⏰ 最近清理:" -ForegroundColor Yellow
    if ($lastCleanup) {
        Write-Host "   日期: $($lastCleanup.Date)" -ForegroundColor Gray
        Write-Host "   距今: $daysSinceLast 天" -ForegroundColor $(if($daysSinceLast -gt 7){"Red"}else{"Green"})
        Write-Host "   释放: $($lastCleanup.SpaceFreedGB) GB" -ForegroundColor Gray
    }
    Write-Host ""
    
    # 显示最近10次记录
    Write-Host "📋 最近清理记录（最近10次）:" -ForegroundColor Yellow
    $recent = $History | Sort-Object Timestamp -Descending | Select-Object -First 10
    
    foreach ($record in $recent) {
        $date = [DateTime]::Parse($record.Date)
        $dateStr = $date.ToString("MM-dd HH:mm")
        Write-Host "   [$dateStr] 释放 $($record.SpaceFreedGB) GB, 删除 $($record.FilesDeleted) 个文件" -ForegroundColor Gray
    }
    Write-Host ""
}

# ==========================================
# 生成HTML趋势图表
# ==========================================

function Export-TrendHTML {
    param([array]$History, [string]$OutputPath)
    
    if ($History.Count -eq 0) {
        Write-Host "⚠️  没有历史数据可导出" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📊 生成HTML趋势图表..." -ForegroundColor Gray
    
    # 准备图表数据
    $chartData = $History | ForEach-Object { 
        "{ date: '$($_.Date)', space: $($_.SpaceFreedGB), files: $($_.FilesDeleted) }" 
    }
    $chartDataStr = $chartData -join ","
    
    # 统计数据
    $totalSpace = ($History | Measure-Object SpaceFreedGB -Sum).Sum
    $totalFiles = ($History | Measure-Object FilesDeleted -Sum).Sum
    $avgSpace = if ($History.Count -gt 0) { $totalSpace / $History.Count } else { 0 }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>清理历史趋势分析</title>
    <!-- 使用CDN，如果离线会显示提示 -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        // 检查Chart.js是否加载成功
        window.onload = function() {
            if (typeof Chart === 'undefined') {
                document.getElementById('chart-error').style.display = 'block';
                document.getElementById('trendChart').style.display = 'none';
            }
        };
    </script>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .summary-box { flex: 1; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-box.total { background: #e3f2fd; }
        .summary-box.space { background: #e8f5e9; }
        .summary-box.avg { background: #fff3e0; }
        .summary-box h3 { margin: 0; color: #666; font-size: 14px; }
        .summary-box .value { font-size: 32px; font-weight: bold; color: #333; margin: 10px 0; }
        .chart-container { margin: 30px 0; height: 400px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #4CAF50; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .timestamp { color: #999; font-size: 12px; text-align: right; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 清理历史趋势分析</h1>
        <p class="timestamp">生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <div class="summary-box total">
                <h3>清理次数</h3>
                <div class="value">$($History.Count)</div>
            </div>
            <div class="summary-box space">
                <h3>总释放空间</h3>
                <div class="value">$([math]::Round($totalSpace, 1)) GB</div>
            </div>
            <div class="summary-box avg">
                <h3>平均每次</h3>
                <div class="value">$([math]::Round($avgSpace, 1)) GB</div>
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="trendChart"></canvas>
            <div id="chart-error" style="display: none; text-align: center; padding: 50px; color: #666;">
                <p>⚠️ 无法加载图表（需要网络连接）</p>
                <p>表格数据仍可正常查看</p>
            </div>
        </div>
        
        <h2>📋 详细记录</h2>
        <table>
            <thead>
                <tr>
                    <th>日期</th>
                    <th>释放空间 (GB)</th>
                    <th>删除文件</th>
                    <th>清理类别</th>
                    <th>备注</th>
                </tr>
            </thead>
            <tbody>
                $($History | Sort-Object Timestamp -Descending | ForEach-Object {
                    "<tr><td>$($_.Date)</td><td>$($_.SpaceFreedGB)</td><td>$($_.FilesDeleted)</td><td>$($_.CategoriesCleaned)</td><td>$($_.Notes)</td></tr>"
                })
            </tbody>
        </table>
    </div>
    
    <script>
        const ctx = document.getElementById('trendChart').getContext('2d');
        const data = [$chartDataStr];
        
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d.date.split(' ')[0]),
                datasets: [{
                    label: '释放空间 (GB)',
                    data: data.map(d => d.space),
                    borderColor: '#4CAF50',
                    backgroundColor: 'rgba(76, 175, 80, 0.1)',
                    tension: 0.4,
                    fill: true
                }, {
                    label: '删除文件数',
                    data: data.map(d => d.files),
                    borderColor: '#2196F3',
                    backgroundColor: 'rgba(33, 150, 243, 0.1)',
                    tension: 0.4,
                    yAxisID: 'y1'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false,
                },
                scales: {
                    y: {
                        type: 'linear',
                        display: true,
                        position: 'left',
                        title: { display: true, text: '空间 (GB)' }
                    },
                    y1: {
                        type: 'linear',
                        display: true,
                        position: 'right',
                        title: { display: true, text: '文件数' },
                        grid: { drawOnChartArea: false }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ HTML报告已生成: $OutputPath" -ForegroundColor Green
    Start-Process $OutputPath
}

# ==========================================
# 导出CSV
# ==========================================

function Export-HistoryCSV {
    param([array]$History, [string]$OutputPath)
    
    if ($History.Count -eq 0) {
        Write-Host "⚠️  没有历史数据可导出" -ForegroundColor Yellow
        return
    }
    
    $csvPath = if ($OutputPath) { $OutputPath } else { 
        Join-Path $env:TEMP "cleanup_history_$timestamp.csv" 
    }
    
    $History | Select-Object Date, SpaceFreedGB, FilesDeleted, CategoriesCleaned, Notes |
        Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "✅ CSV已导出: $csvPath" -ForegroundColor Green
}

# ==========================================
# 主程序
# ==========================================

# 加载历史记录
$history = Get-CleanupHistory -LastDays $Days

# 显示报告
if ($ShowReport -or $history.Count -eq 0) {
    Show-TrendReport -History $history
}

# 导出HTML
Export-TrendHTML -History $history -OutputPath $ReportPath

# 导出CSV
if ($ExportCSV) {
    Export-HistoryCSV -History $history
}

Write-Host ""
Write-Host "💡 提示:" -ForegroundColor DarkGray
Write-Host "   在其他脚本中使用以下命令记录清理:" -ForegroundColor DarkGray
Write-Host '   . ./cleanup_history.ps1; Add-CleanupRecord -SpaceFreedMB 500 -FilesDeleted 100' -ForegroundColor Cyan
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
