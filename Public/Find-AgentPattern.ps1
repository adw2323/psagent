# Find-AgentPattern.ps1 - Searches files for patterns with structured output

function Find-AgentPattern {
    <#
    .SYNOPSIS
    Searches files for patterns with structured output for AI agents.
    
    .DESCRIPTION
    Returns search results as structured JSON with:
    - File paths (absolute)
    - Line numbers
    - Match context
    - Match positions
    
    .EXAMPLE
    Find-AgentPattern -Path C:\src -Pattern "class " -Filter *.py
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Pattern,
        
        [Parameter(Position = 1)]
        [string]$Path = '.',
        
        [string]$Filter = '*',
        
        [switch]$Recurse,
        
        [switch]$CaseSensitive,
        
        [int]$Context = 0,
        
        [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    # If path is a directory, search all files in it
    $searchPath = $resolvedPath.Path
    if (Test-Path -Path $searchPath -PathType Container) {
        $searchPath = Join-Path -Path $searchPath -ChildPath "*"
    }
    
    $matches = @()
    
    $searchParams = @{
        Path = $searchPath
        Pattern = $Pattern
        ErrorAction = 'SilentlyContinue'
    }
    
    if ($Filter -and $Filter -ne '*') {
        $searchParams.Include = $Filter
    }
    
    if ($Recurse) { $searchParams.Recurse = $true }
    if ($CaseSensitive) { $searchParams.CaseSensitive = $true }
    
    Select-String @searchParams | ForEach-Object {
        $match = @{
            file = $_.Path
            absolute = $_.Path
            line_number = $_.LineNumber
            line = $_.Line.Trim()
            match_start = $_.Matches[0].Index
            match_length = $_.Matches[0].Length
            match_text = $_.Matches[0].Value
            language = Get-Language -Extension ([System.IO.Path]::GetExtension($_.Path))
        }
        
        if ($Context -gt 0) {
            $lines = Get-Content -Path $_.Path -ErrorAction SilentlyContinue
            $start = [math]::Max(0, $_.LineNumber - 1 - $Context)
            $end = [math]::Min($lines.Count - 1, $_.LineNumber - 1 + $Context)
            $match.context_before = $lines[$start..($_.LineNumber - 2)]
            $match.context_after = $lines[$($_.LineNumber)..$end]
        }
        
        $matches += $match
    }
    
    $output = @{
        type = 'search_results'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        pattern = $Pattern
        path = $resolvedPath.Path
        total_matches = $matches.Count
        matches = $matches
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name ag -Value Find-AgentPattern
