# Get-AgentToolVersion.ps1 - Returns tool versions as structured JSON

function Get-AgentToolVersion {
    <#
    .SYNOPSIS
    Returns tool versions as structured JSON for AI agents.
    
    .DESCRIPTION
    Checks versions of common development tools:
    - Python, Node.js, Git, PowerShell
    - Azure CLI, gh CLI
    - Package managers (npm, pip, uv)
    
    .EXAMPLE
    Get-AgentToolVersion
    #>
    [CmdletBinding()]
    param(
        [string[]]$Tools,
        
        [switch]$Json
    )
    
    $toolDefs = @(
        @{ name = 'python'; cmd = 'python --version' },
        @{ name = 'pip'; cmd = 'pip --version' },
        @{ name = 'uv'; cmd = 'uv --version' },
        @{ name = 'node'; cmd = 'node --version' },
        @{ name = 'npm'; cmd = 'npm --version' },
        @{ name = 'git'; cmd = 'git --version' },
        @{ name = 'gh'; cmd = 'gh --version' },
        @{ name = 'az'; cmd = 'az --version' },
        @{ name = 'rg'; cmd = 'rg --version' },
        @{ name = 'powershell'; cmd = '$PSVersionTable.PSVersion.ToString()' },
        @{ name = 'agy'; cmd = 'agy --version' },
        @{ name = 'claude'; cmd = 'claude --version' }
    )
    
    # Filter to requested tools
    if ($Tools) {
        $toolDefs = $toolDefs | Where-Object { $Tools -contains $_.name }
    }
    
    $results = @()
    
    foreach ($tool in $toolDefs) {
        $output = try {
            & powershell.exe -NoProfile -Command $tool.cmd 2>&1 | Select-Object -First 1
        } catch {
            'not found'
        }
        
        $installed = $LASTEXITCODE -eq 0 -and $output -ne 'not found'
        
        # Parse version from output
        $version = ''
        if ($installed) {
            $versionMatch = $output | Select-String -Pattern '(\d+\.\d+[\.\d]*)'
            if ($versionMatch) {
                $version = $versionMatch.Matches[0].Value
            } else {
                $version = $output.Trim()
            }
        }
        
        $results += @{
            name = $tool.name
            installed = $installed
            version = $version
            output = $output.Trim()
        }
    }
    
    $installedCount = ($results | Where-Object { $_.installed }).Count
    
    $output = @{
        type = 'tool_versions'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_tools = $results.Count
        installed = $installedCount
        missing = $results.Count - $installedCount
        tools = $results
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name atv -Value Get-AgentToolVersion
