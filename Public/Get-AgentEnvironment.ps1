# Get-AgentEnvironment.ps1 - Returns environment variables as structured JSON

function Get-AgentEnvironment {
    <#
    .SYNOPSIS
    Returns environment variables as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns environment variables with:
    - Variable names
    - Values (masked for secrets)
    - PATH breakdown
    
    .EXAMPLE
    Get-AgentEnvironment -Filter PATH
    #>
    [CmdletBinding()]
    param(
        [string]$Filter,
        
        [switch]$ShowSecrets,
        
        [switch]$Json
    )
    
    $envVars = @()
    
    $secretPatterns = @('KEY', 'SECRET', 'TOKEN', 'PASSWORD', 'CREDENTIAL', 'API')
    
    Get-ChildItem Env: | ForEach-Object {
        $name = $_.Name
        $value = $_.Value
        
        # Check if it's a secret
        $isSecret = $secretPatterns | Where-Object { $name -match $_ }
        
        # Mask secrets unless ShowSecrets
        if ($isSecret -and -not $ShowSecrets) {
            if ($value.Length -gt 8) {
                $value = $value.Substring(0, 4) + '****' + $value.Substring($value.Length - 4)
            } else {
                $value = '****'
            }
        }
        
        $envVars += @{
            name = $name
            value = $value
            is_secret = [bool]$isSecret
        }
    }
    
    # Apply filter
    if ($Filter) {
        $envVars = $envVars | Where-Object { $_.name -match $Filter }
    }
    
    # Get PATH breakdown
    $pathParts = $env:PATH -split ';'
    $pathBreakdown = @()
    foreach ($part in $pathParts) {
        if ($part) {
            $exists = Test-Path -Path $part -ErrorAction SilentlyContinue
            $pathBreakdown += @{
                path = $part
                exists = $exists
            }
        }
    }
    
    $output = @{
        type = 'environment'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_vars = $envVars.Count
        vars = $envVars
        path_count = $pathBreakdown.Count
        path_breakdown = $pathBreakdown
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name aenv -Value Get-AgentEnvironment
