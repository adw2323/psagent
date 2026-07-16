# Compare-AgentDiff.ps1 - Compares files with structured output

function Compare-AgentDiff {
    <#
    .SYNOPSIS
    Compares files with structured output for AI agents.
    
    .DESCRIPTION
    Returns diff results as structured JSON with:
    - Added/removed/modified lines
    - Line numbers
    - Change context
    
    .EXAMPLE
    Compare-AgentDiff -Reference old.py -Difference new.py
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Reference,
        
        [Parameter(Mandatory)]
        [string]$Difference,
        
        [switch]$Json
    )
    
    $refPath = Resolve-Path -Path $Reference -ErrorAction SilentlyContinue
    $diffPath = Resolve-Path -Path $Difference -ErrorAction SilentlyContinue
    
    if (-not $refPath -or -not $diffPath) {
        return @{ error = "File not found" } | ConvertTo-Json
    }
    
    $refLines = Get-Content -Path $refPath.Path -ErrorAction SilentlyContinue
    $diffLines = Get-Content -Path $diffPath.Path -ErrorAction SilentlyContinue
    
    $changes = @()
    $lineNum = 0
    $maxLines = [math]::Max($refLines.Count, $diffLines.Count)
    
    for ($i = 0; $i -lt $maxLines; $i++) {
        $refLine = if ($i -lt $refLines.Count) { $refLines[$i] } else { $null }
        $diffLine = if ($i -lt $diffLines.Count) { $diffLines[$i] } else { $null }
        
        if ($refLine -ne $diffLine) {
            $lineNum++
            $change = @{
                line_number = $lineNum
                type = if ($refLine -eq $null) { 'added' } 
                       elseif ($diffLine -eq $null) { 'removed' }
                       else { 'modified' }
                old = $refLine
                new = $diffLine
            }
            $changes += $change
        }
    }
    
    $output = @{
        type = 'diff'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        reference = $refPath.Path
        difference = $diffPath.Path
        reference_lines = $refLines.Count
        difference_lines = $diffLines.Count
        total_changes = $changes.Count
        added = ($changes | Where-Object { $_.type -eq 'added' }).Count
        removed = ($changes | Where-Object { $_.type -eq 'removed' }).Count
        modified = ($changes | Where-Object { $_.type -eq 'modified' }).Count
        changes = $changes
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name adiff -Value Compare-AgentDiff
