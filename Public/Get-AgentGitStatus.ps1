# Get-AgentGitStatus.ps1 - Returns git status as structured JSON

function Get-AgentGitStatus {
    <#
    .SYNOPSIS
    Returns git status as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns git status with:
    - Branch info (current, tracking, ahead/behind)
    - Staged files
    - Unstaged files
    - Untracked files
    
    .EXAMPLE
    Get-AgentGitStatus -Path C:\git\myrepo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',
        
        [switch]$Raw,
                [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    # Check if git repo
    $gitDir = & git -C $resolvedPath.Path rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        return @{ error = "Not a git repository: $Path" } | ConvertTo-Json
    }
    
    # Get branch info
    $branch = & git -C $resolvedPath.Path branch --show-current 2>&1
    $tracking = & git -C $resolvedPath.Path rev-parse --abbrev-ref '@{upstream}' 2>&1
    $aheadBehind = & git -C $resolvedPath.Path rev-list --left-right --count '@{upstream}...HEAD' 2>&1
    
    $ahead = 0
    $behind = 0
    if ($aheadBehind -match '(\d+)\s+(\d+)') {
        $behind = [int]$Matches[1]
        $ahead = [int]$Matches[2]
    }
    
    # Get status
    $statusOutput = & git -C $resolvedPath.Path status --porcelain 2>&1
    
    $staged = @()
    $unstaged = @()
    $untracked = @()
    
    foreach ($line in $statusOutput) {
        if ($line -match '^\s*(.)(.)\s+(.+)$') {
            $indexStatus = $Matches[1]
            $workStatus = $Matches[2]
            $file = $Matches[3]
            
            $entry = @{
                file = $file
                path = Join-Path $resolvedPath.Path $file
            }
            
            if ($indexStatus -ne ' ' -and $indexStatus -ne '?') {
                $staged += $entry
            }
            
            if ($workStatus -ne ' ' -and $workStatus -ne '?') {
                $unstaged += $entry
            }
            
            if ($indexStatus -eq '?' -and $workStatus -eq '?') {
                $untracked += $entry
            }
        }
    }
    
    # Get ahead/behind commits
    $aheadCommits = @()
    $behindCommits = @()
    
    if ($ahead -gt 0) {
        $aheadCommits = & git -C $resolvedPath.Path log --oneline "@{upstream}..HEAD" 2>&1
    }
    if ($behind -gt 0) {
        $behindCommits = & git -C $resolvedPath.Path log --oneline "HEAD..@{upstream}" 2>&1
    }
    
    $output = @{
        type = 'git_status'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        path = $resolvedPath.Path
        branch = $branch
        tracking = if ($tracking -ne '@{upstream}') { $tracking } else { '' }
        ahead = $ahead
        behind = $behind
        ahead_commits = $aheadCommits
        behind_commits = $behindCommits
        staged = $staged
        unstaged = $unstaged
        untracked = $untracked
        total_staged = $staged.Count
        total_unstaged = $unstaged.Count
        total_untracked = $untracked.Count
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name ags -Value Get-AgentGitStatus
