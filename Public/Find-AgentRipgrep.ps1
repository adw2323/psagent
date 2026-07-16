# Find-AgentRipgrep.ps1 - Wraps ripgrep with structured JSON output

function Find-AgentRipgrep {
    <#
    .SYNOPSIS
    Wraps ripgrep with structured JSON output for AI agents.
    
    .DESCRIPTION
    Uses ripgrep --json for fast, structured search results with:
    - File paths (absolute)
    - Line numbers
    - Match text
    - Context lines
    
    .EXAMPLE
    Find-AgentRipgrep -Pattern "class " -Path C:\src -Filter "*.py"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Pattern,
        
        [Parameter(Position = 1)]
        [string]$Path = '.',
        
        [string]$Filter,
        
        [int]$Context = 0,
        
        [switch]$CaseSensitive,
        
        [switch]$WholeWord,
        
        [switch]$Raw,
                [switch]$Json
    )
    
    # Check if ripgrep is available
    $rgPath = Get-Command rg -ErrorAction SilentlyContinue
    if (-not $rgPath) {
        return @{ error = "ripgrep (rg) not found in PATH" } | ConvertTo-Json
    }
    
    # Build rg command
    $rgArgs = @('--json', '--no-heading')
    
    if ($Context -gt 0) {
        $rgArgs += '--context'
        $rgArgs += $Context.ToString()
    }
    
    if (-not $CaseSensitive) {
        $rgArgs += '--ignore-case'
    }
    
    if ($WholeWord) {
        $rgArgs += '--word-regexp'
    }
    
    if ($Filter) {
        $rgArgs += '--glob'
        $rgArgs += $Filter
    }
    
    $rgArgs += $Pattern
    $rgArgs += $Path
    
    # Execute ripgrep
    $rgOutput = & rg @rgArgs 2>&1
    
    if ($LASTEXITCODE -eq 1) {
        # No matches
        $output = @{
            type = 'ripgrep_results'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            pattern = $Pattern
            path = $Path
            total_matches = 0
            matches = @()
        }
        
        if ($Json) {
            return $output | ConvertTo-Json -Depth 10
        } else {
            return $output
        }
    }
    
    # Parse JSON Lines output
    $matches = @()
    $stats = @{}
    
    foreach ($line in $rgOutput) {
        try {
            $jsonLine = $line | ConvertFrom-Json
            
            if ($jsonLine.type -eq 'match') {
                $match = @{
                    file = $jsonLine.data.path.text
                    line_number = $jsonLine.data.line_number
                    line = $jsonLine.data.lines.text.Trim()
                    match_start = $jsonLine.data.submatches[0].match.start
                    match_length = $jsonLine.data.submatches[0].match.end - $jsonLine.data.submatches[0].match.start
                    match_text = $jsonLine.data.submatches[0].match.text
                }
                $matches += $match
            } elseif ($jsonLine.type -eq 'summary') {
                $stats = @{
                    bytes_searched = $jsonLine.data.stats.bytes_searched
                    matched_lines = $jsonLine.data.stats.matched_lines
                    total_matches = $jsonLine.data.stats.matches
                    elapsed = $jsonLine.data.elapsed_total.human
                }
            }
        } catch {
            # Skip non-JSON lines
        }
    }
    
    $output = @{
        type = 'ripgrep_results'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        pattern = $Pattern
        path = $Path
        total_matches = $matches.Count
        stats = $stats
        matches = $matches
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name arg -Value Find-AgentRipgrep
