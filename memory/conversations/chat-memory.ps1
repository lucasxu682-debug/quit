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
    [string]$Verbose = "false",
    [string]$Content = "",
    [string]$Confidence = "low",
    [string]$MainContext = "",
    [string]$Query = "",
    [int]$Limit = 10,
    [string]$FragmentDir = ""
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

function Get-Count {
    param([object]$obj)
    if ($null -eq $obj) { return 0 }
    if ($obj -is [array]) { return $obj.Count }
    if ($obj.GetType().Name -eq "PSCustomObject" -and $obj.PSObject.Properties["Count"]) {
        return $obj.Count
    }
    try { return @($obj).Count } catch { return 0 }
    return 0
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
                $parsed = $json | ConvertFrom-Json
                if ($parsed) {
                    $existing.lastUpdated = if ($parsed.lastUpdated) { $parsed.lastUpdated } else { "" }
                    $existing.entries = if ($parsed.entries) { @($parsed.entries) } else { @() }
                }
            } catch {}
        }
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
    $cnt = Get-Count $existing.entries
    Write-Host "[chat-memory] Saved to $date.json ($cnt entries)"
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
            $content = $json | ConvertFrom-Json
            if (-not $content.entries) { continue }
            Write-Host "=== $($f.BaseName) ==="
            foreach ($entry in @($content.entries)) {
                Write-Host "  [$($entry.timestamp)] $($entry.summary)"
                if ($isVerbose -and $entry.topics) {
                    foreach ($t in @($entry.topics)) {
                        Write-Host "    - $t"
                    }
                }
                if ($isVerbose -and $entry.decisions) {
                    foreach ($d in @($entry.decisions)) {
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

function Dump-RawConversation {
    param([string]$date, [string]$rawText, [string]$convDir)

    $dumpDir = Join-Path $convDir "raw"
    if (!(Test-Path $dumpDir)) {
        New-Item -ItemType Directory -Path $dumpDir -Force | Out-Null
    }

    $dumpFile = Join-Path $dumpDir "$date-raw.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $content = "[$timestamp]`n$rawText`n`n"
    
    if (Test-Path $dumpFile) {
        $existing = Get-Content $dumpFile -Raw -Encoding UTF8
        $content = $existing + $content
    }
    
    $content | Set-Content $dumpFile -Encoding UTF8
    Write-Host "[chat-memory] Dumped raw text to $dumpFile"
}

function Get-FragmentDir {
    param([string]$convDir, [string]$fragmentDir)
    if ($fragmentDir -ne "") {
        return $fragmentDir
    }
    return Join-Path $convDir "fragments"
}

function Ensure-FragmentDir {
    param([string]$dir)
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Get-RecentFragmentFiles {
    param([string]$dir)
    $cutoff = (Get-Date).AddDays(-3)
    $files = Get-ChildItem $dir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $recentFiles = @()
    foreach ($f in $files) {
        if ($f.LastWriteTime -ge $cutoff) {
            $recentFiles += $f
        }
    }
    return $recentFiles
}

function Read-FragmentFile {
    param([string]$filePath)
    if (!(Test-Path $filePath)) {
        return $null
    }
    $json = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $json) { return $null }
    try {
        return $json | ConvertFrom-Json
    } catch { return $null }
}

function Get-FragmentBufferPath {
    return Join-Path $PWD "memory\kairos\fragments-buffer.json"
}

function Read-FragmentBuffer {
    $path = Get-FragmentBufferPath
    if (-not (Test-Path $path)) {
        return @{ fragments = @(); lastFragmentTime = ""; lastNotifyTime = "" }
    }
    $json = Get-Content $path -Raw -ErrorAction SilentlyContinue
    if (-not $json) { return @{ fragments = @(); lastFragmentTime = ""; lastNotifyTime = "" } }
    try {
        $parsed = $json | ConvertFrom-Json
        $fragList = $parsed.fragments
        if ($null -eq $fragList) {
            $fragList = @()
        } elseif ($fragList -isnot [array]) {
            $fragList = @($fragList)
        }
        return @{
            fragments = $fragList
            lastFragmentTime = if ($parsed.lastFragmentTime) { $parsed.lastFragmentTime } else { "" }
            lastNotifyTime = if ($parsed.lastNotifyTime) { $parsed.lastNotifyTime } else { "" }
        }
    } catch {
        return @{ fragments = @(); lastFragmentTime = ""; lastNotifyTime = "" }
    }
}

function Write-FragmentBuffer {
    param([hashtable]$bufferData)
    $path = Get-FragmentBufferPath
    if ($bufferData.fragments -isnot [array]) {
        $bufferData.fragments = @($bufferData.fragments)
    }
    $jsonOut = $bufferData | ConvertTo-Json -Depth 10
    $jsonOut | Set-Content $path -Encoding UTF8
}

function Save-FragmentToBuffer {
    param([hashtable]$fragmentData)
    $buffer = Read-FragmentBuffer
    $buffer.fragments += $fragmentData
    $buffer.lastFragmentTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    Write-FragmentBuffer -bufferData $buffer
}

function Flush-Fragments {
    param([string]$convDir, [string]$fragmentDir)
    $buffer = Read-FragmentBuffer
    $fragments = $buffer.fragments
    if ($fragments.Count -eq 0) {
        Write-Host "[fragments] Buffer empty, nothing to flush"
        return
    }
    $fragDir = $fragmentDir
    if ($fragDir -eq "") {
        $fragDir = Join-Path $PWD "memory\kairos\fragments"
    }
    Ensure-FragmentDir -dir $fragDir
    $flushed = 0
    foreach ($frag in $fragments) {
        $today = ($frag.timestamp -split " ")[0]
        $filePath = Join-Path $fragDir "$today.json"
        $fragmentData = @{
            id = $frag.id
            timestamp = $frag.timestamp
            content = $frag.content
            topics = @($frag.topics)
            confidence = $frag.confidence
            source = $frag.source
            mainContext = $frag.mainContext
            promoted = $false
        }
        Save-FragmentToFile -filePath $filePath -fragmentData $fragmentData
        $flushed++
    }
    $buffer.fragments = @()
    Write-FragmentBuffer -bufferData $buffer
    Write-Host "[fragments] Flushed $flushed fragment(s) to archive"
}

function Save-FragmentToFile {
    param([string]$filePath, [hashtable]$fragmentData)
    $existing = @{ lastUpdated = ""; fragments = @() }
    if (Test-Path $filePath) {
        $json = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
        if ($json) {
            try {
                $parsed = $json | ConvertFrom-Json
                if ($parsed) {
                    $existing.lastUpdated = if ($parsed.lastUpdated) { $parsed.lastUpdated } else { "" }
                    $existing.fragments = if ($parsed.fragments) { @($parsed.fragments) } else { @() }
                }
            } catch {}
        }
    }

    $existing.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm"
    $fragmentsList = @($existing.fragments)
    $fragmentsList += $fragmentData
    $existing.fragments = $fragmentsList

    $jsonOut = $existing | ConvertTo-Json -Depth 10
    $jsonOut | Set-Content $filePath -Encoding UTF8
}

function Save-Fragment {
    param(
        [string]$content,
        [string]$topics,
        [string]$confidence,
        [string]$mainContext,
        [string]$convDir,
        [string]$fragmentDir
    )

    $id = [guid]::NewGuid().ToString()
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $topicsList = @($topics -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })

    $fragmentData = @{
        id = $id
        timestamp = $timestamp
        content = $content
        topics = $topicsList
        confidence = $confidence
        source = "auto"
        mainContext = $mainContext
        promoted = $false
    }

    Save-FragmentToBuffer -fragmentData $fragmentData

    $buffer = Read-FragmentBuffer
    $count = $buffer.fragments.Count
    Write-Host "[fragments] Buffered fragment (buffer size: $count)"
}

function Load-RecentFragments {
    param([string]$convDir, [string]$fragmentDir, [int]$limit)

    $fragDir = Get-FragmentDir -convDir $convDir -fragmentDir $fragmentDir
    if (!(Test-Path $fragDir)) {
        Write-Host "[fragments] No fragments found (directory does not exist)"
        return
    }

    $files = Get-RecentFragmentFiles -dir $fragDir
    if ($files.Count -eq 0) {
        Write-Host "[fragments] No recent fragments (last 3 days)"
        return
    }

    $allFragments = @()
    foreach ($f in $files) {
        $data = Read-FragmentFile -filePath $f.FullName
        if ($data -and $data.fragments) {
            foreach ($frag in @($data.fragments)) {
                $allFragments += $frag
            }
        }
    }

    $allFragmentsCount = Get-Count $allFragments
    if ($allFragmentsCount -eq 0) {
        Write-Host "[fragments] No recent fragments"
        return
    }

    $allFragments = $allFragments | Sort-Object { $_.timestamp } -Descending
    $total = Get-Count $allFragments
    $display = @($allFragments | Select-Object -First $limit)

    Write-Host "Recent fragments (total $total, showing $($display.Count)):"
    Write-Host ""
    foreach ($frag in $display) {
        $topicsStr = ($frag.topics -join ", ")
        $promotedMark = if ($frag.promoted) { " [permanent]" } else { "" }
        Write-Host "[$($frag.timestamp)] #$topicsStr$promotedMark"
        Write-Host "  Content: $($frag.content)"
        if ($frag.mainContext) {
            Write-Host "  Context: $($frag.mainContext)"
        }
        Write-Host ""
    }
    if ($total -gt $limit) {
        Write-Host "(More fragments available, use searchfragments to find specific ones)"
    }
}

function Search-Fragments {
    param([string]$query, [string]$convDir, [string]$fragmentDir)

    if ($query -eq "") {
        Write-Host "[fragments] Query cannot be empty. Usage: -Action searchfragments -Query ""keyword1 keyword2"""
        return
    }

    $fragDir = Get-FragmentDir -convDir $convDir -fragmentDir $fragmentDir
    if (!(Test-Path $fragDir)) {
        Write-Host "[fragments] No fragments found"
        return
    }

    $keywords = @($query -split "\s+" | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" })

    $files = Get-ChildItem $fragDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $results = @()

    foreach ($f in $files) {
        $data = Read-FragmentFile -filePath $f.FullName
        if (-not ($data -and $data.fragments)) { continue }

        foreach ($frag in @($data.fragments)) {
            $contentLower = $frag.content.ToString().ToLower()
            $topicsLower = @($frag.topics | ForEach-Object { $_.ToString().ToLower() })

            $allMatch = $true
            foreach ($kw in $keywords) {
                $inContent = $contentLower.Contains($kw)
                $inTopics = $topicsLower -contains $kw
                if (-not ($inContent -or $inTopics)) {
                    $allMatch = $false
                    break
                }
            }

            if ($allMatch) {
                $f.LastWriteTime = Get-Date
                $results += $frag
            }
        }
    }

    $resultsCount = Get-Count $results
    if ($resultsCount -eq 0) {
        Write-Host "[fragments] No fragments match: $query"
        return
    }

    $results = $results | Sort-Object { $_.timestamp } -Descending
    Write-Host "Found $resultsCount matching fragment(s):"
    Write-Host ""
    foreach ($frag in @($results)) {
        $topicsStr = ($frag.topics -join ", ")
        $promotedMark = if ($frag.promoted) { " [permanent]" } else { "" }
        Write-Host "[$($frag.timestamp)] #$topicsStr$promotedMark"
        Write-Host "  Content: $($frag.content)"
        if ($frag.mainContext) {
            Write-Host "  Context: $($frag.mainContext)"
        }
        Write-Host ""
    }
}

function Cleanup-Fragments {
    param([string]$convDir, [string]$fragmentDir)

    $fragDir = Get-FragmentDir -convDir $convDir -fragmentDir $fragmentDir
    if (!(Test-Path $fragDir)) {
        Write-Host "[fragments] Nothing to clean up"
        return
    }

    $now = Get-Date
    $cutoff7 = $now.AddDays(-7)
    $cutoff30 = $now.AddDays(-30)
    $files = Get-ChildItem $fragDir -Filter "*.json" -ErrorAction SilentlyContinue
    $removed = 0

    foreach ($f in $files) {
        $data = Read-FragmentFile -filePath $f.FullName
        if (-not ($data -and $data.fragments)) { continue }

        $remaining = @()
        foreach ($frag in @($data.fragments)) {
            $ts = [DateTime]::ParseExact($frag.timestamp.ToString(), "yyyy-MM-dd HH:mm", $null)
            $isPromoted = $frag.promoted -eq $true

            if ($isPromoted) {
                if ($ts -lt $cutoff30) {
                    $removed++
                } else {
                    $remaining += $frag
                }
            } else {
                if ($ts -lt $cutoff7) {
                    $removed++
                } else {
                    $remaining += $frag
                }
            }
        }

        $remainingCount = Get-Count $remaining
        $originalCount = Get-Count $data.fragments

        if ($remainingCount -eq 0) {
            Remove-Item $f.FullName -Force
        } elseif ($remainingCount -ne $originalCount) {
            $data.fragments = $remaining
            $data.lastUpdated = $now.ToString("yyyy-MM-dd HH:mm")
            $jsonOut = $data | ConvertTo-Json -Depth 10
            $jsonOut | Set-Content $f.FullName -Encoding UTF8
        }
    }

    Write-Host "[fragments] Cleanup done. Removed $removed expired fragment(s)."
}

function Remove-Fragment {
    param([string]$query, [string]$convDir, [string]$fragmentDir)

    if ($query -eq "") {
        Write-Host "[fragments] Query cannot be empty. Usage: -Action removefragment -Query ""keyword"""
        return
    }

    $fragDir = Get-FragmentDir -convDir $convDir -fragmentDir $fragmentDir
    if (!(Test-Path $fragDir)) {
        Write-Host "[fragments] No fragments found"
        return
    }

    $keywords = @($query -split "\s+" | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" })
    $files = Get-ChildItem $fragDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $removed = 0

    foreach ($f in $files) {
        $data = Read-FragmentFile -filePath $f.FullName
        if (-not ($data -and $data.fragments)) { continue }

        $remaining = @()
        foreach ($frag in @($data.fragments)) {
            $contentLower = $frag.content.ToString().ToLower()
            $topicsLower = @($frag.topics | ForEach-Object { $_.ToString().ToLower() })

            $allMatch = $true
            foreach ($kw in $keywords) {
                if (-not ($contentLower.Contains($kw) -or ($topicsLower -contains $kw))) {
                    $allMatch = $false
                    break
                }
            }

            if ($allMatch) {
                $removed++
            } else {
                $remaining += $frag
            }
        }

        $remainingCount = Get-Count $remaining
        if ($remainingCount -eq 0) {
            Remove-Item $f.FullName -Force
        } else {
            $data.fragments = $remaining
            $data.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm")
            $jsonOut = $data | ConvertTo-Json -Depth 10
            $jsonOut | Set-Content $f.FullName -Encoding UTF8
        }
    }

    Write-Host "[fragments] Removed $removed fragment(s) matching: $query"
}

function Keep-Fragment {
    param([string]$query, [string]$convDir, [string]$fragmentDir)

    if ($query -eq "") {
        Write-Host "[fragments] Query cannot be empty. Usage: -Action keepfragment -Query ""keyword"""
        return
    }

    $fragDir = Get-FragmentDir -convDir $convDir -fragmentDir $fragmentDir
    if (!(Test-Path $fragDir)) {
        Write-Host "[fragments] No fragments found"
        return
    }

    $keywords = @($query -split "\s+" | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" })
    $files = Get-ChildItem $fragDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $promoted = 0

    foreach ($f in $files) {
        $data = Read-FragmentFile -filePath $f.FullName
        if (-not ($data -and $data.fragments)) { continue }

        $modified = $false
        foreach ($frag in @($data.fragments)) {
            $contentLower = $frag.content.ToString().ToLower()
            $topicsLower = @($frag.topics | ForEach-Object { $_.ToString().ToLower() })

            $allMatch = $true
            foreach ($kw in $keywords) {
                if (-not ($contentLower.Contains($kw) -or ($topicsLower -contains $kw))) {
                    $allMatch = $false
                    break
                }
            }

            if ($allMatch) {
                $frag.promoted = $true
                $modified = $true
                $promoted++
            }
        }

        if ($modified) {
            $data.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm")
            $jsonOut = $data | ConvertTo-Json -Depth 10
            $jsonOut | Set-Content $f.FullName -Encoding UTF8
        }
    }

    Write-Host "[fragments] Promoted $promoted fragment(s) to permanent"
}

switch ($Action) {
    "save"              { Save-Conversation -date $Date -summary $Summary -topics $Topics -decisions $Decisions -filesModified $FilesModified -model $Model -convDir $ConvDir -days $MaxAgeDays }
    "load"              { Load-Conversations -dir $ConvDir -days $MaxAgeDays -verbose $Verbose.ToString() }
    "cleanup"           { $r = Remove-OldFiles -dir $ConvDir -days $MaxAgeDays; Write-Host "[chat-memory] Removed $r old file(s)" }
    "dump"              { Dump-RawConversation -date $Date -rawText $Summary -convDir $ConvDir }
    "savefragment"      { Save-Fragment -content $Content -topics $Topics -confidence $Confidence -mainContext $MainContext -convDir $ConvDir -fragmentDir $FragmentDir }
    "loadrecent"        { Load-RecentFragments -convDir $ConvDir -fragmentDir $FragmentDir -limit $Limit }
    "searchfragments"   { Search-Fragments -query $Query -convDir $ConvDir -fragmentDir $FragmentDir }
    "cleanupfragments"  { Cleanup-Fragments -convDir $ConvDir -fragmentDir $FragmentDir }
    "removefragment"    { Remove-Fragment -query $Query -convDir $ConvDir -fragmentDir $FragmentDir }
    "keepfragment"      { Keep-Fragment -query $Query -convDir $ConvDir -fragmentDir $FragmentDir }
    "flushfragments"    { Flush-Fragments -convDir $ConvDir -fragmentDir $FragmentDir }
}
