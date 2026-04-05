# chat-memory.ps1
# 聊天记录管理脚本
# 用法:
#   保存: .\chat-memory.ps1 -Action save -Summary "..." -Topics "topic1,topic2"
#   读取: .\chat-memory.ps1 -Action load
#   读取(详情): .\chat-memory.ps1 -Action load -Verbose true
#   清理: .\chat-memory.ps1 -Action cleanup
param(
    [string]$Action = "load",
    [string]$Date = "",
    [string]$Summary = "",
    [string]$Topics = "",
    [string]$Decisions = "",
    [string]$FilesModified = "",
    [string]$Model = "mini-max/M2",
    [string]$ConvDir = "",
    [int]$MaxAgeDays = 30,
    [string]$Verbose = "false"
)

$ErrorActionPreference = "SilentlyContinue"

if ($ConvDir -eq "") {
    $ConvDir = Join-Path $PWD "memory\conversations"
}

if (!(Test-Path $ConvDir)) {
    New-Item -ItemType Directory -Path $ConvDir -Force | Out-Null
}

if ($Date -eq "") {
    $Date = Get-Date -Format "yyyy-MM-dd"
}

function Remove-OldFiles {
    param([string]$dir, [int]$days)
    $cutoff = (Get-Date).AddDays(-$days)
    $files = Get-ChildItem $dir -Filter "*.json" -ErrorAction SilentlyContinue
    $removed = 0
    foreach ($f in $files) {
        if ($f.LastWriteTime -lt $cutoff) {
            Remove-Item $f.FullName -Force
            $removed++
        }
    }
    return $removed
}

function Save-Conversation {
    param([string]$date, [string]$summary, [string]$topics, [string]$decisions, [string]$filesModified, [string]$model, [string]$convDir, [int]$days)

    $removed = Remove-OldFiles -dir $convDir -days $days
    if ($removed -gt 0) {
        Write-Host "[chat-memory] Cleaned up $removed old file(s)"
    }

    $filePath = Join-Path $convDir "$date.json"
    $existing = @{ lastUpdated = ""; entries = @() }
    if (Test-Path $filePath) {
        $json = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
        if ($json) {
            try {
                $existing = $json | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    if (-not ($existing.entries)) {
        $existing = @{ lastUpdated = ""; entries = @() }
    }

    $entry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        summary = $summary
        topics = @($topics -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        decisions = @($decisions -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        filesModified = @($filesModified -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        model = $model
    }

    $existing.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm"
    $entriesList = @($existing.entries)
    $entriesList += $entry
    $existing.entries = $entriesList

    $jsonOut = $existing | ConvertTo-Json -Depth 5
    $jsonOut | Set-Content $filePath -Encoding UTF8
    Write-Host "[chat-memory] Saved to $date.json ($(($existing.entries).Count) entries)"
}

function Load-Conversations {
    param([string]$dir, [int]$days, [string]$verbose)

    $cutoff = (Get-Date).AddDays(-$days)
    $files = Get-ChildItem $dir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $total = 0
    $isVerbose = ($verbose -eq "true")
    foreach ($f in $files) {
        if ($f.LastWriteTime -lt $cutoff) {
            Remove-Item $f.FullName -Force
            continue
        }
        $json = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $json) { continue }
        try {
            $content = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
            if (-not $content.entries) { continue }
            Write-Host "=== $($f.BaseName) ==="
            foreach ($entry in $content.entries) {
                Write-Host "  [$($entry.timestamp)] $($entry.summary)"
                if ($isVerbose -and $entry.topics) {
                    foreach ($t in $entry.topics) {
                        Write-Host "    - $t"
                    }
                }
                if ($isVerbose -and $entry.decisions) {
                    foreach ($d in $entry.decisions) {
                        Write-Host "    > $d"
                    }
                }
                $total++
            }
        } catch { continue }
    }
    if ($total -gt 0) {
        Write-Host "[chat-memory] $total record(s) loaded (last $days days)"
    }
}

switch ($Action) {
    "save"    { Save-Conversation -date $Date -summary $Summary -topics $Topics -decisions $Decisions -filesModified $FilesModified -model $Model -convDir $ConvDir -days $MaxAgeDays }
    "load"    { Load-Conversations -dir $ConvDir -days $MaxAgeDays -verbose $Verbose.ToString() }
    "cleanup" { $r = Remove-OldFiles -dir $ConvDir -days $MaxAgeDays; Write-Host "[chat-memory] Removed $r old file(s)" }
}
