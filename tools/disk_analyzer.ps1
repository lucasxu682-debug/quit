# C盘空间分析模块
# 生成可视化空间使用报告

param(
    [string]$OutputPath = "",
    [switch]$ShowConsole
)

# 初始化
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $env:TEMP "disk_analysis_$timestamp.html"
}

$startTime = Get-Date
Write-Host "正在分析C盘空间使用情况..." -ForegroundColor Cyan
Write-Host "   预计需要 1-3 分钟，请稍候..." -ForegroundColor DarkGray

# ==========================================
# 获取文件夹大小（带缓存）
# ==========================================
$script:SizeCache = @{}

function Get-FolderSizeFast {
    param([string]$Path, [int]$Depth = 0, [int]$MaxDepth = 3)
    
    if ($script:SizeCache.ContainsKey($Path)) {
        return $script:SizeCache[$Path]
    }
    
    if (-not (Test-Path $Path)) { return 0 }
    if ($Depth -gt $MaxDepth) { 
        # 超过深度限制时，使用粗略估计
        try {
            return (Get-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        } catch {
            return 0
        }
    }
    
    try {
        # 显示进度
        if ($Depth -eq 0) {
            Write-Host "    扫描: $Path" -ForegroundColor DarkGray
        }
        
        $size = (Get-ChildItem $Path -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        
        # 递归子文件夹（限制深度）
        Get-ChildItem $Path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $size += Get-FolderSizeFast -Path $_.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        }
        
        $script:SizeCache[$Path] = $size
        return $size
    } catch {
        Write-Host "    ⚠️ 无法访问: $Path" -ForegroundColor Yellow
        return 0
    }
}

# ==========================================
# 分析关键目录
# ==========================================
Write-Host "  扫描关键目录..." -ForegroundColor Gray

$analysisData = @()

# C盘根目录下的主要文件夹
$rootFolders = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\Users",
    "C:\ProgramData"
)

foreach ($folder in $rootFolders) {
    if (Test-Path $folder) {
        $size = Get-FolderSizeFast -Path $folder -MaxDepth 1
        $sizeGB = [math]::Round($size / 1GB, 2)
        
        $analysisData += [PSCustomObject]@{
            Name = Split-Path $folder -Leaf
            Path = $folder
            SizeBytes = $size
            SizeGB = $sizeGB
            Category = "System"
        }
        
        Write-Host "    $(Split-Path $folder -Leaf): $sizeGB GB" -ForegroundColor Gray
    }
}

# 用户目录详细分析
Write-Host "  分析用户目录..." -ForegroundColor Gray
$userFolders = @(
    "Documents",
    "Downloads", 
    "Desktop",
    "AppData\Local",
    "AppData\Roaming"
)

foreach ($subFolder in $userFolders) {
    $fullPath = Join-Path $env:USERPROFILE $subFolder
    if (Test-Path $fullPath) {
        $size = Get-FolderSizeFast -Path $fullPath -MaxDepth 1
        $sizeGB = [math]::Round($size / 1GB, 2)
        
        $analysisData += [PSCustomObject]@{
            Name = $subFolder
            Path = $fullPath
            SizeBytes = $size
            SizeGB = $sizeGB
            Category = "User"
        }
        
        Write-Host "    $subFolder`: $sizeGB GB" -ForegroundColor Gray
    }
}

# ==========================================
# 查找大文件
# ==========================================
Write-Host "  查找大文件..." -ForegroundColor Gray

$largeFiles = @()
$searchPaths = @(
    @{ Path = $env:USERPROFILE; Depth = 2 },
    @{ Path = "C:\Windows\Temp"; Depth = 1 },
    @{ Path = "C:\ProgramData"; Depth = 1 }
)

foreach ($searchInfo in $searchPaths) {
    $searchPath = $searchInfo.Path
    $maxDepth = $searchInfo.Depth
    
    if (Test-Path $searchPath) {
        Write-Host "    搜索: $searchPath (深度: $maxDepth)" -ForegroundColor DarkGray
        
        try {
            $files = Get-ChildItem $searchPath -File -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Length -gt 100MB } |
                     Select-Object -First 10 |
                     ForEach-Object {
                         [PSCustomObject]@{
                             Name = $_.Name
                             Path = $_.FullName
                             SizeGB = [math]::Round($_.Length / 1GB, 2)
                             LastModified = $_.LastWriteTime
                         }
                     }
            $largeFiles += $files
        } catch {
            Write-Host "    ⚠️ 搜索失败: $searchPath" -ForegroundColor Yellow
        }
    }
}

