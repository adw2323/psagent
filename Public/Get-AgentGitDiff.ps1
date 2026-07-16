# Get-AgentGitDiff.ps1 - Returns git diff as structured JSON

function Get-AgentGitDiff {
    <#
    .SYNOPSIS
    Returns git diff as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns diff results with:
    - Files changed
    - Lines added/removed
    - Change details per file
    
    .EXAMPLE
    Get-AgentGitDiff -Path C:\git\myrepo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',
        
        [string]$Commit,
        
        [switch]$Staged,
        
        [switch]$Raw,
                [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    # Build diff command
    $diffArgs = @('diff', '--stat=300')
    if ($Staged) { $diffArgs += '--staged' }
    if ($Commit) { $diffArgs += $Commit }
    
    $diffOutput = & git -C $resolvedPath.Path @diffArgs 2>&1
    
    # Parse diff stat
    $files = @()
    $totalAdded = 0
    $totalRemoved = 0
    
    foreach ($line in $diffOutput) {
        if ($line -match '(.+?)\s+\|\s+(\d+)\s+\+*(-*)(-*)') {
            $file = $Matches[1].Trim()
            $changes = [int]$Matches[2]
            $added = if ($Matches[3]) { $changes } else { 0 }
            $removed = if ($Matches[4]) { $changes } else { 0 }
            
            $files += @{
                file = $file
                path = Join-Path $resolvedPath.Path $file
                additions = $added
                deletions = $removed
            }
            
            $totalAdded += $added
            $totalRemoved += $removed
        }
    }
    
    # Get detailed diff for each file
    $detailedDiff = @()
    foreach ($file in $files) {
        $fileDiff = & git -C $resolvedPath.Path diff -- $file.file 2>&1
        $lines = @()
        
        foreach ($line in $fileDiff) {
            if ($line -match '^\+(.+)$') {
                $lines += @{ type = 'added'; content = $Matches[1] }
            } elseif ($line -match '^\-(.+)$') {
                $lines += @{ type = 'removed'; content = $Matches[1] }
            } elseif ($line -match '^@@.*@@(.+)$') {
                $lines += @{ type = 'hunk'; content = $Matches[1].Trim() }
            }
        }
        
        $detailedDiff += @{
            file = $file.file
            changes = $lines
        }
    }
    
    $output = @{
        type = 'git_diff'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        path = $resolvedPath.Path
        staged = $Staged.IsPresent
        total_files = $files.Count
        total_additions = $totalAdded
        total_deletions = $totalRemoved
        files = $files
        details = $detailedDiff
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name agd -Value Get-AgentGitDiff
