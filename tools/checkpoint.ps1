# 会话检查点保存函数
# 用法: . ./checkpoint.ps1; Save-Checkpoint -Task "描述" -Progress 50

function Save-Checkpoint {
    param(
        [string]$Task,
        [int]$Progress,
        [string]$Completed = "",
        [string]$InProgress = "",
        [string]$NextSteps = ""
    )
    
    $checkpointFile = "C:\Users\xumou\quit\memory\session_checkpoint.md"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $content = @"
# 会话检查点
生成时间: $timestamp

## 当前任务
$Task

## 进度
- 完成度: $Progress%
- 已完成: $Completed
- 进行中: $InProgress

## 下一步
$NextSteps

## 关键文件
$(Get-ChildItem C:\Users\xumou\quit -File -Name | Select-Object -First 10 | ForEach-Object { "- $_" })
"@
    
    $content | Out-File -FilePath $checkpointFile -Encoding UTF8
    Write-Host "✅ 检查点已保存: $checkpointFile" -ForegroundColor Green
}

function Load-Checkpoint {
    $checkpointFile = "C:\Users\xumou\quit\memory\session_checkpoint.md"
    if (Test-Path $checkpointFile) {
        Write-Host "📂 恢复之前的会话状态..." -ForegroundColor Cyan
        Get-Content $checkpointFile | Write-Host -ForegroundColor Gray
        return $true
    }
    return $false
}

Export-ModuleMember -Function Save-Checkpoint, Load-Checkpoint
