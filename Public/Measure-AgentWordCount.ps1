# Measure-AgentWordCount.ps1 - Counts words/lines/chars with structured output

function Measure-AgentWordCount {
    <#
    .SYNOPSIS
    Counts words, lines, and characters with structured output for AI agents.
    
    .EXAMPLE
    Measure-AgentWordCount -Path C:\src\*.py
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$Recurse,
        
        [switch]$Raw,
                [switch]$Json
    )
    
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -File -ErrorAction SilentlyContinue
    
    $results = @()
    
    $files | ForEach-Object {
        $content = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue
        $text = ($content -join "`n")
        
        $results += @{
            file = $_.Name
            absolute = $_.FullName
            lines = $content.Count
            words = ($text -split '\s+').Count
            characters = $text.Length
            bytes = $_.Length
            language = Get-Language -Extension $_.Extension
        }
    }
    
    $output = @{
        type = 'word_count'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_files = $results.Count
        total_lines = ($results | Measure-Object -Property lines -Sum).Sum
        total_words = ($results | Measure-Object -Property words -Sum).Sum
        total_characters = ($results | Measure-Object -Property characters -Sum).Sum
        files = $results
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name awc -Value Measure-AgentWordCount
