# Get-AgentGitLog.ps1 - Returns git log as structured JSON

function Get-AgentGitLog {
    <#
    .SYNOPSIS
    Returns git log as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns commit history with:
    - Commit hash (short)
    - Author
    - Date
    - Message
    
    .EXAMPLE
    Get-AgentGitLog -Path C:\git\myrepo -Count 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',
        
        [int]$Count = 10,
        
        [string]$Since,
        
        [string]$Until,
        
        [string]$Author,
        
        [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    # Build git log command
    $format = '%h|%an|%ai|%s'
    $logCmd = @('log', "--format=$format", "-n", $Count.ToString())
    
    if ($Since) { $logCmd += "--since=$Since" }
    if ($Until) { $logCmd += "--until=$Until" }
    if ($Author) { $logCmd += "--author=$Author" }
    
    $logOutput = & git -C $resolvedPath.Path @logCmd 2>&1
    
    $commits = @()
    
    foreach ($line in $logOutput) {
        if ($line -match '^(.+?)\|(.+?)\|(.+?)\|(.+)$') {
            $commits += @{
                hash = $Matches[1].Trim()
                author = $Matches[2].Trim()
                date = $Matches[3].Trim()
                message = $Matches[4].Trim()
            }
        }
    }
    
    # Get branch info
    $branch = & git -C $resolvedPath.Path branch --show-current 2>&1
    
    # Get total commit count
    $totalCommits = & git -C $resolvedPath.Path rev-list --count HEAD 2>&1
    
    $output = @{
        type = 'git_log'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        path = $resolvedPath.Path
        branch = $branch
        total_commits = [int]$totalCommits
        shown = $commits.Count
        commits = $commits
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name agl -Value Get-AgentGitLog
