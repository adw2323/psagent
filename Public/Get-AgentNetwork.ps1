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
        
        [switch]$Json
    )
    
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    
    if ($State) {
        $connections = $connections | Where-Object { $_.State -eq $State }
    }
    
    if ($LocalPort) {
        $connections = $connections | Where-Object { $_.LocalPort -eq $LocalPort }
    }
    
    $results = @()
    
    $connections | ForEach-Object {
        $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        
        $results += @{
            local_address = $_.LocalAddress
            local_port = $_.LocalPort
            remote_address = $_.RemoteAddress
            remote_port = $_.RemotePort
            state = $_.State.ToString()
            process_name = if ($process) { $process.Name } else { 'unknown' }
            process_id = $_.OwningProcess
        }
    }
    
    $output = @{
        type = 'network_connections'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_connections = $results.Count
        connections = $results
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name an -Value Get-AgentNetwork
