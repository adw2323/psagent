# Get-AgentNetwork.ps1 - Returns network information as structured JSON

function Get-AgentNetwork {
    <#
    .SYNOPSIS
    Returns network connection information as structured JSON for AI agents.
    
    .EXAMPLE
    Get-AgentNetwork -SortBy Established -Descending
    #>
    [CmdletBinding()]
    param(
        [string]$State,
        
        [int]$LocalPort,
        
        [switch]$Raw
    )
    
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    
    if ($State) {
        $connections = $connections | Where-Object { $_.State -eq $State }
    }
    
    if ($LocalPort) {
        $connections = $connections | Where-Object { $_.LocalPort -eq $LocalPort }
    }
    
    # Batch process lookup for performance
    $processIds = $connections | ForEach-Object { $_.OwningProcess } | Sort-Object -Unique
    $processMap = @{}
    
    if ($processIds.Count -gt 0) {
        Get-Process -Id $processIds -ErrorAction SilentlyContinue | ForEach-Object {
            $processMap[$_.Id] = $_.Name
        }
    }
    
    $results = @()
    
    $connections | ForEach-Object {
        $processName = if ($processMap.ContainsKey($_.OwningProcess)) { 
            $processMap[$_.OwningProcess] 
        } else { 
            'unknown' 
        }
        
        $results += @{
            local_address = $_.LocalAddress
            local_port = $_.LocalPort
            remote_address = $_.RemoteAddress
            remote_port = $_.RemotePort
            state = $_.State.ToString()
            process_name = $processName
            process_id = $_.OwningProcess
        }
    }
    
    $output = @{
        type = 'network_connections'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_connections = $results.Count
        connections = $results
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name an -Value Get-AgentNetwork
