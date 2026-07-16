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
        
        [switch]$Raw
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    # Build diff command using numstat for machine-readable output
    $diffArgs = @('diff', '--numstat')
    if ($Staged) { $diffArgs += '--staged' }
    if ($Commit) { $diffArgs += $Commit }
    
    $numstatOutput = & git -C $resolvedPath.Path @diffArgs 2>&1
    
    # Parse numstat output (format: added\tremoved\tfile)
    $files = @()
    $totalAdded = 0
    $totalRemoved = 0
    
    foreach ($line in $numstatOutput) {
        if ($line -match '^(\d+|\-)\t(\d+|\-)\t(.+)$') {
            $addedStr = $Matches[1]
            $removedStr = $Matches[2]
            $file = $Matches[3]
            
            # Handle binary files (shown as -)
            $added = if ($addedStr -eq '-') { 0 } else { [int]$addedStr }
            $removed = if ($removedStr -eq '-') { 0 } else { [int]$removedStr }
            
            $files += @{
                file = $file
                path = Join-Path $resolvedPath.Path $file
                additions = $added
                deletions = $removed
                is_binary = ($addedStr -eq '-' -or $removedStr -eq '-')
            }
            
            $totalAdded += $added
            $totalRemoved += $removed
        }
    }
    
    # Get detailed diff for each file (limit to first 10 files for performance)
    $detailedDiff = @()
    $filesToDetail = $files | Select-Object -First 10
    
    foreach ($file in $filesToDetail) {
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