$largeFiles = $largeFiles | Sort-Object SizeGB -Descending | Select-Object -First 10

# ==========================================
# 生成HTML报告
# ==========================================
Write-Host "  生成HTML报告..." -ForegroundColor Gray

$totalSize = ($analysisData | Measure-Object SizeBytes -Sum).Sum
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalDiskGB = [math]::Round($disk.Size / 1GB, 2)
$freeDiskGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedDiskGB = $totalDiskGB - $freeDiskGB

# 按大小排序
$analysisData = $analysisData | Sort-Object SizeBytes -Descending

# HTML转义函数
function ConvertTo-HtmlSafe {
    param([string]$Text)
    $Text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
}

# 生成表格行
$tableRows = if ($analysisData.Count -eq 0) {
    '<tr><td colspan="5" style="text-align: center; color: #999;">暂无数据</td></tr>'
} else {
    $analysisData | ForEach-Object {
        $percent = if ($totalSize -gt 0) { [math]::Round(($_.SizeBytes / $totalSize) * 100, 1) } else { 0 }
        $barWidth = [math]::Min($percent, 100)
        $color = if ($_.SizeGB -gt 10) { "#ff6b6b" } elseif ($_.SizeGB -gt 5) { "#ffd93d" } else { "#6bcf7f" }
        $safeName = ConvertTo-HtmlSafe $_.Name
        
        @"
    <tr>
        <td>$safeName</td>
        <td>$($_.SizeGB) GB</td>
        <td>$percent%</td>
        <td><div class="bar" style="width: $barWidth%; background: $color;"></div></td>
        <td>$($_.Category)</td>
    </tr>
"@
    }
}

# 生成大文件列表
$largeFileRows = if ($largeFiles.Count -eq 0) {
    '<tr><td colspan="4" style="text-align: center; color: #999;">未找到大于100MB的文件</td></tr>'
} else {
    $largeFiles | ForEach-Object {
        $safeName = ConvertTo-HtmlSafe $_.Name
        $safePath = ConvertTo-HtmlSafe $_.Path
        @"
    <tr>
        <td>$safeName</td>
        <td>$($_.SizeGB) GB</td>
        <td>$($_.LastModified)</td>
        <td class="path">$safePath</td>
    </tr>
"@
    }
}
}

$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>C盘空间分析报告</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .summary-box { flex: 1; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-box.total { background: #e3f2fd; }
        .summary-box.used { background: #fff3e0; }
        .summary-box.free { background: #e8f5e9; }
        .summary-box h3 { margin: 0; color: #666; font-size: 14px; }
        .summary-box .value { font-size: 32px; font-weight: bold; color: #333; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #4CAF50; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .bar { height: 20px; border-radius: 10px; transition: width 0.3s; }
        .path { font-size: 12px; color: #666; max-width: 400px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .timestamp { color: #999; font-size: 12px; text-align: right; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ C盘空间分析报告</h1>
        <p class="timestamp">生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <div class="summary-box total">
                <h3>总容量</h3>
                <div class="value">$totalDiskGB GB</div>
            </div>
            <div class="summary-box used">
                <h3>已使用</h3>
                <div class="value">$usedDiskGB GB</div>
            </div>
            <div class="summary-box free">
                <h3>可用空间</h3>
                <div class="value">$freeDiskGB GB</div>
            </div>
        </div>
        
        $(if ($freeDiskGB -lt 10) { '<div class="warning">⚠️ 警告：C盘可用空间不足10GB，建议立即清理！</div>' })
        
        <h2>📁 文件夹大小分析</h2>
        <table>
            <thead>
                <tr>
                    <th>文件夹</th>
                    <th>大小</th>
                    <th>占比</th>
                    <th>可视化</th>
                    <th>类别</th>
                </tr>
            </thead>
            <tbody>
                $($tableRows -join "`n")
            </tbody>
        </table>
        
        <h2>📄 大文件列表 (>100MB)</h2>
        <table>
            <thead>
                <tr>
                    <th>文件名</th>
                    <th>大小</th>
                    <th>修改时间</th>
                    <th>路径</th>
                </tr>
            </thead>
            <tbody>
                $($largeFileRows -join "`n")
            </tbody>
        </table>
    </div>
</body>
</html>
"@

$html | Out-File -FilePath $OutputPath -Encoding UTF8

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "`n✅ 分析报告已生成: $OutputPath" -ForegroundColor Green
Write-Host "   分析耗时: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host "   请在浏览器中打开查看" -ForegroundColor Gray

# 自动打开浏览器
Start-Process $OutputPath
